# Complete Algorithm Visualizer Deployment Guide

## 📋 Part 1: Initial Setup

### 1.1 Verify AWS Configuration
```bash
# Check AWS configuration
aws configure list

# Verify AWS credentials
aws sts get-caller-identity

# Set correct region
aws configure set region us-east-1
```

### 1.2 Prerequisites Check
- AWS CLI installed and configured
- kubectl installed
- eksctl installed
- Helm installed
- Docker installed and running
- Git installed

## 🚀 Part 2: Deployment Process

### 2.1 Create EKS Cluster
```bash
eksctl create cluster \
   --name algorithm-visualizer-cluster \
   --region us-east-1 \
   --version 1.28 \
   --managed \
   --node-type t2.small \
   --nodes 1 \
   --nodes-min 1 \
   --nodes-max 1
```

### 2.2 Install Required Components

#### Install AWS Load Balancer Controller
```bash
# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=algorithm-visualizer-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=algorithm-visualizer-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

#### Install Metrics Server
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 2.3 Create Jenkins EC2 Instance
```bash
# Make script executable
chmod +x scripts/create-jenkins-ec2.sh

# Create Jenkins instance
./scripts/create-jenkins-ec2.sh
```

### 2.4 Configure Jenkins

1. Access Jenkins (wait 5-10 minutes after EC2 creation):
   ```bash
   # Get EC2 public IP
   aws ec2 describe-instances --filters "Name=tag:Name,Values=Jenkins" --query "Reservations[*].Instances[*].PublicIpAddress" --output text
   
   # Get initial admin password
   ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@EC2_PUBLIC_IP 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
   ```

2. Install Required Plugins:
   - Install suggested plugins first
   - Then install additional plugins:
     * Docker Pipeline
     * CloudBees Docker Build and Publish
     * Amazon ECR
     * Kubernetes CLI
     * Kubernetes Credentials
     * Config File Provider

3. Configure Credentials:
   - Docker Hub credentials
   - AWS credentials
   - Kubernetes config

### 2.5 Deploy Application
```bash
# Create namespace
kubectl create namespace algorithm-visualizer

# Deploy application
kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml -f k8s/hpa.yaml -n algorithm-visualizer

# Verify deployment
kubectl get pods,svc,deployment -n algorithm-visualizer
```

## 🔄 Part 3: Cleanup and Redeployment

### 3.1 Cleanup Process
```bash
# 1. Delete namespace and all resources in it
kubectl delete namespace algorithm-visualizer

# 2. Delete EKS cluster
eksctl delete cluster --name algorithm-visualizer-cluster --region us-east-1

# 3. Terminate Jenkins EC2 instance
aws ec2 describe-instances --filters "Name=tag:Name,Values=Jenkins" --query "Reservations[*].Instances[*].InstanceId" --output text
aws ec2 terminate-instances --instance-ids INSTANCE_ID --region us-east-1

# 4. Delete Load Balancer IAM policy
aws iam delete-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy
```

### 3.2 Verification of Cleanup
```bash
# Verify EKS clusters
aws eks list-clusters --region us-east-1

# Verify EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=Jenkins" --query "Reservations[*].Instances[*].State.Name" --output text
```

### 3.3 Redeployment
To redeploy after cleanup:
1. Start from Part 2.1 (Create EKS Cluster)
2. Follow all steps in sequence
3. No need to recreate AWS configurations

## 🔍 Part 4: Monitoring and Verification

### 4.1 Check Deployment Status
```bash
# Check all resources
kubectl get all -n algorithm-visualizer

# Check logs if needed
kubectl logs -n algorithm-visualizer deployment/algorithm-visualizer

# Get service URL
kubectl get svc -n algorithm-visualizer
```

### 4.2 Common Issues and Solutions

1. **Cluster Creation Issues**
   - Check IAM permissions
   - Verify region settings
   - Ensure sufficient quota

2. **Jenkins Connection Issues**
   - Wait 5-10 minutes after EC2 creation
   - Check security group ports (8080, 22)
   - Verify EC2 status

3. **Load Balancer Issues**
   - Check Load Balancer Controller logs
   - Verify IAM roles and policies
   - Check service annotations

4. **Application Issues**
   - Check pod logs
   - Verify deployment configuration
   - Check service configuration

## 💡 Tips

1. **Cost Management**
   - Delete cluster when not in use
   - Use t2.small instances
   - Monitor AWS billing dashboard

2. **Time Saving**
   - Save kubeconfig and credentials
   - Keep track of EC2 public IP
   - Document custom configurations

3. **Troubleshooting**
   - Always check logs first
   - Verify AWS credentials
   - Confirm region settings

Remember: Always perform cleanup when finished to avoid unnecessary AWS charges!