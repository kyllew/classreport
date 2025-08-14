#!/bin/bash

# AWS ECS Deployment Script for Class Report Application
set -e

# Configuration
AWS_REGION="us-east-1"
ECR_REPOSITORY="classreport"
ECS_CLUSTER="classreport-cluster"
ECS_SERVICE="classreport-service"
TASK_DEFINITION="classreport-task"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting deployment of Class Report Application to AWS ECS${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Build and tag Docker image
echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t ${ECR_REPOSITORY}:latest .
docker tag ${ECR_REPOSITORY}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

# Create ECR repository if it doesn't exist
echo -e "${YELLOW}🏗️  Creating ECR repository if needed...${NC}"
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY} --region ${AWS_REGION} 2>/dev/null || \
aws ecr create-repository --repository-name ${ECR_REPOSITORY} --region ${AWS_REGION}

# Login to ECR
echo -e "${YELLOW}🔐 Logging into ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Push image to ECR
echo -e "${YELLOW}⬆️  Pushing image to ECR...${NC}"
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest

# Create CloudWatch Log Group
echo -e "${YELLOW}📊 Creating CloudWatch log group...${NC}"
aws logs create-log-group --log-group-name /ecs/classreport --region ${AWS_REGION} 2>/dev/null || echo "Log group already exists"

# Update task definition with actual account ID
echo -e "${YELLOW}📝 Updating task definition...${NC}"
sed "s/YOUR_ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" task-definition.json > task-definition-updated.json

# Register task definition
echo -e "${YELLOW}📋 Registering task definition...${NC}"
aws ecs register-task-definition --cli-input-json file://task-definition-updated.json --region ${AWS_REGION}

# Create ECS cluster if it doesn't exist
echo -e "${YELLOW}🏗️  Creating ECS cluster if needed...${NC}"
aws ecs describe-clusters --clusters ${ECS_CLUSTER} --region ${AWS_REGION} 2>/dev/null || \
aws ecs create-cluster --cluster-name ${ECS_CLUSTER} --capacity-providers FARGATE --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 --region ${AWS_REGION}

echo -e "${GREEN}✅ Deployment preparation complete!${NC}"
echo -e "${BLUE}📋 Next steps:${NC}"
echo -e "1. Create IAM roles (ecsTaskExecutionRole and classreport-task-role)"
echo -e "2. Create ECS service with load balancer"
echo -e "3. Configure security groups and VPC"
echo -e ""
echo -e "${YELLOW}💡 Run the following commands to complete the deployment:${NC}"
echo -e "aws ecs create-service --cluster ${ECS_CLUSTER} --service-name ${ECS_SERVICE} --task-definition ${TASK_DEFINITION} --desired-count 1 --launch-type FARGATE --network-configuration 'awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}'"

# Cleanup
rm -f task-definition-updated.json

echo -e "${GREEN}🎉 Deployment script completed successfully!${NC}"