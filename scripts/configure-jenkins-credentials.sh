#!/bin/bash

# Jenkins Credentials Configuration Script
# This script helps configure Jenkins credentials via CLI

set -e

# Configuration
JENKINS_URL="http://localhost:8080"  # Update with your Jenkins URL
JENKINS_USER="admin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Configuring Jenkins Credentials${NC}"

# Check if Jenkins CLI is available
if [ ! -f "jenkins-cli.jar" ]; then
    echo -e "${YELLOW}📥 Downloading Jenkins CLI...${NC}"
    wget ${JENKINS_URL}/jnlpJars/jenkins-cli.jar
fi

# Function to create credentials
create_credential() {
    local cred_id=$1
    local cred_type=$2
    local description=$3
    
    echo -e "${YELLOW}🔑 Creating credential: $description${NC}"
    
    case $cred_type in
        "docker-hub")
            read -p "Enter Docker Hub username: " docker_username
            read -s -p "Enter Docker Hub password/token: " docker_password
            echo
            
            cat > /tmp/docker-cred.xml << EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$cred_id</id>
  <description>$description</description>
  <username>$docker_username</username>
  <password>$docker_password</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
            
            java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD create-credentials-by-xml system::system::jenkins _ < /tmp/docker-cred.xml
            rm /tmp/docker-cred.xml
            ;;
            
        "aws-credentials")
            read -p "Enter AWS Access Key ID: " aws_access_key
            read -s -p "Enter AWS Secret Access Key: " aws_secret_key
            echo
            
            cat > /tmp/aws-cred.xml << EOF
<com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$cred_id</id>
  <description>$description</description>
  <accessKey>$aws_access_key</accessKey>
  <secretKey>$aws_secret_key</secretKey>
</com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl>
EOF
            
            java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD create-credentials-by-xml system::system::jenkins _ < /tmp/aws-cred.xml
            rm /tmp/aws-cred.xml
            ;;
            
        "kubeconfig")
            read -p "Enter path to kubeconfig file: " kubeconfig_path
            
            if [ ! -f "$kubeconfig_path" ]; then
                echo -e "${RED}❌ Kubeconfig file not found: $kubeconfig_path${NC}"
                return 1
            fi
            
            kubeconfig_content=$(cat $kubeconfig_path | base64 -w 0)
            
            cat > /tmp/kube-cred.xml << EOF
<org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>$cred_id</id>
  <description>$description</description>
  <fileName>kubeconfig</fileName>
  <secretBytes>$kubeconfig_content</secretBytes>
</org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl>
EOF
            
            java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD create-credentials-by-xml system::system::jenkins _ < /tmp/kube-cred.xml
            rm /tmp/kube-cred.xml
            ;;
            
        "ssh-key")
            read -p "Enter path to SSH private key: " ssh_key_path
            read -p "Enter SSH username: " ssh_username
            
            if [ ! -f "$ssh_key_path" ]; then
                echo -e "${RED}❌ SSH key file not found: $ssh_key_path${NC}"
                return 1
            fi
            
            ssh_key_content=$(cat $ssh_key_path)
            
            cat > /tmp/ssh-cred.xml << EOF
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
  <scope>GLOBAL</scope>
  <id>$cred_id</id>
  <description>$description</description>
  <username>$ssh_username</username>
  <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
    <privateKey>$ssh_key_content</privateKey>
  </privateKeySource>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF
            
            java -jar jenkins-cli.jar -s $JENKINS_URL -auth $JENKINS_USER:$JENKINS_PASSWORD create-credentials-by-xml system::system::jenkins _ < /tmp/ssh-cred.xml
            rm /tmp/ssh-cred.xml
            ;;
    esac
}

# Get Jenkins admin password
if [ -z "$JENKINS_PASSWORD" ]; then
    read -s -p "Enter Jenkins admin password: " JENKINS_PASSWORD
    echo
fi

# Create credentials
echo -e "${YELLOW}📋 Setting up required credentials...${NC}"

# Docker Hub credentials
create_credential "docker-hub-credentials" "docker-hub" "Docker Hub credentials for pushing images"

# AWS credentials
create_credential "aws-credentials" "aws-credentials" "AWS credentials for EKS access"

# Kubeconfig file
create_credential "kubeconfig" "kubeconfig" "Kubernetes config file for cluster access"

# Optional: SSH key for Git repositories (if using private repos)
read -p "Do you want to add SSH credentials for Git repositories? (y/n): " add_ssh
if [ "$add_ssh" = "y" ] || [ "$add_ssh" = "Y" ]; then
    create_credential "git-ssh-key" "ssh-key" "SSH key for Git repository access"
fi

echo -e "${GREEN}✅ Jenkins credentials configured successfully!${NC}"
echo -e "${YELLOW}📝 Configured Credentials:${NC}"
echo "  - docker-hub-credentials: Docker Hub access"
echo "  - aws-credentials: AWS access for EKS"
echo "  - kubeconfig: Kubernetes cluster access"
if [ "$add_ssh" = "y" ] || [ "$add_ssh" = "Y" ]; then
    echo "  - git-ssh-key: Git repository access"
fi

echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Verify credentials in Jenkins UI: ${JENKINS_URL}/credentials/"
echo "2. Create a new Pipeline job"
echo "3. Configure the job to use your Git repository"
echo "4. Update the Jenkinsfile with your Docker Hub username"
echo "5. Run the pipeline to deploy your application"

# Cleanup
rm -f jenkins-cli.jar
