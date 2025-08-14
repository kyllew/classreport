# 🚀 AWS Deployment Guide for Class Report Application

This guide will help you deploy the Class Report Application to AWS using ECS Fargate with an Application Load Balancer.

## 📋 Prerequisites

1. **AWS CLI installed and configured**
   ```bash
   aws configure
   ```

2. **Docker installed and running**
   ```bash
   docker --version
   ```

3. **AWS Account with appropriate permissions**
   - ECS Full Access
   - ECR Full Access
   - CloudFormation Full Access
   - IAM permissions to create roles
   - VPC and EC2 permissions

## 🎯 Quick Deployment (Recommended)

### Option 1: Complete Automated Deployment

Run the complete deployment script that handles everything:

```bash
./deploy-cloudformation.sh
```

This script will:
- ✅ Build and push Docker image to ECR
- ✅ Create all AWS resources using CloudFormation
- ✅ Deploy the application to ECS Fargate
- ✅ Set up Application Load Balancer
- ✅ Configure security groups and networking
- ✅ Provide you with the application URL

### Option 2: Manual Step-by-Step Deployment

If you prefer more control, follow these steps:

#### Step 1: Build and Push Docker Image
```bash
./deploy.sh
```

#### Step 2: Deploy Infrastructure
```bash
# Get your VPC and subnet information
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text | tr '\t' ',')

# Deploy CloudFormation stack
aws cloudformation deploy \
  --template-file cloudformation-template.yaml \
  --stack-name classreport-stack \
  --parameter-overrides \
    VpcId=${VPC_ID} \
    SubnetIds=${SUBNET_IDS} \
    ImageUri=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/classreport:latest \
  --capabilities CAPABILITY_NAMED_IAM
```

## 🏗️ Architecture Overview

```
Internet → ALB → ECS Fargate → Flask App
                     ↓
               CloudWatch Logs
                     ↓
               AWS Bedrock (AI Analysis)
```

### Components Created:
- **ECS Cluster**: Runs your containerized application
- **ECS Service**: Manages application instances
- **Application Load Balancer**: Distributes traffic
- **ECR Repository**: Stores Docker images
- **CloudWatch Logs**: Application logging
- **IAM Roles**: Secure access permissions
- **Security Groups**: Network security

## 🔧 Configuration

### Environment Variables
The application uses these environment variables:
- `FLASK_ENV=production`
- `AWS_DEFAULT_REGION=us-east-1`

### AWS Permissions Required
The ECS task has permissions for:
- **Bedrock**: For AI-powered feedback analysis
- **CloudWatch**: For logging
- **ECR**: For pulling container images

## 📊 Monitoring and Logs

### CloudWatch Logs
View application logs at:
```
/ecs/classreport
```

### ECS Service Monitoring
Monitor your service in the AWS Console:
- ECS → Clusters → classreport-cluster → Services

### Application Load Balancer
Check load balancer health:
- EC2 → Load Balancers → classreport-alb

## 🔄 Updates and Maintenance

### Deploying Updates
1. Make your code changes
2. Run the deployment script again:
   ```bash
   ./deploy-cloudformation.sh
   ```

### Scaling
To change the number of running instances:
```bash
aws ecs update-service \
  --cluster classreport-cluster \
  --service classreport-service \
  --desired-count 2
```

### Rolling Back
To rollback to a previous version:
```bash
aws ecs update-service \
  --cluster classreport-cluster \
  --service classreport-service \
  --task-definition classreport-task:PREVIOUS_REVISION
```

## 💰 Cost Optimization

### Current Configuration:
- **ECS Fargate**: 0.5 vCPU, 1GB RAM
- **Application Load Balancer**: Standard pricing
- **CloudWatch Logs**: 7-day retention

### Cost-Saving Tips:
1. **Use Spot Instances**: For non-production workloads
2. **Adjust Resources**: Reduce CPU/memory if not needed
3. **Log Retention**: Reduce retention period
4. **Auto Scaling**: Scale down during low usage

## 🔒 Security Best Practices

### Implemented Security:
- ✅ IAM roles with least privilege
- ✅ Security groups restricting access
- ✅ Private container networking
- ✅ HTTPS-ready load balancer

### Additional Security (Optional):
- Enable AWS WAF on the load balancer
- Use AWS Certificate Manager for SSL/TLS
- Enable VPC Flow Logs
- Set up AWS Config for compliance

## 🚨 Troubleshooting

### Common Issues:

#### 1. Service Won't Start
```bash
# Check service events
aws ecs describe-services --cluster classreport-cluster --services classreport-service
```

#### 2. Health Check Failures
```bash
# Check container logs
aws logs tail /ecs/classreport --follow
```

#### 3. Image Pull Errors
```bash
# Verify ECR repository and permissions
aws ecr describe-repositories --repository-names classreport
```

#### 4. Load Balancer Issues
- Check target group health in AWS Console
- Verify security group rules
- Ensure subnets are in different AZs

### Getting Help
- Check CloudWatch logs for application errors
- Review ECS service events
- Verify IAM permissions
- Check security group configurations

## 🧹 Cleanup

To remove all resources and avoid charges:
```bash
aws cloudformation delete-stack --stack-name classreport-stack
```

This will delete:
- ECS Service and Cluster
- Application Load Balancer
- Target Groups
- Security Groups
- IAM Roles
- CloudWatch Log Groups

**Note**: ECR repository and images need to be deleted manually if desired.

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review AWS CloudFormation events
3. Check application logs in CloudWatch
4. Verify AWS permissions and quotas

---

🎉 **Congratulations!** Your Class Report Application is now running on AWS with enterprise-grade infrastructure!