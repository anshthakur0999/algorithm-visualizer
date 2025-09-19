# CI/CD Deployment Guide

This guide provides step-by-step instructions for setting up a complete CI/CD pipeline for the Algorithm Visualizer application using Jenkins, Docker, and Kubernetes on AWS.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │     Jenkins     │    │   Docker Hub    │
│   (Git Push)    │───▶│   (CI/CD)       │───▶│   (Registry)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   AWS EKS       │
                       │  (Kubernetes)   │
                       └─────────────────┘
```

## 📋 Prerequisites

### Required Tools
- AWS CLI v2
- Docker
- kubectl
- eksctl
- Helm
- Git

### Required Accounts
- AWS Account with appropriate permissions
- Docker Hub account
- GitHub/GitLab account (for source code)

### Required Permissions
Your AWS user/role needs the following permissions:
- EC2 full access
- EKS full access
- IAM permissions for creating roles
- VPC permissions
- CloudFormation permissions

## 🚀 Quick Start

### Step 1: Clone and Prepare Repository

```bash
git clone https://github.com/anshthakur0999/algorithm-visualizer.git
cd algorithm-visualizer

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### Step 2: Set Up AWS Infrastructure

#### 2.1 Create EKS Cluster

```bash
# Make script executable
chmod +x scripts/setup-eks-cluster.sh

# Run the setup script
./scripts/setup-eks-cluster.sh
```

This script will:
- Create an EKS cluster with managed node groups
- Install AWS Load Balancer Controller
- Install metrics server for autoscaling
- Configure necessary IAM roles

#### 2.2 Create Jenkins EC2 Instance

```bash
# Make script executable
chmod +x scripts/create-jenkins-ec2.sh

# Update the script with your key pair name
nano scripts/create-jenkins-ec2.sh

# Run the script
./scripts/create-jenkins-ec2.sh
```

### Step 3: Configure Jenkins

#### 3.1 Access Jenkins

1. Wait 5-10 minutes for the EC2 instance to complete setup
2. Access Jenkins at: `http://YOUR_EC2_PUBLIC_IP:8080`
3. Get the initial admin password:

```bash
ssh -i ~/.ssh/YOUR_KEY.pem ec2-user@YOUR_EC2_PUBLIC_IP 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

#### 3.2 Initial Jenkins Setup

1. Unlock Jenkins with the initial admin password
2. Install suggested plugins
3. Create an admin user
4. Configure Jenkins URL

#### 3.3 Configure Credentials

```bash
# Make script executable
chmod +x scripts/configure-jenkins-credentials.sh

# Run the credential configuration script
./scripts/configure-jenkins-credentials.sh
```

This will configure:
- Docker Hub credentials
- AWS credentials
- Kubernetes config file

### Step 4: Update Configuration Files

#### 4.1 Update Docker Image Name

Edit `k8s/deployment.yaml` and `Jenkinsfile`:

```yaml
# In k8s/deployment.yaml
image: YOUR_DOCKERHUB_USERNAME/algorithm-visualizer:latest
```

```groovy
# In Jenkinsfile
DOCKER_IMAGE = 'YOUR_DOCKERHUB_USERNAME/algorithm-visualizer'
```

#### 4.2 Update Ingress Configuration

Edit `k8s/ingress.yaml`:

```yaml
# Update with your domain
host: algorithm-visualizer.yourdomain.com
```

### Step 5: Create Jenkins Pipeline

1. In Jenkins, click "New Item"
2. Enter name: "algorithm-visualizer-pipeline"
3. Select "Pipeline" and click OK
4. In the Pipeline section:
   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: Your Git repository URL
   - Credentials: Select your Git credentials (if private repo)
   - Branch: `*/main` or `*/master`
   - Script Path: `Jenkinsfile`
5. Save the configuration

### Step 6: Run the Pipeline

1. Click "Build Now" on your pipeline
2. Monitor the build progress
3. Check each stage for any errors

## 🔧 Manual Deployment (Alternative)

If you prefer to deploy manually without Jenkins:

### Build and Push Docker Image

```bash
# Build the image
docker build -t YOUR_DOCKERHUB_USERNAME/algorithm-visualizer:latest .

# Push to Docker Hub
docker login
docker push YOUR_DOCKERHUB_USERNAME/algorithm-visualizer:latest
```

### Deploy to Kubernetes

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name algorithm-visualizer-cluster

# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

# Check deployment status
kubectl get pods -n algorithm-visualizer
kubectl get services -n algorithm-visualizer
kubectl get ingress -n algorithm-visualizer
```

## 🧪 Testing the Deployment

### Local Testing

```bash
# Test with Docker Compose
docker-compose up -d

# Access the application
curl http://localhost:8080

# Check health endpoint
curl http://localhost:8080/health

# Cleanup
docker-compose down
```

### Kubernetes Testing

```bash
# Check pod status
kubectl get pods -n algorithm-visualizer

# Check service endpoints
kubectl get endpoints -n algorithm-visualizer

# Port forward for testing
kubectl port-forward -n algorithm-visualizer service/algorithm-visualizer-service 8080:80

# Test the application
curl http://localhost:8080
```

## 📊 Monitoring and Logging

### View Application Logs

```bash
# Get pod logs
kubectl logs -n algorithm-visualizer -l app=algorithm-visualizer

# Follow logs in real-time
kubectl logs -n algorithm-visualizer -l app=algorithm-visualizer -f
```

### Monitor Resource Usage

```bash
# Check resource usage
kubectl top pods -n algorithm-visualizer
kubectl top nodes

# Check HPA status
kubectl get hpa -n algorithm-visualizer
```

## 🔒 Security Considerations

### Production Security Checklist

- [ ] Enable HTTPS with SSL certificates
- [ ] Configure proper security groups
- [ ] Use IAM roles instead of access keys
- [ ] Enable Jenkins security features
- [ ] Regularly update all components
- [ ] Implement network policies
- [ ] Use secrets for sensitive data
- [ ] Enable audit logging

### SSL/TLS Configuration

1. Request an SSL certificate from AWS Certificate Manager
2. Update the ingress configuration with the certificate ARN
3. Configure HTTPS redirect

## 🚨 Troubleshooting

### Common Issues

#### Jenkins Build Fails

```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Check Docker daemon
sudo systemctl status docker

# Check disk space
df -h
```

#### Kubernetes Deployment Issues

```bash
# Describe pod for events
kubectl describe pod -n algorithm-visualizer POD_NAME

# Check node status
kubectl get nodes

# Check cluster events
kubectl get events -n algorithm-visualizer --sort-by='.lastTimestamp'
```

#### Network Issues

```bash
# Check security groups
aws ec2 describe-security-groups --group-names jenkins-sg

# Check load balancer
kubectl get ingress -n algorithm-visualizer -o yaml
```

## 🔄 Updating the Application

### Automated Updates (via Jenkins)

1. Push changes to your Git repository
2. Jenkins will automatically trigger a build
3. New Docker image will be built and pushed
4. Kubernetes deployment will be updated

### Manual Updates

```bash
# Build new image with version tag
docker build -t YOUR_DOCKERHUB_USERNAME/algorithm-visualizer:v1.1.0 .
docker push YOUR_DOCKERHUB_USERNAME/algorithm-visualizer:v1.1.0

# Update deployment
kubectl set image deployment/algorithm-visualizer -n algorithm-visualizer algorithm-visualizer=YOUR_DOCKERHUB_USERNAME/algorithm-visualizer:v1.1.0

# Check rollout status
kubectl rollout status deployment/algorithm-visualizer -n algorithm-visualizer
```

## 🧹 Cleanup

### Remove Kubernetes Resources

```bash
kubectl delete namespace algorithm-visualizer
```

### Remove EKS Cluster

```bash
eksctl delete cluster --name algorithm-visualizer-cluster --region us-west-2
```

### Remove EC2 Instance

```bash
aws ec2 terminate-instances --instance-ids YOUR_INSTANCE_ID --region us-west-2
```

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review Jenkins and Kubernetes logs
- Consult AWS EKS documentation
- Open an issue in the project repository

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

## 🎯 Next Steps

After successful deployment, consider these enhancements:

### Performance Optimization
- Implement CDN (CloudFront) for static assets
- Add Redis caching layer
- Optimize Docker image size
- Configure resource limits and requests

### Monitoring and Observability
- Set up Prometheus and Grafana
- Implement application metrics
- Configure alerting rules
- Add distributed tracing

### Security Enhancements
- Implement OAuth/OIDC authentication
- Add rate limiting
- Configure Web Application Firewall (WAF)
- Implement secrets rotation

### Development Workflow
- Set up staging environment
- Implement feature branch deployments
- Add automated testing
- Configure code quality gates

---

**🎉 Congratulations!** You now have a complete CI/CD pipeline for your Algorithm Visualizer application!
