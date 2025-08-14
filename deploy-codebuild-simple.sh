#!/bin/bash

# Simple CodeBuild Deployment (No Pipeline Complexity)
set -e

# Configuration
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

echo -e "${BLUE}🚀 Simple CodeBuild CI/CD Setup${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Step 1: Deploy Simple CodeBuild Infrastructure
echo -e "${YELLOW}🏗️  Deploying CodeBuild infrastructure...${NC}"

aws cloudformation deploy \
  --template-file codebuild-simple.yaml \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --parameter-overrides \
    GitHubOwner=${GITHUB_OWNER} \
    GitHubRepo=${GITHUB_REPO} \
    GitHubBranch=${GITHUB_BRANCH} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

echo -e "${GREEN}✓ CodeBuild infrastructure deployed${NC}"

# Get outputs
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

# Step 2: Trigger initial build
echo -e "${YELLOW}🔨 Starting initial build...${NC}"

BUILD_ID=$(aws codebuild start-build \
  --project-name ${CODEBUILD_PROJECT_NAME} \
  --query "build.id" \
  --output text \
  --region ${AWS_REGION})

echo -e "${GREEN}✓ Build started: ${BUILD_ID}${NC}"
echo -e "${BLUE}Monitor at: https://console.aws.amazon.com/codesuite/codebuild/projects/${CODEBUILD_PROJECT_NAME}/build/${BUILD_ID}${NC}"

# Step 3: Check if application infrastructure exists, if not deploy it
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

# Wait for build to complete
echo -e "${YELLOW}⏳ Waiting for initial build to complete...${NC}"

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
      echo -e "${YELLOW}Check logs: https://console.aws.amazon.com/codesuite/codebuild/projects/${CODEBUILD_PROJECT_NAME}/build/${BUILD_ID}${NC}"
      break
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

# Get application URL
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name ${APP_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
  --output text \
  --region ${AWS_REGION} 2>/dev/null || echo "Will be available after ECS deployment")

echo -e "${GREEN}🎉 Simple CodeBuild Setup Complete!${NC}"
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "CodeBuild Stack: ${CODEBUILD_STACK_NAME}"
echo -e "Application Stack: ${APP_STACK_NAME}"
echo -e "ECR Repository: ${ECR_REPOSITORY_URI}"
echo -e "CodeBuild Project: ${CODEBUILD_PROJECT_NAME}"
echo -e "Application URL: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${YELLOW}🔄 How to Deploy Updates:${NC}"
echo -e "1. Push code changes to GitHub"
echo -e "2. Manually trigger build:"
echo -e "   ${GREEN}aws codebuild start-build --project-name ${CODEBUILD_PROJECT_NAME}${NC}"
echo -e "3. Or use the AWS Console to trigger builds"
echo -e ""
echo -e "${BLUE}📊 Monitor your deployment:${NC}"
echo -e "1. CodeBuild: https://console.aws.amazon.com/codesuite/codebuild/projects/${CODEBUILD_PROJECT_NAME}"
echo -e "2. ECR: https://console.aws.amazon.com/ecr/repositories/classreport"
echo -e "3. ECS: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/classreport-cluster/services"
echo -e "4. Application: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${GREEN}✅ Your beautiful Class Report app is now deployed with CI/CD!${NC}"