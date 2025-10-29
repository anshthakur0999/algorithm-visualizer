# ECS Blue-Green Deployment - Free Tier Edition
## Algorithm Visualizer - College Assignment

---

## 📋 Overview

This is a **simplified, free-tier friendly** blue-green deployment strategy using:
- **Jenkins** (free, self-hosted or local)
- **Docker** (free)
- **AWS ECS Fargate** (free tier: 750 hours/month)
- **AWS ECR** (free tier: 500MB storage)
- **GitHub** (free)

### Free Tier Limits
- ✅ 750 hours/month ECS Fargate (0.25 vCPU, 512MB RAM)
- ✅ 500MB ECR storage
- ✅ 1GB CloudWatch Logs
- ✅ ALB: First 15 LCUs free
- ✅ Data transfer: 1GB/month free

---

## 🎯 Simplified Architecture

```
Git Push
   ↓
Jenkins (Local/EC2 Micro)
   ├─ Build & Test
   ├─ Docker Build
   └─ Push to ECR
   ↓
AWS ECR (Free tier)
   ↓
AWS ECS Fargate (Free tier)
   ├─ Blue Service (v1.0)
   └─ Green Service (v1.1)
   ↓
AWS ALB (Free tier)
   ↓
CloudWatch Logs (Free tier)
```

---

## 💰 Cost Breakdown (Free Tier)

| Service | Free Tier | Cost |
|---------|-----------|------|
| ECS Fargate | 750 hrs/month | $0 |
| ECR | 500MB storage | $0 |
| ALB | 15 LCUs | $0 |
| CloudWatch Logs | 1GB | $0 |
| Data Transfer | 1GB/month | $0 |
| **Total** | | **$0** |

**Note**: After free tier, costs are minimal (~$5-10/month for small app)

---

## 🚀 Quick Start (30 Minutes)

### Prerequisites
- AWS Free Tier Account
- Docker installed locally
- Git account (GitHub)
- Jenkins (can run locally or on EC2 micro)

### Step 1: Create ECR Repository (5 min)
```bash
aws ecr create-repository \
  --repository-name algorithm-visualizer \
  --region us-east-1
```

### Step 2: Build & Push Docker Image (10 min)
```bash
# Build
docker build -t algorithm-visualizer:v1.0 .

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com

# Tag & Push
docker tag algorithm-visualizer:v1.0 \
  <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/algorithm-visualizer:v1.0

docker push \
  <ACCOUNT>.dkr.ecr.us-east-1.amazonaws.com/algorithm-visualizer:v1.0
```

### Step 3: Create ECS Cluster (5 min)
```bash
aws ecs create-cluster --cluster-name visualizer-cluster
```

### Step 4: Deploy Blue Service (10 min)
See ECS_IMPLEMENTATION_GUIDE.md for detailed steps

---

## 📊 Minimal Setup for Assignment

### What You NEED
1. ✅ Dockerfile
2. ✅ ECR Repository
3. ✅ ECS Cluster
4. ✅ ECS Services (Blue & Green)
5. ✅ ALB for traffic switching
6. ✅ Jenkins pipeline (basic)
7. ✅ Deployment scripts

### What You DON'T NEED (for assignment)
- ❌ Kubernetes
- ❌ Complex monitoring
- ❌ Auto-scaling
- ❌ Multiple regions
- ❌ RDS database
- ❌ VPC customization

---

## 🛠️ Technology Stack (Minimal)

| Component | Technology | Why |
|-----------|-----------|-----|
| Application | Node.js/Static | Simple, free |
| Containerization | Docker | Free, standard |
| Registry | AWS ECR | Free tier |
| Orchestration | ECS Fargate | Free tier, simple |
| CI/CD | Jenkins | Free, self-hosted |
| Load Balancing | ALB | Free tier |
| Logs | CloudWatch | Free tier |

---

## 📈 Implementation Timeline

### Week 1: Setup (2-3 hours)
- [ ] Create AWS account
- [ ] Create Dockerfile
- [ ] Create ECR repository
- [ ] Test Docker locally

### Week 2: Infrastructure (2-3 hours)
- [ ] Create ECS cluster
- [ ] Create task definitions
- [ ] Create services
- [ ] Create ALB

### Week 3: CI/CD (2-3 hours)
- [ ] Set up Jenkins
- [ ] Create Jenkinsfile
- [ ] Configure GitHub webhook
- [ ] Test pipeline

### Week 4: Blue-Green (2-3 hours)
- [ ] Deploy Blue
- [ ] Deploy Green
- [ ] Create switching scripts
- [ ] Test deployment

### Week 5: Testing & Documentation (2-3 hours)
- [ ] Test full pipeline
- [ ] Document process
- [ ] Create demo
- [ ] Prepare presentation

**Total Time: ~10-15 hours**

---

## 🔑 Key Concepts for Assignment

### Blue-Green Deployment
- **Blue**: Current production (v1.0)
- **Green**: New version (v1.1)
- **Switch**: ALB routes traffic to Green
- **Rollback**: ALB routes back to Blue

### Why Blue-Green?
- ✅ Zero downtime
- ✅ Easy rollback
- ✅ Full testing before production
- ✅ Perfect for demonstrations

### How It Works
```
1. Deploy new version to Green
2. Run tests on Green
3. Switch traffic: Blue → Green
4. Monitor Green
5. If issues: Switch back to Blue
6. If success: Green becomes new Blue
```

---

## 📋 Deliverables for Assignment

### Code
- [ ] Dockerfile
- [ ] docker-compose.yml
- [ ] Jenkinsfile
- [ ] Deployment scripts (bash)

### Infrastructure
- [ ] ECR repository
- [ ] ECS cluster
- [ ] Task definitions (Blue & Green)
- [ ] Services (Blue & Green)
- [ ] ALB configuration

### Documentation
- [ ] Architecture diagram
- [ ] Deployment guide
- [ ] How to run demo
- [ ] Troubleshooting guide

### Demo
- [ ] Show Blue running
- [ ] Deploy Green
- [ ] Switch traffic
- [ ] Show rollback

---

## 🎓 Learning Outcomes

By completing this assignment, you'll learn:
- ✅ Docker containerization
- ✅ AWS ECS basics
- ✅ CI/CD with Jenkins
- ✅ Blue-green deployment pattern
- ✅ Infrastructure automation
- ✅ DevOps best practices

---

## 💡 Pro Tips for Assignment

1. **Start Simple**: Get basic deployment working first
2. **Use Free Tier**: Don't exceed free tier limits
3. **Document Everything**: Show your understanding
4. **Test Thoroughly**: Demo should be smooth
5. **Keep Scripts Simple**: Bash scripts are fine
6. **Use Defaults**: Don't over-engineer
7. **Version Control**: Push everything to GitHub

---

## ⚠️ Free Tier Gotchas

### Don't Do This
- ❌ Leave services running 24/7 (will exceed 750 hours)
- ❌ Store large images in ECR (500MB limit)
- ❌ Use multiple ALBs (only 1 free)
- ❌ Transfer lots of data (1GB/month limit)

### Do This Instead
- ✅ Stop services when not using
- ✅ Clean up old images
- ✅ Use single ALB for both Blue & Green
- ✅ Keep data transfer minimal

---

## 🚀 Next Steps

1. Read **ECS_IMPLEMENTATION_GUIDE.md** (simplified version)
2. Read **ECS_JENKINS_PIPELINE.md** (basic pipeline)
3. Follow step-by-step implementation
4. Test locally first
5. Deploy to AWS
6. Create demo video/presentation

---

## 📞 Quick Reference

### Check Free Tier Usage
```bash
# View billing
aws ce get-cost-and-usage \
  --time-period Start=2025-10-01,End=2025-10-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### Stop Services (Save Money)
```bash
# Scale down to 0
aws ecs update-service \
  --cluster visualizer-cluster \
  --service algorithm-visualizer-blue \
  --desired-count 0
```

### View Logs
```bash
# Stream logs
aws logs tail /ecs/algorithm-visualizer --follow
```

---

## 📝 Assignment Checklist

- [ ] AWS account created
- [ ] Dockerfile working locally
- [ ] ECR repository created
- [ ] Image pushed to ECR
- [ ] ECS cluster created
- [ ] Blue service deployed
- [ ] Green service deployed
- [ ] ALB configured
- [ ] Jenkins pipeline working
- [ ] Blue-green switch working
- [ ] Rollback working
- [ ] Documentation complete
- [ ] Demo prepared
- [ ] GitHub repo updated

---

**Ready to start? Begin with ECS_IMPLEMENTATION_GUIDE.md!** 🚀

**Estimated Total Cost: $0 (Free Tier)**

