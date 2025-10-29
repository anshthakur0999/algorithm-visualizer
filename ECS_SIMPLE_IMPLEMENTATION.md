# Simplified ECS Implementation - Free Tier

## Phase 1: Local Setup (30 minutes)

### Step 1.1: Create Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY index.html .
COPY app.js .
COPY style.css .
COPY package.json .

RUN npm install --production || true

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1

CMD ["node", "-e", "require('http').createServer((req, res) => { res.writeHead(200, {'Content-Type': 'text/html'}); require('fs').createReadStream('index.html').pipe(res); }).listen(8080)"]
```

### Step 1.2: Test Locally
```bash
# Build
docker build -t algorithm-visualizer:v1.0 .

# Run
docker run -p 8080:8080 algorithm-visualizer:v1.0

# Test
curl http://localhost:8080
```

---

## Phase 2: AWS Setup (1 hour)

### Step 2.1: Create ECR Repository
```bash
aws ecr create-repository \
  --repository-name algorithm-visualizer \
  --region us-east-1
```

### Step 2.2: Push Image to ECR
```bash
# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Login
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag
docker tag algorithm-visualizer:v1.0 \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/algorithm-visualizer:v1.0

# Push
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/algorithm-visualizer:v1.0
```

### Step 2.3: Create ECS Cluster
```bash
aws ecs create-cluster --cluster-name visualizer-cluster --region us-east-1
```

### Step 2.4: Create CloudWatch Log Group
```bash
aws logs create-log-group \
  --log-group-name /ecs/algorithm-visualizer \
  --region us-east-1
```

---

## Phase 3: Create IAM Roles (15 minutes)

### Step 3.1: Create Task Execution Role
```bash
# Create role
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policy
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

---

## Phase 4: Create Task Definitions (15 minutes)

### Step 4.1: Blue Task Definition
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TASK_EXEC_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole"

aws ecs register-task-definition \
  --family algorithm-visualizer-blue \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 \
  --memory 512 \
  --execution-role-arn $TASK_EXEC_ROLE_ARN \
  --container-definitions '[{
    "name": "algorithm-visualizer",
    "image": "'$ACCOUNT_ID'.dkr.ecr.us-east-1.amazonaws.com/algorithm-visualizer:v1.0",
    "portMappings": [{"containerPort": 8080}],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/algorithm-visualizer",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]'
```

### Step 4.2: Green Task Definition
```bash
aws ecs register-task-definition \
  --family algorithm-visualizer-green \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 \
  --memory 512 \
  --execution-role-arn $TASK_EXEC_ROLE_ARN \
  --container-definitions '[{
    "name": "algorithm-visualizer",
    "image": "'$ACCOUNT_ID'.dkr.ecr.us-east-1.amazonaws.com/algorithm-visualizer:v1.1",
    "portMappings": [{"containerPort": 8080}],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/algorithm-visualizer",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]'
```

---

## Phase 5: Create VPC & Security Groups (15 minutes)

### Step 5.1: Get Default VPC
```bash
# Use default VPC (free tier includes this)
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)

# Get subnets
SUBNET_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
SUBNET_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[1].SubnetId' --output text)

echo "VPC: $VPC_ID"
echo "Subnet 1: $SUBNET_1"
echo "Subnet 2: $SUBNET_2"
```

### Step 5.2: Create Security Group
```bash
SG_ID=$(aws ec2 create-security-group \
  --group-name ecs-tasks-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow port 8080
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0

echo "Security Group: $SG_ID"
```

---

## Phase 6: Create ALB (20 minutes)

### Step 6.1: Create ALB
```bash
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name visualizer-alb \
  --subnets $SUBNET_1 $SUBNET_2 \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB ARN: $ALB_ARN"
```

### Step 6.2: Create Target Groups
```bash
# Blue Target Group
BLUE_TG=$(aws elbv2 create-target-group \
  --name visualizer-blue \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Green Target Group
GREEN_TG=$(aws elbv2 create-target-group \
  --name visualizer-green \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Blue TG: $BLUE_TG"
echo "Green TG: $GREEN_TG"
```

### Step 6.3: Create Listener
```bash
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG \
  --query 'Listeners[0].ListenerArn' --output text)

echo "Listener ARN: $LISTENER_ARN"
```

---

## Phase 7: Create ECS Services (20 minutes)

### Step 7.1: Blue Service
```bash
aws ecs create-service \
  --cluster visualizer-cluster \
  --service-name algorithm-visualizer-blue \
  --task-definition algorithm-visualizer-blue:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=$BLUE_TG,containerName=algorithm-visualizer,containerPort=8080
```

### Step 7.2: Green Service
```bash
aws ecs create-service \
  --cluster visualizer-cluster \
  --service-name algorithm-visualizer-green \
  --task-definition algorithm-visualizer-green:1 \
  --desired-count 0 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=$GREEN_TG,containerName=algorithm-visualizer,containerPort=8080
```

---

## Phase 8: Test Deployment (10 minutes)

### Step 8.1: Get ALB DNS
```bash
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "ALB DNS: $ALB_DNS"

# Test
curl http://$ALB_DNS
```

### Step 8.2: Check Service Status
```bash
aws ecs describe-services \
  --cluster visualizer-cluster \
  --services algorithm-visualizer-blue \
  --query 'services[0].{Status:status,RunningCount:runningCount,DesiredCount:desiredCount}'
```

---

## Phase 9: Create Deployment Scripts

### scripts/deploy-green.sh
```bash
#!/bin/bash
set -e

CLUSTER="visualizer-cluster"
GREEN_SERVICE="algorithm-visualizer-green"
IMAGE_TAG=$1

echo "Deploying Green with tag: $IMAGE_TAG"

# Update service
aws ecs update-service \
  --cluster $CLUSTER \
  --service $GREEN_SERVICE \
  --force-new-deployment

# Wait for deployment
aws ecs wait services-stable --cluster $CLUSTER --services $GREEN_SERVICE

echo "✓ Green deployed"
```

### scripts/switch-traffic.sh
```bash
#!/bin/bash
set -e

LISTENER_ARN=$1
GREEN_TG=$2

echo "Switching traffic to Green..."

aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$GREEN_TG

echo "✓ Traffic switched"
```

### scripts/rollback.sh
```bash
#!/bin/bash
set -e

LISTENER_ARN=$1
BLUE_TG=$2

echo "Rolling back to Blue..."

aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG

echo "✓ Rolled back"
```

---

## Phase 10: Save Configuration

Create `config.sh` to save all values:
```bash
#!/bin/bash

export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REGION=us-east-1
export CLUSTER=visualizer-cluster
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
export SUBNET_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
export SUBNET_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[1].SubnetId' --output text)
export SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecs-tasks-sg" --query 'SecurityGroups[0].GroupId' --output text)
export ALB_ARN=$(aws elbv2 describe-load-balancers --names visualizer-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
export BLUE_TG=$(aws elbv2 describe-target-groups --names visualizer-blue --query 'TargetGroups[0].TargetGroupArn' --output text)
export GREEN_TG=$(aws elbv2 describe-target-groups --names visualizer-green --query 'TargetGroups[0].TargetGroupArn' --output text)
export LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[0].ListenerArn' --output text)

echo "Configuration loaded!"
```

---

## Testing the Deployment

```bash
# Source config
source config.sh

# Deploy Green
bash scripts/deploy-green.sh v1.1

# Switch traffic
bash scripts/switch-traffic.sh $LISTENER_ARN $GREEN_TG

# Rollback
bash scripts/rollback.sh $LISTENER_ARN $BLUE_TG
```

---

## Cleanup (Save Money!)

```bash
# Stop services
aws ecs update-service --cluster visualizer-cluster --service algorithm-visualizer-blue --desired-count 0
aws ecs update-service --cluster visualizer-cluster --service algorithm-visualizer-green --desired-count 0

# Delete ALB
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN

# Delete cluster
aws ecs delete-cluster --cluster visualizer-cluster
```

---

**Total Setup Time: ~3 hours**  
**Total Cost: $0 (Free Tier)**

