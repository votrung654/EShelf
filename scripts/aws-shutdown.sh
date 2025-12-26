#!/bin/bash

# AWS Resource Shutdown Script
# Stops EC2 instances to avoid charges when not in use

set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}

echo "Shutting down AWS resources for environment: $ENVIRONMENT"

# Get instance IDs from Terraform state
if [ -f "infrastructure/terraform/environments/$ENVIRONMENT/terraform.tfstate" ]; then
    INSTANCE_IDS=$(terraform -chdir=infrastructure/terraform/environments/$ENVIRONMENT output -json | \
        jq -r '.k3s_master_instance_id.value, .k3s_worker_instance_ids.value[]?, .bastion_instance_id.value' | \
        grep -v null)
    
    if [ -n "$INSTANCE_IDS" ]; then
        echo "Stopping instances: $INSTANCE_IDS"
        aws ec2 stop-instances --instance-ids $INSTANCE_IDS --region $AWS_REGION
        echo "Instances stopped successfully"
    else
        echo "No instances found to stop"
    fi
else
    echo "Terraform state file not found. Please run terraform apply first."
    exit 1
fi

