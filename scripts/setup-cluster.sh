#!/bin/bash

set -e

echo "Setting up Kind cluster..."

# Create Kind cluster with config
kind create cluster --config=/home/ubuntu/kind-config.yaml --name=k8s-cluster

# Verify cluster
kubectl cluster-info
kubectl get nodes

echo "Kind cluster setup completed!"