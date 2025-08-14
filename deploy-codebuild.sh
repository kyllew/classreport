#!/bin/bash

# AWS CodeBuild CI/CD Pipeline Deployment Script
set -e

# Configuration
AWS_REGION="us-east-1"
CODEBUILD_STACK_NAME="classreport-codebuild"
APP_STACK_NAME="classreport-stack"
GITHUB_REPO_URL="https://github.com/kyllew/classreport.git"
GITHUB_BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up CodeBuild CI/CD Pipeline for Class Report Application${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Step 1: Deploy CodeBuild Infrastructure
echo -e "${YELLOW}🏗️  Deploying CodeBuild infrastructure...${NC}"

aws cloudformation deploy \
  --template-file codebuild-template.yaml \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --parameter-overrides \
    GitHubRepoUrl=${GITHUB_REPO_URL} \
    GitHubBranch=${GITHUB_BRANCH} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

echo -e "${GREEN}✓ CodeBuild infrastructure deployed${NC}"

# Get CodeBuild outputs
ECR_REPOSITORY_URI=$(aws cloudformation describe-stacks \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='ECRRepositoryURI'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

CODEBUILD_PROJECT_NAME=$(aws cloudformation describe-stacks \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='CodeBuildProjectName'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

echo -e "${GREEN}✓ ECR Repository: ${ECR_REPOSITORY_URI}${NC}"
echo -e "${GREEN}✓ CodeBuild Project: ${CODEBUILD_PROJECT_NAME}${NC}"

# Step 2: Initial Build (Optional - trigger first build)
echo -e "${YELLOW}🔨 Starting initial build...${NC}"

BUILD_ID=$(aws codebuild start-build \
  --project-name ${CODEBUILD_PROJECT_NAME} \
  --query "build.id" \
  --output text \
  --region ${AWS_REGION})

echo -e "${GREEN}✓ Build started with ID: ${BUILD_ID}${NC}"

# Step 3: Wait for build to complete (optional)
echo -e "${YELLOW}⏳ Waiting for build to complete...${NC}"
echo -e "${BLUE}You can monitor the build at: https://console.aws.amazon.com/codesuite/codebuild/projects/${CODEBUILD_PROJECT_NAME}/build/${BUILD_ID}${NC}"

# Poll build status
while true; do
  BUILD_STATUS=$(aws codebuild batch-get-builds \
    --ids ${BUILD_ID} \
    --query "builds[0].buildStatus" \
    --output text \
    --region ${AWS_REGION})
  
  case ${BUILD_STATUS} in
    "SUCCEEDED")
      echo -e "${GREEN}✅ Build completed successfully!${NC}"
      break
      ;;
    "FAILED"|"FAULT"|"STOPPED"|"TIMED_OUT")
      echo -e "${RED}❌ Build failed with status: ${BUILD_STATUS}${NC}"
      echo -e "${YELLOW}Check the build logs at: https://console.aws.amazon.com/codesuite/codebuild/projects/${CODEBUILD_PROJECT_NAME}/build/${BUILD_ID}${NC}"
      exit 1
      ;;
    "IN_PROGRESS")
      echo -e "${YELLOW}⏳ Build in progress...${NC}"
      sleep 30
      ;;
    *)
      echo -e "${YELLOW}⏳ Build status: ${BUILD_STATUS}${NC}"
      sleep 30
      ;;
  esac
done

# Step 4: Check if application infrastructure exists, if not deploy it
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

# Get application URL
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name ${APP_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
  --output text \
  --region ${AWS_REGION} 2>/dev/null || echo "Not deployed yet")

echo -e "${GREEN}🎉 CodeBuild CI/CD Pipeline Setup Complete!${NC}"
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "CodeBuild Stack: ${CODEBUILD_STACK_NAME}"
echo -e "Application Stack: ${APP_STACK_NAME}"
echo -e "ECR Repository: ${ECR_REPOSITORY_URI}"
echo -e "CodeBuild Project: ${CODEBUILD_PROJECT_NAME}"
echo -e "Application URL: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${YELLOW}🔄 CI/CD Pipeline Features:${NC}"
echo -e "✅ Automatic builds on GitHub push to ${GITHUB_BRANCH}"
echo -e "✅ Docker image building and pushing to ECR"
echo -e "✅ Automatic ECS service updates"
echo -e "✅ Build logs in CloudWatch"
echo -e "✅ Image vulnerability scanning"
echo -e ""
echo -e "${BLUE}📊 Monitor your pipeline:${NC}"
echo -e "1. CodeBuild Console: https://console.aws.amazon.com/codesuite/codebuild/projects/${CODEBUILD_PROJECT_NAME}"
echo -e "2. ECR Repository: https://console.aws.amazon.com/ecr/repositories/classreport"
echo -e "3. ECS Service: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/classreport-cluster/services"
echo -e "4. Application: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo -e "1. Push code changes to GitHub ${GITHUB_BRANCH} branch"
echo -e "2. CodeBuild will automatically build and deploy"
echo -e "3. Monitor builds in AWS Console"
echo -e "4. Your app will be updated automatically!"