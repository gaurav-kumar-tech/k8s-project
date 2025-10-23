#!/bin/bash

set -e

INSTANCE_IP=$1
NEW_IMAGE=${2:-nginx:1.22}

if [ -z "$INSTANCE_IP" ]; then
    echo "Usage: $0 <instance_ip> [new_image]"
    exit 1
fi

echo "Performing zero-downtime update to $NEW_IMAGE..."

ssh -i key-pair.pem ubuntu@$INSTANCE_IP << EOF
    # Update deployment with new image
    kubectl set image deployment/sample-app app=$NEW_IMAGE
    
    # Wait for rollout to complete
    kubectl rollout status deployment/sample-app
    
    # Verify deployment
    kubectl get pods -l app=sample-app
    
    echo "Zero-downtime update completed successfully!"
EOF