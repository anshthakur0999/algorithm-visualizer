#!/bin/bash

# Jenkins EC2 Setup Script
# This script sets up Jenkins on an EC2 instance with all required tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Jenkins on EC2${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo yum update -y

# Install Java 11 (required for Jenkins)
echo -e "${YELLOW}☕ Installing Java 11...${NC}"
sudo yum install -y java-11-amazon-corretto-headless

# Install Jenkins
echo -e "${YELLOW}🔧 Installing Jenkins...${NC}"
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y jenkins

# Install Docker
echo -e "${YELLOW}🐳 Installing Docker...${NC}"
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker jenkins
sudo usermod -a -G docker ec2-user

# Install Docker Compose
echo -e "${YELLOW}🐙 Installing Docker Compose...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install kubectl
echo -e "${YELLOW}⚙️  Installing kubectl...${NC}"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI v2
echo -e "${YELLOW}☁️  Installing AWS CLI v2...${NC}"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo yum install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
echo -e "${YELLOW}🔧 Installing eksctl...${NC}"
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install Helm
echo -e "${YELLOW}⛵ Installing Helm...${NC}"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Node.js (for JavaScript linting)
echo -e "${YELLOW}📦 Installing Node.js...${NC}"
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Install Git
echo -e "${YELLOW}📝 Installing Git...${NC}"
sudo yum install -y git

# Install additional tools
echo -e "${YELLOW}🛠️  Installing additional tools...${NC}"
sudo yum install -y curl wget vim htop

# Configure Jenkins
echo -e "${YELLOW}⚙️  Configuring Jenkins...${NC}"

# Create Jenkins directories
sudo mkdir -p /var/lib/jenkins/.kube
sudo mkdir -p /var/lib/jenkins/.aws
sudo mkdir -p /var/lib/jenkins/.docker

# Set proper permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
sudo chown -R jenkins:jenkins /var/lib/jenkins/.aws
sudo chown -R jenkins:jenkins /var/lib/jenkins/.docker

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Configure firewall (if needed)
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
sudo yum install -y firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --reload

# Create Jenkins plugins installation script
cat > /tmp/install-jenkins-plugins.sh << 'EOF'
#!/bin/bash

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
while ! curl -s http://localhost:8080 > /dev/null; do
    sleep 5
done

# Get initial admin password
JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "Jenkins initial admin password: $JENKINS_PASSWORD"

# Install Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install essential plugins
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin \
    git \
    workflow-aggregator \
    docker-workflow \
    kubernetes \
    aws-credentials \
    pipeline-stage-view \
    blueocean \
    slack \
    build-timeout \
    timestamper \
    ws-cleanup

# Restart Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD restart

echo "Jenkins plugins installed successfully!"
EOF

chmod +x /tmp/install-jenkins-plugins.sh

# Create systemd service for Jenkins plugin installation
sudo tee /etc/systemd/system/jenkins-setup.service > /dev/null << EOF
[Unit]
Description=Jenkins Initial Setup
After=jenkins.service
Requires=jenkins.service

[Service]
Type=oneshot
User=ec2-user
ExecStart=/tmp/install-jenkins-plugins.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable jenkins-setup.service

# Create Docker daemon configuration for Jenkins
sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker

echo -e "${GREEN}✅ Jenkins setup completed successfully!${NC}"
echo -e "${YELLOW}📝 Setup Information:${NC}"
echo "  Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "  Initial Admin Password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'Jenkins not started yet')"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Access Jenkins web interface using the URL above"
echo "2. Use the initial admin password to unlock Jenkins"
echo "3. Install suggested plugins or use the custom plugin list"
echo "4. Create an admin user"
echo "5. Configure Jenkins with:"
echo "   - Docker Hub credentials"
echo "   - AWS credentials"
echo "   - Kubernetes config"
echo "6. Create a new pipeline job pointing to your Git repository"
echo ""
echo -e "${YELLOW}⚠️  Security Note:${NC}"
echo "Make sure to:"
echo "- Change default passwords"
echo "- Configure proper security groups"
echo "- Enable HTTPS in production"
echo "- Regularly update Jenkins and plugins"

# Cleanup
rm -f awscliv2.zip
rm -rf aws/
rm -f kubectl
