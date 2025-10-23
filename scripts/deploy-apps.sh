#!/bin/bash

set -e

INSTANCE_IP=$1

if [ -z "$INSTANCE_IP" ]; then
    echo "Usage: $0 <instance_ip>"
    exit 1
fi

echo "Deploying applications to Kind cluster..."

# Copy manifests to remote instance
scp -i key-pair.pem -r k8s/ ubuntu@$INSTANCE_IP:/home/ubuntu/
scp -i key-pair.pem -r helm/ ubuntu@$INSTANCE_IP:/home/ubuntu/

# Deploy NGINX Ingress Controller
ssh -i key-pair.pem ubuntu@$INSTANCE_IP << 'EOF'
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress controller to be ready
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
EOF

# Deploy PostgreSQL
ssh -i key-pair.pem ubuntu@$INSTANCE_IP << 'EOF'
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    helm install postgresql bitnami/postgresql \
        --set auth.postgresPassword=postgres123 \
        --set primary.persistence.size=1Gi
EOF

# Deploy sample application
ssh -i key-pair.pem ubuntu@$INSTANCE_IP << 'EOF'
    kubectl apply -f k8s/
    
    # Wait for deployment to be ready
    kubectl rollout status deployment/sample-app
    
    echo "Deployment completed!"
    echo "Checking cluster status..."
    kubectl get nodes
    kubectl get pods -A
    kubectl get services -A
    kubectl get ingress -A
EOF

echo "Applications deployed successfully!"
echo "Access the application at: http://$INSTANCE_IP"