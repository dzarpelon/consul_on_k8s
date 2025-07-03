#!/bin/bash

# Setup /etc/hosts entries for Consul and Prometheus local access
# This script adds the necessary hostname mappings for ingress access

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

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    HOSTS_FILE="/etc/hosts"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    HOSTS_FILE="/etc/hosts"
else
    print_error "Unsupported operating system"
    exit 1
fi

print_status "Setting up /etc/hosts entries for Consul local access"
echo

# Check if entries already exist
if grep -q "consul.local" "$HOSTS_FILE" && grep -q "prometheus.local" "$HOSTS_FILE"; then
    print_warning "Entries already exist in $HOSTS_FILE"
    print_status "Current entries:"
    grep -E "(consul\.local|prometheus\.local)" "$HOSTS_FILE"
    echo
    read -p "Do you want to update the entries? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping /etc/hosts update"
        exit 0
    fi
    
    # Remove existing entries
    print_status "Removing existing entries..."
    sudo sed -i.bak '/consul\.local/d; /prometheus\.local/d' "$HOSTS_FILE"
fi

# Add new entries
print_status "Adding new entries to $HOSTS_FILE..."
echo "127.0.0.1 consul.local" | sudo tee -a "$HOSTS_FILE" > /dev/null
echo "127.0.0.1 prometheus.local" | sudo tee -a "$HOSTS_FILE" > /dev/null

print_success "Successfully added entries to $HOSTS_FILE"
echo

print_status "Current entries:"
grep -E "(consul\.local|prometheus\.local)" "$HOSTS_FILE"
echo

print_success "Setup completed! You can now access:"
echo "  • Consul UI: http://consul.local"
echo "  • Prometheus: http://prometheus.local"
