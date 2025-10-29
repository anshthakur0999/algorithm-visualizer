# Deployment Scripts - Ready to Use

## 📁 Directory Structure

```
algorithm-visualizer/
├── Dockerfile
├── Jenkinsfile
├── package.json
├── index.html
├── app.js
├── style.css
├── scripts/
│   ├── config.sh
│   ├── setup.sh
│   ├── deploy-green.sh
│   ├── health-check.sh
│   ├── switch-traffic.sh
│   ├── rollback.sh
│   └── cleanup.sh
└── README_ECS_DEPLOYMENT.md
```

---

## 📄 scripts/config.sh

Save all AWS configuration values

```bash
#!/bin/bash

# AWS Configuration
export AWS_REGION="us-east-1"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export ECR_REPO="algorithm-visualizer"

# ECS Configuration
export ECS_CLUSTER="visualizer-cluster"
export BLUE_SERVICE="algorithm-visualizer-blue"
export GREEN_SERVICE="algorithm-visualizer-green"
export BLUE_TASK_DEF="algorithm-visualizer-blue"
export GREEN_TASK_DEF="algorithm-visualizer-green"

# VPC Configuration
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text)
export SUBNET_1=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
export SUBNET_2=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[1].SubnetId' --output text)
export SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecs-tasks-sg" --query 'SecurityGroups[0].GroupId' --output text)

# ALB Configuration
export ALB_ARN=$(aws elbv2 describe-load-balancers --names visualizer-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
export LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[0].ListenerArn' --output text)
export BLUE_TG=$(aws elbv2 describe-target-groups --names visualizer-blue --query 'TargetGroups[0].TargetGroupArn' --output text)
export GREEN_TG=$(aws elbv2 describe-target-groups --names visualizer-green --query 'TargetGroups[0].TargetGroupArn' --output text)

# IAM Configuration
export TASK_EXEC_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole"

# Application Configuration
export ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)

echo "✓ Configuration loaded!"
echo "Account ID: $ACCOUNT_ID"
echo "ALB DNS: $ALB_DNS"
```

---

## 📄 scripts/setup.sh

One-time setup script

```bash
#!/bin/bash
set -e

echo "🚀 Setting up ECS Blue-Green Deployment..."

# Create log group
echo "Creating CloudWatch log group..."
aws logs create-log-group --log-group-name /ecs/algorithm-visualizer --region us-east-1 || true

# Create ECS cluster
echo "Creating ECS cluster..."
aws ecs create-cluster --cluster-name visualizer-cluster --region us-east-1 || true

# Create IAM role
echo "Creating IAM role..."
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' || true

# Attach policy
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || true

# Create ECR repository
echo "Creating ECR repository..."
aws ecr create-repository --repository-name algorithm-visualizer --region us-east-1 || true

echo "✓ Setup complete!"
```

---

## 📄 scripts/deploy-green.sh

Deploy new version to Green

```bash
#!/bin/bash
set -e

source scripts/config.sh

IMAGE_TAG=${1:-latest}

echo "🟢 Deploying Green with tag: $IMAGE_TAG"

# Register new task definition
echo "Registering task definition..."
aws ecs register-task-definition \
  --family $GREEN_TASK_DEF \
  --network-mode awsvpc \
  --requires-compatibilities FARGATE \
  --cpu 256 \
  --memory 512 \
  --execution-role-arn $TASK_EXEC_ROLE_ARN \
  --container-definitions "[{
    \"name\": \"algorithm-visualizer\",
    \"image\": \"$ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG\",
    \"portMappings\": [{\"containerPort\": 8080}],
    \"logConfiguration\": {
      \"logDriver\": \"awslogs\",
      \"options\": {
        \"awslogs-group\": \"/ecs/algorithm-visualizer\",
        \"awslogs-region\": \"$AWS_REGION\",
        \"awslogs-stream-prefix\": \"ecs\"
      }
    }
  }]" > /dev/null

# Update Green service
echo "Updating Green service..."
aws ecs update-service \
  --cluster $ECS_CLUSTER \
  --service $GREEN_SERVICE \
  --force-new-deployment \
  --region $AWS_REGION > /dev/null

# Wait for deployment
echo "Waiting for Green to be stable..."
aws ecs wait services-stable \
  --cluster $ECS_CLUSTER \
  --services $GREEN_SERVICE \
  --region $AWS_REGION

echo "✓ Green deployment complete!"
```

---

## 📄 scripts/health-check.sh

Check if Green is healthy

```bash
#!/bin/bash
set -e

source scripts/config.sh

echo "❤️ Running health checks..."

# Get Green target group health
echo "Checking target group health..."
HEALTHY=$(aws elbv2 describe-target-health \
  --target-group-arn $GREEN_TG \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
  --output text)

if [ "$HEALTHY" -eq 0 ]; then
    echo "✗ No healthy targets in Green"
    exit 1
fi

echo "✓ Health check passed ($HEALTHY healthy targets)"

# Test HTTP endpoint
echo "Testing HTTP endpoint..."
for i in {1..10}; do
    if curl -f http://$ALB_DNS > /dev/null 2>&1; then
        echo "✓ HTTP endpoint responding"
        exit 0
    fi
    echo "Attempt $i/10..."
    sleep 5
done

echo "✗ HTTP endpoint not responding"
exit 1
```

---

## 📄 scripts/switch-traffic.sh

Switch traffic from Blue to Green

```bash
#!/bin/bash
set -e

source scripts/config.sh

echo "🔄 Switching traffic to Green..."

# Update listener
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$GREEN_TG \
  --region $AWS_REGION

echo "✓ Traffic switched to Green"
echo "Application URL: http://$ALB_DNS"
```

---

## 📄 scripts/rollback.sh

Rollback to Blue

```bash
#!/bin/bash
set -e

source scripts/config.sh

echo "🔙 Rolling back to Blue..."

# Update listener
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,TargetGroupArn=$BLUE_TG \
  --region $AWS_REGION

# Scale down Green
aws ecs update-service \
  --cluster $ECS_CLUSTER \
  --service $GREEN_SERVICE \
  --desired-count 0 \
  --region $AWS_REGION > /dev/null

echo "✓ Rolled back to Blue"
echo "Application URL: http://$ALB_DNS"
```

---

## 📄 scripts/cleanup.sh

Clean up resources (save money!)

```bash
#!/bin/bash
set -e

source scripts/config.sh

echo "🧹 Cleaning up resources..."

# Scale down services
echo "Scaling down services..."
aws ecs update-service --cluster $ECS_CLUSTER --service $BLUE_SERVICE --desired-count 0 --region $AWS_REGION > /dev/null
aws ecs update-service --cluster $ECS_CLUSTER --service $GREEN_SERVICE --desired-count 0 --region $AWS_REGION > /dev/null

# Wait for services to scale down
echo "Waiting for services to scale down..."
aws ecs wait services-stable --cluster $ECS_CLUSTER --services $BLUE_SERVICE $GREEN_SERVICE --region $AWS_REGION

# Delete ALB
echo "Deleting ALB..."
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --region $AWS_REGION

# Delete target groups
echo "Deleting target groups..."
aws elbv2 delete-target-group --target-group-arn $BLUE_TG --region $AWS_REGION || true
aws elbv2 delete-target-group --target-group-arn $GREEN_TG --region $AWS_REGION || true

# Delete cluster
echo "Deleting cluster..."
aws ecs delete-cluster --cluster $ECS_CLUSTER --region $AWS_REGION

echo "✓ Cleanup complete!"
```

---

## 🚀 Usage

### Make scripts executable
```bash
chmod +x scripts/*.sh
```

### Setup (one time)
```bash
bash scripts/setup.sh
```

### Deploy Green
```bash
bash scripts/deploy-green.sh v1.1
```

### Health check
```bash
bash scripts/health-check.sh
```

### Switch traffic
```bash
bash scripts/switch-traffic.sh
```

### Rollback
```bash
bash scripts/rollback.sh
```

### Cleanup (save money!)
```bash
bash scripts/cleanup.sh
```

---

## 📊 Full Deployment Flow

```bash
# 1. Build Docker image
docker build -t algorithm-visualizer:v1.1 .

# 2. Push to ECR
source scripts/config.sh
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
docker tag algorithm-visualizer:v1.1 $ECR_REGISTRY/algorithm-visualizer:v1.1
docker push $ECR_REGISTRY/algorithm-visualizer:v1.1

# 3. Deploy to Green
bash scripts/deploy-green.sh v1.1

# 4. Health check
bash scripts/health-check.sh

# 5. Switch traffic
bash scripts/switch-traffic.sh

# 6. Monitor
aws logs tail /ecs/algorithm-visualizer --follow

# 7. Rollback if needed
bash scripts/rollback.sh
```

---

## 💡 Tips

- Always test locally first
- Run health checks before switching traffic
- Monitor logs after switching
- Keep scripts simple and readable
- Document any customizations
- Save config.sh values for reference

---

**Ready to deploy? Start with `bash scripts/setup.sh`!** 🚀

