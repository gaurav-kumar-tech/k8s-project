#!/bin/bash

set -e

echo "Starting K8s cluster provisioning with Kind..."

# Check if terraform.tfvars exists
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo "Please copy terraform/terraform.tfvars.example to terraform/terraform.tfvars and update values"
    exit 1
fi

# Provision infrastructure
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "Instance IP: $INSTANCE_IP"

# Wait for instance to be ready
echo "Waiting for instance to be ready..."
sleep 60

echo "Infrastructure provisioned successfully!"
echo "SSH to instance: $(terraform output -raw ssh_command)"
echo "Application will be available at: $(terraform output -raw ingress_url)"

cd ..
./scripts/deploy-apps.sh $INSTANCE_IP