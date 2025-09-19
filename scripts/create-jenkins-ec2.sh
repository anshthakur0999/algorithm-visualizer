#!/bin/bash

# Create Jenkins EC2 Instance Script
# This script creates an EC2 instance and sets up Jenkins automatically

set -e

# Configuration
INSTANCE_TYPE="t3.micro"  # Free tier with better CPU
REGION="us-east-1"  # Change to your preferred region
KEY_NAME="jenkins-key"  # This should match the key pair you created in AWS
SECURITY_GROUP_NAME="jenkins-sg"
INSTANCE_NAME="jenkins-server"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Creating Jenkins EC2 instance${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Get the latest Amazon Linux 2 AMI
echo -e "${YELLOW}🔍 Finding latest Amazon Linux 2 AMI...${NC}"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region $REGION)

echo "Using AMI: $AMI_ID"

# Create security group
echo -e "${YELLOW}🔒 Creating security group...${NC}"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for Jenkins server" \
    --region $REGION \
    --query 'GroupId' \
    --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --group-names $SECURITY_GROUP_NAME \
    --region $REGION \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

echo "Security Group ID: $SECURITY_GROUP_ID"

# Add security group rules
echo -e "${YELLOW}🔧 Configuring security group rules...${NC}"

# SSH access
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "SSH rule already exists"

# Jenkins web interface
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Jenkins rule already exists"

# HTTPS (for future use)
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "HTTPS rule already exists"

# Create user data script
cat > user-data.sh << 'EOF'
#!/bin/bash
yum update -y

# Install Java 11
yum install -y java-11-amazon-corretto-headless

# Install Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker jenkins
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum install -y unzip
unzip awscliv2.zip
./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Git and other tools
yum install -y git curl wget vim htop

# Start Jenkins
systemctl start jenkins
systemctl enable jenkins

# Create setup completion marker
echo "Jenkins setup completed at $(date)" > /tmp/jenkins-setup-complete

# Cleanup
rm -f awscliv2.zip kubectl
rm -rf aws/
EOF

# Launch EC2 instance
echo -e "${YELLOW}🚀 Launching EC2 instance...${NC}"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Environment,Value=production},{Key=Application,Value=jenkins}]" \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance to be running
echo -e "${YELLOW}⏳ Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get instance public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}✅ Jenkins EC2 instance created successfully!${NC}"
echo -e "${YELLOW}📝 Instance Information:${NC}"
echo "  Instance ID: $INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"
echo "  Security Group: $SECURITY_GROUP_NAME ($SECURITY_GROUP_ID)"
echo "  Region: $REGION"
echo ""
echo -e "${YELLOW}🔧 Access Information:${NC}"
echo "  SSH: ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo "  Jenkins URL: http://$PUBLIC_IP:8080"
echo ""
echo -e "${YELLOW}⏳ Setup Status:${NC}"
echo "  The instance is starting up and installing Jenkins..."
echo "  This process takes about 5-10 minutes."
echo "  You can monitor progress with: ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP 'tail -f /var/log/cloud-init-output.log'"
echo ""
echo -e "${YELLOW}🔑 Getting Jenkins Initial Password:${NC}"
echo "  Once setup is complete, get the initial admin password with:"
echo "  ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"

# Cleanup
rm -f user-data.sh

echo -e "${GREEN}🎉 EC2 instance creation completed!${NC}"


