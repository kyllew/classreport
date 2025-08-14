# 🚀 AWS CodeBuild CI/CD Setup for Class Report Application

This guide sets up a complete CI/CD pipeline using AWS CodeBuild that automatically builds and deploys your Class Report application whenever you push code to GitHub.

## 🎯 What You Get

### **Automated CI/CD Pipeline:**
```
GitHub Push → CodeBuild → ECR → ECS Deployment
```

### **Features:**
- ✅ **Automatic builds** on GitHub push
- ✅ **Docker image building** and pushing to ECR
- ✅ **Zero-downtime deployments** to ECS
- ✅ **Build logs** in CloudWatch
- ✅ **Image vulnerability scanning**
- ✅ **Automatic image cleanup** (keeps last 10 images)

## 🚀 Quick Setup

### **One-Command Deployment:**
```bash
./deploy-codebuild.sh
```

This script will:
1. Create ECR repository
2. Set up CodeBuild project
3. Configure GitHub webhook
4. Run initial build
5. Deploy application infrastructure
6. Provide you with URLs and monitoring links

## 📋 Prerequisites

1. **AWS CLI configured:**
   ```bash
   aws configure
   ```

2. **Docker installed:**
   ```bash
   docker --version
   ```

3. **GitHub repository** with your code
4. **AWS permissions** for CodeBuild, ECR, ECS, CloudFormation

## 🏗️ Architecture

### **CI/CD Flow:**
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│   GitHub    │───▶│  CodeBuild   │───▶│     ECR     │───▶│     ECS     │
│   (Source)  │    │   (Build)    │    │  (Registry) │    │  (Deploy)   │
└─────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
                           │
                           ▼
                   ┌──────────────┐
                   │ CloudWatch   │
                   │   (Logs)     │
                   └──────────────┘
```

### **Components Created:**
- **ECR Repository** - Private Docker registry
- **CodeBuild Project** - Build and test automation
- **IAM Roles** - Secure permissions
- **CloudWatch Logs** - Build monitoring
- **GitHub Webhook** - Automatic triggers

## 🔧 Configuration Files

### **buildspec.yml** - Build Instructions
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - docker build -t $IMAGE_REPO_NAME:latest .
      - docker tag $IMAGE_REPO_NAME:latest $REPOSITORY_URI:latest
  post_build:
    commands:
      - docker push $REPOSITORY_URI:latest
      - aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --force-new-deployment
```

### **Environment Variables:**
- `AWS_DEFAULT_REGION` - AWS region
- `AWS_ACCOUNT_ID` - Your AWS account ID
- `IMAGE_REPO_NAME` - ECR repository name
- `ECS_CLUSTER_NAME` - ECS cluster name
- `ECS_SERVICE_NAME` - ECS service name

## 📊 Monitoring

### **Build Status:**
Monitor builds at:
```
https://console.aws.amazon.com/codesuite/codebuild/projects/classreport-codebuild-build
```

### **Build Logs:**
View detailed logs in CloudWatch:
```
/aws/codebuild/classreport-codebuild-build
```

### **ECR Images:**
Check pushed images:
```
https://console.aws.amazon.com/ecr/repositories/classreport
```

## 🔄 Development Workflow

### **Making Changes:**
1. **Make code changes** locally
2. **Commit and push** to GitHub main branch:
   ```bash
   git add .
   git commit -m "Update application"
   git push origin main
   ```
3. **CodeBuild automatically triggers**
4. **Monitor build** in AWS Console
5. **Application updates** automatically

### **Build Process:**
1. **Source** - CodeBuild pulls from GitHub
2. **Build** - Docker image is built
3. **Test** - Run any tests (if configured)
4. **Push** - Image pushed to ECR
5. **Deploy** - ECS service updated with new image

## 🎛️ Advanced Configuration

### **Custom Build Commands:**
Edit `buildspec.yml` to add:
- **Unit tests**
- **Security scans**
- **Code quality checks**
- **Custom deployment logic**

### **Build Environment:**
- **Image**: `aws/codebuild/standard:5.0`
- **Compute**: `BUILD_GENERAL1_MEDIUM`
- **Privileged**: `true` (for Docker)

### **Webhook Filters:**
Currently triggers on:
- **Push events** to `main` branch
- **Pull request** events (optional)

## 💰 Cost Optimization

### **Current Setup:**
- **CodeBuild**: Pay per build minute (~$0.005/minute)
- **ECR**: $0.10/GB/month storage
- **Data Transfer**: Standard AWS rates

### **Cost-Saving Tips:**
1. **Optimize Dockerfile** - Use multi-stage builds
2. **Cache dependencies** - Reduce build time
3. **Cleanup old images** - Automatic lifecycle policy
4. **Right-size builds** - Use appropriate compute type

## 🔒 Security Features

### **Implemented:**
- ✅ **IAM roles** with least privilege
- ✅ **Private ECR repository**
- ✅ **Encrypted build artifacts**
- ✅ **VPC isolation** (optional)
- ✅ **Image vulnerability scanning**

### **Best Practices:**
- **No hardcoded secrets** in buildspec
- **Use AWS Secrets Manager** for sensitive data
- **Regular security updates** of base images
- **Monitor build logs** for security issues

## 🚨 Troubleshooting

### **Common Issues:**

#### **Build Fails:**
```bash
# Check build logs
aws logs tail /aws/codebuild/classreport-codebuild-build --follow
```

#### **Docker Build Issues:**
- Verify Dockerfile syntax
- Check base image availability
- Ensure all dependencies are listed

#### **ECR Push Fails:**
- Verify IAM permissions
- Check ECR repository exists
- Confirm region settings

#### **ECS Deployment Fails:**
- Check ECS service exists
- Verify task definition
- Check security groups and networking

### **Debugging Commands:**
```bash
# Check CodeBuild project
aws codebuild batch-get-projects --names classreport-codebuild-build

# List recent builds
aws codebuild list-builds-for-project --project-name classreport-codebuild-build

# Check ECR images
aws ecr list-images --repository-name classreport
```

## 🔄 Pipeline Variations

### **Option 1: CodeBuild Only (Current)**
- Simple webhook-triggered builds
- Direct ECS deployment
- Good for small teams

### **Option 2: Full CodePipeline**
- Multi-stage pipeline
- Manual approval gates
- Better for enterprise

### **Option 3: GitHub Actions**
- GitHub-native CI/CD
- Marketplace integrations
- Good for GitHub-centric workflows

## 📈 Scaling

### **Multi-Environment:**
Create separate stacks for:
- **Development** - Auto-deploy from `develop` branch
- **Staging** - Auto-deploy from `staging` branch  
- **Production** - Manual approval required

### **Multi-Region:**
Deploy to multiple regions:
- **Primary**: us-east-1
- **Secondary**: us-west-2
- **Cross-region replication**

## 🧹 Cleanup

### **Remove CI/CD Pipeline:**
```bash
aws cloudformation delete-stack --stack-name classreport-codebuild
```

### **Remove Application:**
```bash
aws cloudformation delete-stack --stack-name classreport-stack
```

### **Manual Cleanup:**
- Delete ECR images manually
- Remove S3 artifacts bucket
- Clean up CloudWatch logs

---

## 🎉 Success!

After running `./deploy-codebuild.sh`, you'll have:

- ✅ **Automated CI/CD pipeline**
- ✅ **Professional deployment process**
- ✅ **Monitoring and logging**
- ✅ **Scalable infrastructure**
- ✅ **Security best practices**

**Push code → Automatic deployment!** 🚀