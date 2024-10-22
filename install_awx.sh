#!/bin/bash

# Stop on error
set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo."
  exit 1
fi

# Install required dependencies
echo "Installing necessary dependencies..."
apt-get update && apt-get install -y apt-transport-https ca-certificates curl git docker.io

# Enable Docker service
systemctl enable docker --now

# Install kubectl
echo "Installing kubectl..."
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

# Install kind (Kubernetes in Docker)
echo "Installing kind..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind

# Create a kind Kubernetes cluster
echo "Creating a kind Kubernetes cluster..."
kind create cluster --name awx-cluster

# Check if kubectl is configured correctly
kubectl cluster-info

# Create a namespace for AWX
kubectl create namespace awx

# Install AWX Operator using GitHub manifests
echo "Cloning AWX Operator repository..."
git clone https://github.com/ansible/awx-operator.git
cd awx-operator

# Switch to a specific stable release (replace with the latest version if needed)
git checkout tags/2.3.0

# Deploy AWX Operator to the cluster
echo "Deploying AWX Operator to Kubernetes cluster..."
kubectl apply -f deploy/namespace.yaml
kubectl apply -f deploy/crds/awx.ansible.com_awxs_crd.yaml
kubectl apply -f deploy/operator.yaml

# Wait for the AWX Operator to be ready
echo "Waiting for the AWX Operator to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/awx-operator-controller-manager -n awx

# Create an AWX instance
echo "Creating an AWX instance..."
cat <<EOF | kubectl apply -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: nodeport
EOF

# Wait for the AWX instance to be ready
echo "Waiting for the AWX instance to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/awx -n awx

# Display the AWX service details
echo "AWX installation completed. Here are the details:"
kubectl get svc -n awx

# Output the AWX credentials
echo "AWX admin credentials:"
kubectl get secret awx-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode
echo ""
