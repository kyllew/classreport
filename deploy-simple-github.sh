#!/bin/bash

# Simple GitHub-Integrated CodeBuild Deployment
set -e

# Configuration - Edit these values for your setup
AWS_REGION="us-east-1"
CODEBUILD_STACK_NAME="classreport-codebuild"
APP_STACK_NAME="classreport-stack"
GITHUB_OWNER="kyllew"
GITHUB_REPO="classreport"
GITHUB_BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Simple GitHub-Integrated CI/CD Pipeline Setup${NC}"

# Check if GitHub token is provided
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}📝 GitHub Personal Access Token Required${NC}"
    echo -e "${BLUE}Please provide your GitHub Personal Access Token:${NC}"
    echo -e "1. Go to: https://github.com/settings/tokens"
    echo -e "2. Click 'Generate new token (classic)'"
    echo -e "3. Select scopes: repo, admin:repo_hook"
    echo -e "4. Copy the token and paste it here"
    echo -e ""
    read -s -p "GitHub Token: " GITHUB_TOKEN
    echo ""
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${RED}❌ GitHub token is required for webhook integration${NC}"
        exit 1
    fi
fi

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}✓ GitHub Owner: ${GITHUB_OWNER}${NC}"
echo -e "${GREEN}✓ GitHub Repo: ${GITHUB_REPO}${NC}"

# Step 1: Deploy CodePipeline Infrastructure
echo -e "${YELLOW}🏗️  Deploying CodePipeline infrastructure...${NC}"

aws cloudformation deploy \
  --template-file codepipeline-template.yaml \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --parameter-overrides \
    GitHubOwner=${GITHUB_OWNER} \
    GitHubRepo=${GITHUB_REPO} \
    GitHubBranch=${GITHUB_BRANCH} \
    GitHubToken=${GITHUB_TOKEN} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

echo -e "${GREEN}✓ CodePipeline infrastructure deployed${NC}"

# Get outputs
ECR_REPOSITORY_URI=$(aws cloudformation describe-stacks \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='ECRRepositoryURI'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

PIPELINE_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='PipelineName'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

echo -e "${GREEN}✓ ECR Repository: ${ECR_REPOSITORY_URI}${NC}"
echo -e "${GREEN}✓ Pipeline Name: ${PIPELINE_NAME}${NC}"

# Step 2: Check if application infrastructure exists, if not deploy it
echo -e "${YELLOW}🏗️  Checking application infrastructure...${NC}"

if aws cloudformation describe-stacks --stack-name ${APP_STACK_NAME} --region ${AWS_REGION} >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Application infrastructure already exists${NC}"
else
  echo -e "${YELLOW}🏗️  Deploying application infrastructure...${NC}"
  
  # Get VPC and subnet information
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text --region ${AWS_REGION})
  SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text --region ${AWS_REGION} | tr '\t' ',')
  
  # Update CloudFormation template with ECR URI
  sed "s|YOUR_ACCOUNT_ID|${AWS_ACCOUNT_ID}|g" cloudformation-template.yaml > cloudformation-template-updated.yaml
  
  aws cloudformation deploy \
    --template-file cloudformation-template-updated.yaml \
    --stack-name ${APP_STACK_NAME} \
    --parameter-overrides \
      VpcId=${VPC_ID} \
      SubnetIds=${SUBNET_IDS} \
      ImageUri=${ECR_REPOSITORY_URI}:latest \
    --capabilities CAPABILITY_NAMED_IAM \
    --region ${AWS_REGION}
  
  rm -f cloudformation-template-updated.yaml
  echo -e "${GREEN}✓ Application infrastructure deployed${NC}"
fi

# Step 3: Trigger initial pipeline run
echo -e "${YELLOW}🚀 Starting initial pipeline run...${NC}"

EXECUTION_ID=$(aws codepipeline start-pipeline-execution \
  --name ${PIPELINE_NAME} \
  --query "pipelineExecutionId" \
  --output text \
  --region ${AWS_REGION})

echo -e "${GREEN}✓ Pipeline execution started: ${EXECUTION_ID}${NC}"

# Get application URL
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name ${APP_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
  --output text \
  --region ${AWS_REGION} 2>/dev/null || echo "Will be available after first deployment")

echo -e "${GREEN}🎉 CI/CD Pipeline Setup Complete!${NC}"
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "Pipeline Stack: ${CODEBUILD_STACK_NAME}"
echo -e "Application Stack: ${APP_STACK_NAME}"
echo -e "ECR Repository: ${ECR_REPOSITORY_URI}"
echo -e "Pipeline Name: ${PIPELINE_NAME}"
echo -e "Application URL: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${YELLOW}🔄 CI/CD Features:${NC}"
echo -e "✅ Full CodePipeline (Source → Build → Deploy)"
echo -e "✅ GitHub webhook integration"
echo -e "✅ Automatic deployments on push to ${GITHUB_BRANCH}"
echo -e "✅ Docker image building and ECR storage"
echo -e "✅ Zero-downtime ECS deployments"
echo -e ""
echo -e "${BLUE}📊 Monitor your pipeline:${NC}"
echo -e "1. CodePipeline: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view"
echo -e "2. ECR Repository: https://console.aws.amazon.com/ecr/repositories/classreport"
echo -e "3. ECS Service: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/classreport-cluster/services"
echo -e "4. Application: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo -e "1. Push code changes to GitHub ${GITHUB_BRANCH} branch"
echo -e "2. Pipeline will automatically trigger"
echo -e "3. Monitor progress in CodePipeline console"
echo -e "4. Your beautiful app will be updated automatically!"
echo -e ""
echo -e "${YELLOW}💡 Pipeline is now running! Check the console for progress.${NC}"