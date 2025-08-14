#!/bin/bash

# GitHub Integration Setup Helper
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔗 GitHub Integration Setup Helper${NC}"
echo -e "${YELLOW}This script will help you set up GitHub integration for your CI/CD pipeline${NC}"
echo ""

# Step 1: GitHub Token Setup
echo -e "${BLUE}📝 Step 1: GitHub Personal Access Token${NC}"
echo -e "You need a GitHub Personal Access Token with the following permissions:"
echo -e "• ${GREEN}repo${NC} - Full control of private repositories"
echo -e "• ${GREEN}admin:repo_hook${NC} - Full control of repository hooks"
echo ""
echo -e "${YELLOW}To create a token:${NC}"
echo -e "1. Go to: ${BLUE}https://github.com/settings/tokens${NC}"
echo -e "2. Click '${GREEN}Generate new token (classic)${NC}'"
echo -e "3. Give it a name like '${GREEN}AWS CodePipeline${NC}'"
echo -e "4. Select the required scopes above"
echo -e "5. Click '${GREEN}Generate token${NC}'"
echo -e "6. Copy the token (you won't see it again!)"
echo ""

# Step 2: Repository Setup
echo -e "${BLUE}📂 Step 2: Repository Configuration${NC}"
echo -e "Make sure your GitHub repository:"
echo -e "• ${GREEN}Contains your application code${NC}"
echo -e "• ${GREEN}Has the main branch${NC}"
echo -e "• ${GREEN}Is accessible with your token${NC}"
echo ""

# Step 3: AWS Permissions
echo -e "${BLUE}🔐 Step 3: AWS Permissions${NC}"
echo -e "Ensure your AWS user/role has permissions for:"
echo -e "• ${GREEN}CodePipeline${NC} - Full access"
echo -e "• ${GREEN}CodeBuild${NC} - Full access"
echo -e "• ${GREEN}ECR${NC} - Full access"
echo -e "• ${GREEN}ECS${NC} - Full access"
echo -e "• ${GREEN}CloudFormation${NC} - Full access"
echo -e "• ${GREEN}IAM${NC} - Create/manage roles"
echo ""

# Step 4: Deployment Options
echo -e "${BLUE}🚀 Step 4: Choose Your Deployment Method${NC}"
echo ""
echo -e "${YELLOW}Option 1: Interactive Deployment (Recommended)${NC}"
echo -e "Run: ${GREEN}./deploy-with-github.sh${NC}"
echo -e "• Prompts for GitHub token securely"
echo -e "• Full pipeline setup with monitoring"
echo -e "• Automatic webhook configuration"
echo ""
echo -e "${YELLOW}Option 2: Environment Variable${NC}"
echo -e "Set token as environment variable:"
echo -e "${GREEN}export GITHUB_TOKEN='your_token_here'${NC}"
echo -e "${GREEN}./deploy-with-github.sh${NC}"
echo ""
echo -e "${YELLOW}Option 3: AWS Systems Manager Parameter Store${NC}"
echo -e "Store token securely in AWS:"
echo -e "${GREEN}aws ssm put-parameter --name '/github/token' --value 'your_token' --type 'SecureString'${NC}"
echo ""

# Step 5: What Gets Created
echo -e "${BLUE}🏗️  Step 5: What Will Be Created${NC}"
echo -e "The deployment will create:"
echo -e "• ${GREEN}CodePipeline${NC} - 3-stage pipeline (Source → Build → Deploy)"
echo -e "• ${GREEN}CodeBuild Project${NC} - Docker image building"
echo -e "• ${GREEN}ECR Repository${NC} - Private Docker registry"
echo -e "• ${GREEN}GitHub Webhook${NC} - Automatic trigger on push"
echo -e "• ${GREEN}IAM Roles${NC} - Secure service permissions"
echo -e "• ${GREEN}S3 Bucket${NC} - Pipeline artifacts storage"
echo -e "• ${GREEN}CloudWatch Logs${NC} - Build and deployment logs"
echo ""

# Step 6: Pipeline Flow
echo -e "${BLUE}🔄 Step 6: CI/CD Pipeline Flow${NC}"
echo -e "Your automated workflow:"
echo -e "1. ${YELLOW}Push code${NC} to GitHub main branch"
echo -e "2. ${YELLOW}Webhook triggers${NC} CodePipeline"
echo -e "3. ${YELLOW}Source stage${NC} downloads code from GitHub"
echo -e "4. ${YELLOW}Build stage${NC} creates Docker image and pushes to ECR"
echo -e "5. ${YELLOW}Deploy stage${NC} updates ECS service with new image"
echo -e "6. ${YELLOW}Application${NC} is live with zero downtime"
echo ""

# Step 7: Monitoring and Management
echo -e "${BLUE}📊 Step 7: Monitoring Your Pipeline${NC}"
echo -e "After deployment, monitor via:"
echo -e "• ${GREEN}CodePipeline Console${NC} - Pipeline status and history"
echo -e "• ${GREEN}CodeBuild Console${NC} - Build logs and metrics"
echo -e "• ${GREEN}ECR Console${NC} - Docker images and vulnerability scans"
echo -e "• ${GREEN}ECS Console${NC} - Service health and scaling"
echo -e "• ${GREEN}CloudWatch${NC} - Logs and metrics"
echo ""

# Step 8: Security Best Practices
echo -e "${BLUE}🔒 Step 8: Security Best Practices${NC}"
echo -e "• ${GREEN}Rotate GitHub tokens${NC} regularly"
echo -e "• ${GREEN}Use least privilege${NC} IAM policies"
echo -e "• ${GREEN}Enable ECR image scanning${NC}"
echo -e "• ${GREEN}Monitor CloudTrail${NC} for API calls"
echo -e "• ${GREEN}Use AWS Secrets Manager${NC} for sensitive data"
echo ""

# Ready to deploy prompt
echo -e "${GREEN}✅ Ready to Deploy?${NC}"
echo -e "If you have your GitHub token ready, run:"
echo -e "${BLUE}./deploy-with-github.sh${NC}"
echo ""
echo -e "Or set the token as an environment variable first:"
echo -e "${BLUE}export GITHUB_TOKEN='your_token_here'${NC}"
echo -e "${BLUE}./deploy-with-github.sh${NC}"
echo ""
echo -e "${YELLOW}💡 The script will guide you through the entire process!${NC}"