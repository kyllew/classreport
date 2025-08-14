#!/bin/bash

# Complete AWS Deployment Script using CloudFormation
set -e

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY="classreport"
STACK_NAME="classreport-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Complete AWS Deployment for Class Report Application${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Get default VPC and subnets
echo -e "${YELLOW}🔍 Getting VPC and subnet information...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text --region ${AWS_REGION})
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" --query "Subnets[*].SubnetId" --output text --region ${AWS_REGION} | tr '\t' ',')

echo -e "${GREEN}✓ VPC ID: ${VPC_ID}${NC}"
echo -e "${GREEN}✓ Subnet IDs: ${SUBNET_IDS}${NC}"

# Build and push Docker image
echo -e "${YELLOW}📦 Building and pushing Docker image...${NC}"

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${AWS_REGION} 2>/dev/null || \
aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${AWS_REGION}

# Build and tag image
docker build -t ${ECR_REPOSITORY}:latest .
docker tag ${ECR_REPOSITORY}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

# Login and push
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest"
echo -e "${GREEN}✓ Image pushed: ${IMAGE_URI}${NC}"

# Deploy CloudFormation stack
echo -e "${YELLOW}☁️  Deploying CloudFormation stack...${NC}"

# Update CloudFormation template with actual account ID
sed "s/YOUR_ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" cloudformation-template.yaml > cloudformation-template-updated.yaml

aws cloudformation deploy \
  --template-file cloudformation-template-updated.yaml \
  --stack-name ${STACK_NAME} \
  --parameter-overrides \
    VpcId=${VPC_ID} \
    SubnetIds=${SUBNET_IDS} \
    ImageUri=${IMAGE_URI} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

# Get stack outputs
echo -e "${YELLOW}📋 Getting deployment information...${NC}"
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
  --output text \
  --region ${AWS_REGION})

# Cleanup
rm -f cloudformation-template-updated.yaml

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "Stack Name: ${STACK_NAME}"
echo -e "Region: ${AWS_REGION}"
echo -e "Application URL: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${YELLOW}💡 Your Class Report Application is now available at:${NC}"
echo -e "${GREEN}${LOAD_BALANCER_URL}${NC}"
echo -e ""
echo -e "${BLUE}📊 To monitor your application:${NC}"
echo -e "1. CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups/log-group/%2Fecs%2Fclassreport"
echo -e "2. ECS Service: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/classreport-cluster/services"
echo -e "3. Load Balancer: https://console.aws.amazon.com/ec2/v2/home?region=${AWS_REGION}#LoadBalancers:"
echo -e ""
echo -e "${YELLOW}🔧 To update the application:${NC}"
echo -e "1. Make your code changes"
echo -e "2. Run this script again to deploy updates"