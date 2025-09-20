#!/bin/bash

# AWS EKS Cluster Setup Script
# This script creates an EKS cluster for the Algorithm Visualizer application

set -e

# Configuration
CLUSTER_NAME="algorithm-visualizer-cluster"
REGION="us-east-1"  # Changed from us-west-2
NODE_GROUP_NAME="algorithm-visualizer-nodes"
KUBERNETES_VERSION="1.28"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up EKS cluster for Algorithm Visualizer${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! command -v eksctl &> /dev/null; then
    echo -e "${RED}❌ eksctl is not installed. Please install it first.${NC}"
    echo "Install from: https://eksctl.io/introduction/#installation"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Check if cluster exists and delete if necessary
if aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Existing cluster found. Cleaning up...${NC}"
    eksctl delete cluster --name ${CLUSTER_NAME} --region ${REGION} --wait
fi

# Create EKS cluster
echo -e "${YELLOW}🏗️  Creating EKS cluster...${NC}"
cat > cluster-config.yaml << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${REGION}
  version: "${KUBERNETES_VERSION}"

iam:
  withOIDC: true

managedNodeGroups:
  - name: ${NODE_GROUP_NAME}
    instanceType: t2.small
    minSize: 1
    maxSize: 1
    desiredCapacity: 1
    volumeSize: 20
    ssh:
      allow: false
    labels:
      role: worker
    tags:
      Environment: production
      Application: algorithm-visualizer
    iam:
      withAddonPolicies:
        albIngress: true
        cloudWatch: true

addons:
  - name: vpc-cni
    version: latest
  - name: coredns
    version: latest
  - name: kube-proxy
    version: latest

cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
EOF

eksctl create cluster -f cluster-config.yaml

# Install AWS Load Balancer Controller
echo -e "${YELLOW}🔧 Installing AWS Load Balancer Controller...${NC}"

# Create IAM role for AWS Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install AWS Load Balancer Controller using Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Install metrics server for HPA
echo -e "${YELLOW}📊 Installing metrics server...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify installation
echo -e "${YELLOW}🔍 Verifying cluster setup...${NC}"
kubectl get nodes
kubectl get pods -n kube-system

echo -e "${GREEN}✅ EKS cluster setup completed successfully!${NC}"
echo -e "${YELLOW}📝 Cluster Information:${NC}"
echo "  Cluster Name: ${CLUSTER_NAME}"
echo "  Region: ${REGION}"
echo "  Kubernetes Version: ${KUBERNETES_VERSION}"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Update your kubeconfig: aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}"
echo "2. Configure Jenkins with the kubeconfig file"
echo "3. Update the Docker image name in k8s/deployment.yaml"
echo "4. Run your Jenkins pipeline to deploy the application"

# Cleanup
rm -f cluster-config.yaml

