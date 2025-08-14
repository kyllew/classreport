#!/bin/bash

# Enhanced AWS CodeBuild CI/CD Pipeline with GitHub Integration
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

echo -e "${BLUE}🚀 Enhanced CodeBuild CI/CD Pipeline with GitHub Integration${NC}"

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

# Extract GitHub owner and repo from URL
GITHUB_OWNER=$(echo $GITHUB_REPO_URL | sed 's/.*github\.com\/\([^/]*\)\/.*/\1/')
GITHUB_REPO=$(echo $GITHUB_REPO_URL | sed 's/.*github\.com\/[^/]*\/\([^/]*\)\.git/\1/' | sed 's/\.git$//')

echo -e "${GREEN}✓ GitHub Owner: ${GITHUB_OWNER}${NC}"
echo -e "${GREEN}✓ GitHub Repo: ${GITHUB_REPO}${NC}"

# Step 1: Deploy Enhanced CodeBuild Infrastructure with GitHub Integration
echo -e "${YELLOW}🏗️  Deploying enhanced CodeBuild infrastructure...${NC}"

# Create parameter file for GitHub token (secure)
cat > /tmp/codebuild-params.json << EOF
[
  {
    "ParameterKey": "GitHubOwner",
    "ParameterValue": "${GITHUB_OWNER}"
  },
  {
    "ParameterKey": "GitHubRepo",
    "ParameterValue": "${GITHUB_REPO}"
  },
  {
    "ParameterKey": "GitHubBranch",
    "ParameterValue": "${GITHUB_BRANCH}"
  },
  {
    "ParameterKey": "GitHubToken",
    "ParameterValue": "${GITHUB_TOKEN}"
  }
]
EOF

# Deploy using the full CodePipeline template for better GitHub integration
aws cloudformation deploy \
  --template-file codepipeline-template.yaml \
  --stack-name ${CODEBUILD_STACK_NAME} \
  --parameter-overrides file:///tmp/codebuild-params.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${AWS_REGION}

# Clean up parameter file
rm -f /tmp/codebuild-params.json

echo -e "${GREEN}✓ Enhanced CodeBuild infrastructure deployed${NC}"

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

# Step 4: Monitor pipeline execution
echo -e "${YELLOW}⏳ Monitoring pipeline execution...${NC}"
echo -e "${BLUE}You can also monitor at: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view${NC}"

# Poll pipeline status
TIMEOUT=1800  # 30 minutes timeout
ELAPSED=0
POLL_INTERVAL=30

while [ $ELAPSED -lt $TIMEOUT ]; do
  PIPELINE_STATUS=$(aws codepipeline get-pipeline-execution \
    --pipeline-name ${PIPELINE_NAME} \
    --pipeline-execution-id ${EXECUTION_ID} \
    --query "pipelineExecution.status" \
    --output text \
    --region ${AWS_REGION})
  
  case ${PIPELINE_STATUS} in
    "Succeeded")
      echo -e "${GREEN}✅ Pipeline completed successfully!${NC}"
      break
      ;;
    "Failed"|"Cancelled"|"Superseded")
      echo -e "${RED}❌ Pipeline failed with status: ${PIPELINE_STATUS}${NC}"
      echo -e "${YELLOW}Check the pipeline details at: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view${NC}"
      exit 1
      ;;
    "InProgress")
      echo -e "${YELLOW}⏳ Pipeline in progress... (${ELAPSED}s elapsed)${NC}"
      sleep $POLL_INTERVAL
      ELAPSED=$((ELAPSED + POLL_INTERVAL))
      ;;
    *)
      echo -e "${YELLOW}⏳ Pipeline status: ${PIPELINE_STATUS} (${ELAPSED}s elapsed)${NC}"
      sleep $POLL_INTERVAL
      ELAPSED=$((ELAPSED + POLL_INTERVAL))
      ;;
  esac
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo -e "${YELLOW}⚠️  Pipeline monitoring timed out after 30 minutes${NC}"
  echo -e "${BLUE}Check the pipeline status manually at: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view${NC}"
fi

# Get application URL
LOAD_BALANCER_URL=$(aws cloudformation describe-stacks \
  --stack-name ${APP_STACK_NAME} \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" \
  --output text \
  --region ${AWS_REGION} 2>/dev/null || echo "Not deployed yet")

echo -e "${GREEN}🎉 Enhanced CI/CD Pipeline Setup Complete!${NC}"
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "Pipeline Stack: ${CODEBUILD_STACK_NAME}"
echo -e "Application Stack: ${APP_STACK_NAME}"
echo -e "ECR Repository: ${ECR_REPOSITORY_URI}"
echo -e "Pipeline Name: ${PIPELINE_NAME}"
echo -e "Application URL: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${YELLOW}🔄 Enhanced CI/CD Features:${NC}"
echo -e "✅ Full CodePipeline with Source → Build → Deploy stages"
echo -e "✅ GitHub webhook integration (automatic triggers)"
echo -e "✅ Pipeline visualization and monitoring"
echo -e "✅ Rollback capabilities"
echo -e "✅ Build artifacts management"
echo -e "✅ Multi-stage deployment ready"
echo -e ""
echo -e "${BLUE}📊 Monitor your pipeline:${NC}"
echo -e "1. CodePipeline Console: https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE_NAME}/view"
echo -e "2. ECR Repository: https://console.aws.amazon.com/ecr/repositories/classreport"
echo -e "3. ECS Service: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/classreport-cluster/services"
echo -e "4. Application: ${LOAD_BALANCER_URL}"
echo -e ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo -e "1. Push code changes to GitHub ${GITHUB_BRANCH} branch"
echo -e "2. Pipeline will automatically trigger via webhook"
echo -e "3. Monitor progress in CodePipeline console"
echo -e "4. Your app will be updated automatically!"
echo -e ""
echo -e "${YELLOW}💡 Pro Tips:${NC}"
echo -e "• Create pull requests to test changes before merging"
echo -e "• Use different branches for different environments"
echo -e "• Monitor CloudWatch logs for application insights"
echo -e "• Set up notifications for pipeline status changes"