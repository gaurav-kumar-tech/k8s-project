# Kubernetes Project - Kind Cluster with NGINX Ingress

This project demonstrates a highly available and scalable Kubernetes application deployment using Kind cluster on AWS EC2, fully automated with Terraform.

## Features

- **Kind Kubernetes Cluster** - Multi-node cluster (1 control-plane + 2 workers) on AWS EC2
- **NGINX Ingress Controller** - HTTP/HTTPS traffic routing
- **High Availability** - 3 replica application with health checks and rolling updates
- **Zero-Downtime Updates** - Rolling deployment strategy
- **Stateful Database** - PostgreSQL with persistent storage
- **Infrastructure as Code** - Complete Terraform automation with SSH provisioning

## Prerequisites

- AWS Account with programmatic access
- Terraform >= 1.0
- SSH Key Pair in AWS (jenkins-key)

## Project Structure

```
k8s-project/
├── README.md
├── key-pair.pem                 # SSH private key
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # Main Terraform configuration
│   ├── variables.tf             # Variable definitions
│   ├── providers.tf             # Provider configuration
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars         # Variable values
├── scripts/                     # Automation scripts
│   ├── install-tools.sh         # Install Docker, Kind, kubectl, Helm
│   ├── setup-cluster.sh         # Create Kind cluster
│   ├── provision.sh             # Main provisioning script
│   ├── deploy-apps.sh           # Deploy applications
│   └── update-app.sh            # Zero-downtime updates
├── config/                      # Configuration files
│   └── kind-config.yaml         # Kind cluster configuration
├── k8s/                         # Kubernetes manifests
│   ├── app-deployment.yaml      # Sample application
│   ├── app-service.yaml         # Service definition
│   ├── app-ingress.yaml         # Ingress configuration
│   └── postgres-deployment.yaml # PostgreSQL StatefulSet
└── helm/                        # Helm charts
    ├── nginx-ingress/values.yaml
    └── sample-app/values.yaml
```

## Quick Start

### 1. Configure AWS Credentials

**Option A: Environment Variables (Recommended)**
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"


**Option B: Update terraform.tfvars**

# Edit terraform/terraform.tfvars with your AWS credentials


### 2. Deploy Infrastructure

cd terraform
terraform init
terraform plan
terraform apply -auto-approve


### 3. Get Instance IP and Deploy Applications

# Get instance IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "Instance IP: $INSTANCE_IP"

# Deploy applications
cd ..
./scripts/deploy-apps.sh $INSTANCE_IP

### 4. Access Application

# Application URL
echo "Application URL: http://$INSTANCE_IP"

# Test with curl
curl -H "Host: sample-app.local" http://$INSTANCE_IP

## Manual Deployment Steps

### Step 1: Infrastructure Provisioning

cd terraform
terraform init
terraform apply -auto-approve


### Step 2: SSH to Instance and Verify Cluster

# SSH to instance
ssh -i ../key-pair.pem ubuntu@<INSTANCE_IP>

# Check cluster status
kubectl get nodes
kubectl get pods -A


### Step 3: Deploy Applications Manually

# Deploy NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Deploy sample application
kubectl apply -f k8s/

# Deploy PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgresql bitnami/postgresql \
  --set auth.postgresPassword=postgres123 \
  --set primary.persistence.size=1Gi


## Verification Commands

### Check Cluster Status

kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl cluster-info


### Check Services and Ingress
kubectl get services -A
kubectl get ingress -A
kubectl get endpoints -A
```

### Test Application Access

curl -H "Host: sample-app.local" http://<INSTANCE_IP>

### Check Application Health
kubectl get deployment sample-app
kubectl rollout status deployment/sample-app
kubectl get pods -l app=sample-app


## Zero-Downtime Updates

# Update application image
./scripts/update-app.sh <INSTANCE_IP> nginx:1.22

# Monitor rollout
kubectl rollout status deployment/sample-app
kubectl get pods -l app=sample-app

## Database Access

# Get PostgreSQL password
kubectl get secret postgresql -o jsonpath="{.data.postgres-password}" | base64 -d

# Port forward to access database
kubectl port-forward svc/postgresql 5432:5432

# Connect to database
psql -h localhost -U postgres -d sampledb

## Expected Outputs

### Cluster Nodes

$ kubectl get nodes
NAME                          STATUS   ROLES           AGE   VERSION
k8s-cluster-control-plane     Ready    control-plane   5m    v1.28.0
k8s-cluster-worker            Ready    <none>          4m    v1.28.0
k8s-cluster-worker2           Ready    <none>          4m    v1.28.0
```

### Application Pods
$ kubectl get pods -l app=sample-app
NAME                          READY   STATUS    RESTARTS   AGE
sample-app-7d4b8c8f9d-2xk8m   1/1     Running   0          2m
sample-app-7d4b8c8f9d-5h9j2   1/1     Running   0          2m
sample-app-7d4b8c8f9d-8k3l5   1/1     Running   0          2m
```

### Services
$ kubectl get services
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes           ClusterIP   10.96.0.1       <none>        443/TCP   6m
postgresql           ClusterIP   None            <none>        5432/TCP  3m
sample-app-service   ClusterIP   10.96.123.45    <none>        80/TCP    2m


### Ingress
$ kubectl get ingress
NAME                 CLASS   HOSTS              ADDRESS   PORTS   AGE
sample-app-ingress   nginx   sample-app.local             80      2m

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   chmod 600 key-pair.pem
   

2. **Terraform Apply Failed**
   # Check AWS credentials
   aws sts get-caller-identity

3. **Kind Cluster Not Starting**
   # SSH to instance and check Docker
   sudo systemctl status docker

4. **Ingress Not Working**
   # Check ingress controller
   kubectl get pods -n ingress-nginx

### View Logs
# Application logs
kubectl logs -l app=sample-app

# Ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# System events
kubectl get events --sort-by=.metadata.creationTimestamp

## Cleanup

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve

## Key Files Explained

### Terraform Configuration
- **main.tf**: Creates EC2 instance, security group, and provisions Kind cluster
- **variables.tf**: Defines input variables for AWS credentials and configuration
- **outputs.tf**: Outputs instance IP and connection details

### Kubernetes Manifests
- **app-deployment.yaml**: 3-replica nginx deployment with rolling update strategy, resource limits, and health checks
- **app-service.yaml**: ClusterIP service for load balancing
- **app-ingress.yaml**: Ingress resource for external access
- **postgres-deployment.yaml**: StatefulSet with persistent storage

### Scripts
- **install-tools.sh**: Installs Docker, Kind, kubectl, and Helm
- **setup-cluster.sh**: Creates Kind cluster with configuration
- **deploy-apps.sh**: Deploys NGINX Ingress, sample app, and PostgreSQL
- **update-app.sh**: Performs zero-downtime rolling updates

<<<<<<< HEAD
This project demonstrates all required Kubernetes concepts: cluster setup, ingress controller, high availability, zero-downtime updates, and stateful database deployment.
=======
This project demonstrates all required Kubernetes concepts: cluster setup, ingress controller, high availability, zero-downtime updates, and stateful database deployment.
>>>>>>> 5d11998 (Initial commit)
