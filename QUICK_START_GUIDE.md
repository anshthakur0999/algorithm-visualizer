# Quick Start Guide - ECS Blue-Green Deployment

## 🚀 Get Started in 2 Hours

### Prerequisites (15 minutes)
```bash
# 1. Create AWS Free Tier Account
# 2. Install AWS CLI
aws --version

# 3. Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)

# 4. Install Docker
docker --version

# 5. Clone repository
git clone <your-repo>
cd algorithm-visualizer
```

---

## Step 1: Build & Test Locally (15 minutes)

```bash
# Build Docker image
docker build -t algorithm-visualizer:v1.0 .

# Run locally
docker run -p 8080:8080 algorithm-visualizer:v1.0

# Test in another terminal
curl http://localhost:8080

# Stop container
# Press Ctrl+C
```

---

## Step 2: Push to ECR (15 minutes)

```bash
# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo $ACCOUNT_ID

# Create ECR repository
aws ecr create-repository \
  --repository-name algorithm-visualizer \
  --region us-east-1

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag image
docker tag algorithm-visualizer:v1.0 \
  $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/algorithm-visualizer:v1.0

# Push to ECR
docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/algorithm-visualizer:v1.0

# Verify
aws ecr describe-images --repository-name algorithm-visualizer
```

---

## Step 3: Setup AWS Infrastructure (30 minutes)

```bash
# Create log group
aws logs create-log-group \
  --log-group-name /ecs/algorithm-visualizer \
  --region us-east-1

# Create ECS cluster
aws ecs create-cluster \
  --cluster-name visualizer-cluster \
  --region us-east-1

# Create IAM role
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

# Get default VPC and subnets
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNET_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
SUBNET_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[1].SubnetId' --output text)

echo "VPC: $VPC_ID"
echo "Subnet 1: $SUBNET_1"
echo "Subnet 2: $SUBNET_2"

# Create security group
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

## Step 4: Create ALB (20 minutes)

```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name visualizer-alb \
  --subnets $SUBNET_1 $SUBNET_2 \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB ARN: $ALB_ARN"

# Create Blue target group
BLUE_TG=$(aws elbv2 create-target-group \
  --name visualizer-blue \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create Green target group
GREEN_TG=$(aws elbv2 create-target-group \
  --name visualizer-green \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Blue TG: $BLUE_TG"
echo "Green TG: $GREEN_TG"

# Create listener
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG \
  --query 'Listeners[0].ListenerArn' --output text)

echo "Listener ARN: $LISTENER_ARN"
```

---

## Step 5: Create Task Definitions (15 minutes)

```bash
TASK_EXEC_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole"

# Blue task definition
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

# Green task definition
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

## Step 6: Create ECS Services (15 minutes)

```bash
# Blue service
aws ecs create-service \
  --cluster visualizer-cluster \
  --service-name algorithm-visualizer-blue \
  --task-definition algorithm-visualizer-blue:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=$BLUE_TG,containerName=algorithm-visualizer,containerPort=8080

# Green service
aws ecs create-service \
  --cluster visualizer-cluster \
  --service-name algorithm-visualizer-green \
  --task-definition algorithm-visualizer-green:1 \
  --desired-count 0 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=$GREEN_TG,containerName=algorithm-visualizer,containerPort=8080

# Wait for Blue to be running
aws ecs wait services-stable --cluster visualizer-cluster --services algorithm-visualizer-blue
```

---

## Step 7: Test Deployment (10 minutes)

```bash
# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)

echo "Application URL: http://$ALB_DNS"

# Test
curl http://$ALB_DNS

# Check service status
aws ecs describe-services \
  --cluster visualizer-cluster \
  --services algorithm-visualizer-blue \
  --query 'services[0].{Status:status,RunningCount:runningCount}'
```

---

## Step 8: Deploy Green & Switch Traffic (10 minutes)

```bash
# Update Green service to 1 task
aws ecs update-service \
  --cluster visualizer-cluster \
  --service algorithm-visualizer-green \
  --desired-count 1

# Wait for Green to be running
aws ecs wait services-stable --cluster visualizer-cluster --services algorithm-visualizer-green

# Switch traffic to Green
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$GREEN_TG

# Test
curl http://$ALB_DNS

# Rollback to Blue (if needed)
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG
```

---

## 📊 Useful Commands

```bash
# View logs
aws logs tail /ecs/algorithm-visualizer --follow

# Check service status
aws ecs describe-services --cluster visualizer-cluster --services algorithm-visualizer-blue

# List tasks
aws ecs list-tasks --cluster visualizer-cluster --service-name algorithm-visualizer-blue

# View task details
aws ecs describe-tasks --cluster visualizer-cluster --tasks <task-arn>

# Stop services (save money!)
aws ecs update-service --cluster visualizer-cluster --service algorithm-visualizer-blue --desired-count 0
aws ecs update-service --cluster visualizer-cluster --service algorithm-visualizer-green --desired-count 0
```

---

## 💰 Cost Tracking

```bash
# Check free tier usage
aws ce get-cost-and-usage \
  --time-period Start=2025-10-01,End=2025-10-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

---

## ✅ Checklist

- [ ] AWS account created
- [ ] Docker image built locally
- [ ] Image pushed to ECR
- [ ] ECS cluster created
- [ ] ALB created
- [ ] Blue service running
- [ ] Green service created
- [ ] Traffic switching works
- [ ] Rollback works
- [ ] Documentation complete

---

**Total Time: ~2 hours**  
**Total Cost: $0 (Free Tier)**

**Next: Read ECS_SIMPLE_IMPLEMENTATION.md for detailed steps**

