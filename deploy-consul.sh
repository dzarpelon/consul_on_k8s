#!/bin/bash

# Consul on Kubernetes Deployment Script
# This script deploys a production-like Consul cluster with ACLs, service mesh, and monitoring

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}==> ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ ${1}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local selector=$2
    local timeout=${3:-300}
    
    print_status "Waiting for pods to be ready (timeout: ${timeout}s)..."
    kubectl wait --for=condition=ready pod -l "$selector" -n "$namespace" --timeout="${timeout}s"
}

# Function to get bootstrap token with retry
get_bootstrap_token() {
    local max_attempts=30
    local attempt=1
    
    print_status "Retrieving bootstrap ACL token..."
    
    while [ $attempt -le $max_attempts ]; do
        if kubectl get secret consul-bootstrap-acl-token -n consul >/dev/null 2>&1; then
            token=$(kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d)
            if [ ! -z "$token" ]; then
                echo "$token"
                return 0
            fi
        fi
        
        print_info "Attempt $attempt/$max_attempts: Waiting for bootstrap token to be generated..."
        sleep 10
        ((attempt++))
    done
    
    print_error "Failed to retrieve bootstrap token after $max_attempts attempts"
    return 1
}

# Main deployment function
main() {
    print_status "Starting Consul on Kubernetes deployment"
    echo
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists kubectl; then
        print_error "kubectl is required but not installed"
        exit 1
    fi
    
    if ! command_exists consul-k8s; then
        print_error "consul-k8s CLI is required but not installed"
        print_info "Install with: brew install hashicorp/tap/consul-k8s"
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "All prerequisites met"
    echo
    
    # Check if Consul is already installed
    print_status "Checking for existing Consul installation..."
    if kubectl get namespace consul >/dev/null 2>&1; then
        print_warning "Consul namespace already exists"
        read -p "Do you want to uninstall the existing deployment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Uninstalling existing Consul deployment..."
            consul-k8s uninstall --auto-approve
            print_success "Existing deployment uninstalled"
        else
            print_error "Deployment aborted"
            exit 1
        fi
    fi
    echo
    
    # Check if values.yaml exists
    if [ ! -f "values.yaml" ]; then
        print_error "values.yaml file not found in current directory"
        exit 1
    fi
    
    # Install Consul
    print_status "Installing Consul cluster..."
    consul-k8s install -config-file=values.yaml
    print_success "Consul installation completed"
    echo
    
    # Wait for pods to be ready
    print_status "Waiting for Consul pods to be ready..."
    wait_for_pods "consul" "app=consul" 300
    print_success "Consul pods are ready"
    echo
    
    # Apply Prometheus ingress if file exists
    if [ -f "prometheus-ingress.yaml" ]; then
        print_status "Applying Prometheus ingress..."
        kubectl apply -f prometheus-ingress.yaml
        print_success "Prometheus ingress applied"
    else
        print_warning "prometheus-ingress.yaml not found, skipping Prometheus ingress setup"
    fi
    echo
    
    # Get cluster status
    print_status "Checking cluster status..."
    
    # Get pod distribution
    echo "Pod Distribution:"
    kubectl get pods -n consul -o wide | grep consul-server
    echo
    
    # Check cluster leader
    leader=$(curl -s http://consul.local/v1/status/leader 2>/dev/null || echo "unavailable")
    print_info "Cluster Leader: $leader"
    
    # Check cluster members
    peers=$(curl -s http://consul.local/v1/status/peers 2>/dev/null || echo "unavailable")
    print_info "Cluster Members: $peers"
    echo
    
    # Get bootstrap token
    print_status "Retrieving bootstrap ACL token..."
    if token=$(get_bootstrap_token); then
        print_success "Bootstrap token retrieved successfully"
        echo
        echo "=================================================="
        echo "🎉 CONSUL DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉"
        echo "=================================================="
        echo
        echo "📋 ACCESS INFORMATION:"
        echo "  • Consul UI: http://consul.local"
        echo "  • Prometheus: http://prometheus.local"
        echo
        echo "🔑 BOOTSTRAP TOKEN:"
        echo "  $token"
        echo
        echo "🚀 LOGIN INSTRUCTIONS:"
        echo "  1. Navigate to http://consul.local"
        echo "  2. Click 'Log in with ACLs'"
        echo "  3. Paste the bootstrap token above"
        echo "  4. Click 'Login'"
        echo
        echo "📊 CLUSTER STATUS:"
        echo "  • 3-node high availability cluster"
        echo "  • ACLs enabled for security"
        echo "  • Service mesh (Consul Connect) enabled"
        echo "  • Prometheus monitoring enabled"
        echo "  • Ingress configured for UI access"
        echo
        echo "⚠️  IMPORTANT NOTES:"
        echo "  • Save the bootstrap token securely"
        echo "  • Ensure /etc/hosts contains:"
        echo "    127.0.0.1 consul.local"
        echo "    127.0.0.1 prometheus.local"
        echo
        print_success "Deployment completed successfully!"
    else
        print_error "Failed to retrieve bootstrap token"
        print_info "You can manually retrieve it later with:"
        print_info "kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d"
        exit 1
    fi
}

# Run main function
main "$@"
