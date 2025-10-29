# CI/CD Pipeline Setup Guide

This guide will help you set up automated deployments to AWS ECS using GitHub Actions.

## 🎯 What This Pipeline Does

Every time you push code to the `main` or `master` branch:
1. ✅ Builds a new Docker image
2. ✅ Pushes it to AWS ECR
3. ✅ Updates the ECS task definition
4. ✅ Deploys to ECS (zero-downtime rolling update)
5. ✅ Waits for deployment to stabilize

---

## 📋 Prerequisites

- GitHub account
- AWS account with ECS already set up (✅ You have this!)
- AWS IAM user with appropriate permissions

---

## 🚀 Setup Steps

### Step 1: Create IAM User for GitHub Actions

Create a dedicated IAM user with programmatic access:

```bash
aws iam create-user --user-name github-actions-ecs-deploy
```

### Step 2: Create IAM Policy

Save this policy to a file named `github-actions-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::503015902469:role/ecsTaskExecutionRole"
    }
  ]
}
```

Then create and attach the policy:

```bash
# Create the policy
aws iam create-policy \
  --policy-name GitHubActionsECSDeployPolicy \
  --policy-document file://github-actions-policy.json

# Attach to user
aws iam attach-user-policy \
  --user-name github-actions-ecs-deploy \
  --policy-arn arn:aws:iam::503015902469:policy/GitHubActionsECSDeployPolicy
```

### Step 3: Create Access Keys

```bash
aws iam create-access-key --user-name github-actions-ecs-deploy
```

**⚠️ IMPORTANT:** Save the output! You'll need:
- `AccessKeyId`
- `SecretAccessKey`

---

### Step 4: Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these two secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AccessKeyId from Step 3 |
| `AWS_SECRET_ACCESS_KEY` | Your SecretAccessKey from Step 3 |

---

### Step 5: Initialize Git Repository (if not already done)

```bash
# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit with CI/CD pipeline"

# Create GitHub repository (replace YOUR_USERNAME)
# Then push:
git remote add origin https://github.com/YOUR_USERNAME/algorithm-visualizer.git
git branch -M main
git push -u origin main
```

---

### Step 6: Test the Pipeline

Make a small change to your code:

```bash
# Edit a file (e.g., index.html)
# Then commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push
```

Go to GitHub → **Actions** tab to watch the deployment!

---

## 🔍 Monitoring Deployments

### View GitHub Actions Logs
- Go to your repository on GitHub
- Click the **Actions** tab
- Click on the latest workflow run

### View ECS Deployment
```bash
# Check service status
aws ecs describe-services \
  --cluster visualizer-cluster \
  --services algorithm-visualizer-blue \
  --region us-east-1

# View running tasks
aws ecs list-tasks \
  --cluster visualizer-cluster \
  --service-name algorithm-visualizer-blue \
  --region us-east-1
```

### View Application Logs
```bash
# Get the latest log stream
aws logs tail /ecs/algorithm-visualizer --follow --region us-east-1
```

---

## 🎨 Workflow Features

### Automatic Triggers
- ✅ Pushes to `main` or `master` branch
- ✅ Manual trigger via GitHub UI (workflow_dispatch)

### Image Tagging Strategy
- `latest` - Always points to the most recent build
- `<git-sha>` - Specific commit hash for rollback capability

### Zero-Downtime Deployment
- ECS performs rolling updates
- New tasks start before old ones stop
- Health checks ensure new tasks are healthy

---

## 🔄 Rolling Back a Deployment

If something goes wrong, you can rollback:

### Option 1: Revert Git Commit
```bash
git revert HEAD
git push
```
This triggers a new deployment with the previous code.

### Option 2: Manual Rollback via AWS
```bash
# List task definitions
aws ecs list-task-definitions --family-prefix algorithm-visualizer-task --region us-east-1

# Update service to previous revision
aws ecs update-service \
  --cluster visualizer-cluster \
  --service algorithm-visualizer-blue \
  --task-definition algorithm-visualizer-task:1 \
  --region us-east-1
```

---

## 🛠️ Troubleshooting

### Pipeline Fails at "Login to Amazon ECR"
- ✅ Check AWS credentials in GitHub Secrets
- ✅ Verify IAM user has ECR permissions

### Pipeline Fails at "Deploy Amazon ECS task definition"
- ✅ Check IAM user has ECS permissions
- ✅ Verify `iam:PassRole` permission for ecsTaskExecutionRole

### Deployment Succeeds but App Doesn't Work
- ✅ Check ECS service events: `aws ecs describe-services ...`
- ✅ Check CloudWatch logs: `aws logs tail /ecs/algorithm-visualizer --follow`
- ✅ Check target group health: `aws elbv2 describe-target-health ...`

---

## 📊 Pipeline Workflow Diagram

```
┌─────────────────┐
│  Push to GitHub │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Checkout Code   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Configure AWS   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Login to ECR    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Build Image     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Push to ECR     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Task Def │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Deploy to ECS   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ ✅ Success!     │
└─────────────────┘
```

---

## 🎯 Next Steps

1. ✅ Set up the IAM user and permissions
2. ✅ Add secrets to GitHub
3. ✅ Push code to trigger first deployment
4. 🚀 Make changes and watch automatic deployments!

---

## 🔐 Security Best Practices

- ✅ Use dedicated IAM user for CI/CD (not your personal credentials)
- ✅ Follow principle of least privilege (only necessary permissions)
- ✅ Rotate access keys regularly
- ✅ Never commit AWS credentials to Git
- ✅ Use GitHub Secrets for sensitive data

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)

