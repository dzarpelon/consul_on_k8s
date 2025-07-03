#!/bin/bash

# Consul Cleanup Script
# This script removes the Consul deployment and cleans up resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

main() {
    local auto_approve=false
    local auto_hosts=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto|--yes|-y)
                auto_approve=true
                shift
                ;;
            --auto-hosts)
                auto_hosts=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --auto, --yes, -y    Skip confirmation prompts"
                echo "  --auto-hosts         Automatically remove /etc/hosts entries"
                echo "  --help, -h           Show this help message"
                echo ""
                echo "This script completely removes the Consul deployment and all associated resources."
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    print_status "Consul Cleanup Script"
    echo
    
    print_warning "This will completely remove the Consul deployment and all associated resources!"
    print_info "This includes:"
    echo "  • All Consul pods and services"
    echo "  • Persistent volumes and data"
    echo "  • ACL tokens and secrets"
    echo "  • Custom resources and configurations"
    echo "  • Ingresses (including prometheus-ingress)"
    echo "  • Consul namespace (if empty)"
    echo "  • /etc/hosts entries (optional)"
    echo
    
    if [ "$auto_approve" = false ]; then
        read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Cleanup aborted"
            exit 0
        fi
    else
        print_info "Auto-approve mode: proceeding with cleanup..."
    fi
    
    # Check if Consul is installed
    if ! kubectl get namespace consul >/dev/null 2>&1; then
        print_warning "Consul namespace not found - nothing to clean up"
        exit 0
    fi
    
    # Uninstall Consul using consul-k8s
    print_status "Uninstalling Consul deployment..."
    if command -v consul-k8s >/dev/null 2>&1; then
        consul-k8s uninstall --auto-approve
        print_success "Consul uninstalled successfully"
    else
        print_warning "consul-k8s CLI not found, using kubectl to clean up..."
        kubectl delete namespace consul --ignore-not-found=true
        print_success "Consul namespace deleted"
    fi
    
    # Clean up PVCs (consul-k8s preserves these by default)
    print_status "Cleaning up persistent volume claims..."
    kubectl delete pvc -n consul -l app=consul --ignore-not-found=true 2>/dev/null || true
    kubectl delete pvc -n consul --all --ignore-not-found=true 2>/dev/null || true
    
    # Clean up separate ingresses (like prometheus-ingress.yaml)
    print_status "Cleaning up ingresses..."
    kubectl delete ingress -n consul prometheus-ingress --ignore-not-found=true 2>/dev/null || true
    kubectl delete ingress -n consul --all --ignore-not-found=true 2>/dev/null || true
    
    # Clean up any remaining resources
    print_status "Cleaning up remaining resources..."
    
    # Remove any finalizers that might prevent cleanup
    kubectl patch crd -p '{"metadata":{"finalizers":[]}}' --type=merge \
        controlplanerequestlimits.consul.hashicorp.com \
        exportedservices.consul.hashicorp.com \
        gatewayclassconfigs.consul.hashicorp.com \
        gatewaypolicies.consul.hashicorp.com \
        ingressgateways.consul.hashicorp.com \
        jwtproviders.consul.hashicorp.com \
        meshes.consul.hashicorp.com \
        meshservices.consul.hashicorp.com \
        proxydefaults.consul.hashicorp.com \
        registrations.consul.hashicorp.com \
        routeauthfilters.consul.hashicorp.com \
        routeretryfilters.consul.hashicorp.com \
        routetimeoutfilters.consul.hashicorp.com \
        samenessgroups.consul.hashicorp.com \
        servicedefaults.consul.hashicorp.com \
        serviceintentions.consul.hashicorp.com \
        serviceresolvers.consul.hashicorp.com \
        servicerouters.consul.hashicorp.com \
        servicesplitters.consul.hashicorp.com \
        terminatinggateways.consul.hashicorp.com \
        trafficpermissions.auth.consul.hashicorp.com 2>/dev/null || true
    
    # Remove Consul CRDs
    kubectl delete crd -l app.kubernetes.io/name=consul 2>/dev/null || true
    
    # Remove any remaining PVs
    kubectl delete pv -l app=consul 2>/dev/null || true
    
    # Clean up cluster roles and bindings
    kubectl delete clusterrole -l app.kubernetes.io/name=consul 2>/dev/null || true
    kubectl delete clusterrolebinding -l app.kubernetes.io/name=consul 2>/dev/null || true
    
    # Clean up webhook configurations
    kubectl delete mutatingwebhookconfiguration consul-connect-injector 2>/dev/null || true
    kubectl delete validatingwebhookconfiguration consul-connect-injector 2>/dev/null || true
    
    print_success "Resource cleanup completed"
    
    # Clean up empty namespace if it still exists
    print_status "Cleaning up namespace..."
    if kubectl get namespace consul >/dev/null 2>&1; then
        # Check if namespace is empty
        resources=$(kubectl get all -n consul --no-headers 2>/dev/null | wc -l)
        if [ "$resources" -eq 0 ]; then
            kubectl delete namespace consul --ignore-not-found=true
            print_success "Empty consul namespace removed"
        else
            print_warning "Consul namespace still contains resources, skipping deletion"
        fi
    fi
    echo
    
    # Optional: Clean up /etc/hosts entries
    if [ "$auto_hosts" = true ]; then
        print_status "Removing /etc/hosts entries (auto mode)..."
        sudo sed -i.bak '/consul\.local/d; /prometheus\.local/d' /etc/hosts 2>/dev/null || true
        print_success "/etc/hosts entries removed"
    else
        read -p "Do you want to remove consul.local and prometheus.local from /etc/hosts? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Removing /etc/hosts entries..."
            sudo sed -i.bak '/consul\.local/d; /prometheus\.local/d' /etc/hosts 2>/dev/null || true
            print_success "/etc/hosts entries removed"
        fi
    fi
    
    echo
    print_success "Consul cleanup completed successfully!"
    print_info "All Consul resources have been removed from the cluster"
}

main "$@"
