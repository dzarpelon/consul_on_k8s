# Consul on Kubernetes

This repository contains a production-like Consul deployment on Kubernetes for lab environment purposes.

## Overview

This project demonstrates how to deploy HashiCorp Consul on a Kubernetes cluster with:

- Service mesh enabled with Consul Connect
- ACLs enabled for security
- Prometheus monitoring integration
- UI access via ingress
- Production-like configuration

## Environment

⚠️ **Lab Environment Only** - This configuration is intended for learning and experimentation purposes and should not be used in production environments.

## Prerequisites

- Docker Desktop with Kubernetes enabled or kind cluster
- kubectl configured to access your cluster
- Helm 3.x installed
- consul-k8s CLI tool installed

## Installation

### Step 1: Install consul-k8s CLI

```bash
# Install consul-k8s CLI
brew install hashicorp/tap/consul-k8s

# Verify installation
consul-k8s version
```

### Step 2: Deploy Consul

```bash
# Clone this repository
git clone <repository-url>
cd consul/k8s

# Deploy Consul using consul-k8s
consul-k8s install -config-file=values.yaml

# Monitor the deployment
kubectl get pods -n consul
```

### Step 3: Configure Local Ingress Access

Add the following entry to your `/etc/hosts` file:

```text
127.0.0.1 consul.local
```

### Step 4: Access the Consul UI

1. Wait for all pods to be ready:

   ```bash
   kubectl wait --for=condition=ready pod -l app=consul -n consul --timeout=300s
   ```

2. Access the UI at: <http://consul.local>

### Step 5: Bootstrap ACLs and Get Token

When ACLs are enabled, Consul automatically generates a bootstrap token. Retrieve it:

```bash
# Get the bootstrap token
kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d

# Alternative: Get token and copy to clipboard (macOS)
kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d | pbcopy
```

### Step 6: Login to Consul UI

1. Navigate to <http://consul.local>
2. Click "Log in with ACLs"
3. Paste the bootstrap token from Step 5
4. Click "Login"

You should now have full access to the Consul UI with administrative privileges.

## Configuration Highlights

The `values.yaml` file includes:

- **ACLs**: `global.acls.manageSystemACLs: true` - Enables ACLs for security
- **Service Mesh**: `connectInject.enabled: true` - Enables Consul Connect
- **Monitoring**: `prometheus.enabled: true` - Integrates with Prometheus
- **UI Ingress**: Configured for nginx ingress with `consul.local` hostname
- **High Availability**: 3 server replicas with data persistence

## Troubleshooting

### UI Access Issues

If you cannot access the UI:

1. Check ingress controller is running:

   ```bash
   kubectl get pods -n ingress-nginx
   ```

2. Verify /etc/hosts entry exists:

   ```bash
   grep consul.local /etc/hosts
   ```

3. Check ingress resource:

   ```bash
   kubectl get ingress -n consul
   ```

### ACL Token Issues

If you cannot retrieve the bootstrap token:

1. Check if ACLs are enabled:

   ```bash
   kubectl get secret consul-bootstrap-acl-token -n consul
   ```

2. If the secret doesn't exist, ACLs may not be fully bootstrapped yet. Wait a few minutes and try again.

### Pod Issues

If pods are not starting:

1. Check pod status:

   ```bash
   kubectl get pods -n consul
   ```

2. Check pod logs:

   ```bash
   kubectl logs -n consul -l app=consul
   ```

## Upgrading

To upgrade the Consul deployment:

```bash
# Upgrade using consul-k8s
consul-k8s upgrade -config-file=values.yaml

# Or using Helm directly
helm upgrade consul hashicorp/consul -f values.yaml -n consul
```

## Cleanup

To remove the Consul deployment:

```bash
# Uninstall using consul-k8s
consul-k8s uninstall

# Or using Helm
helm uninstall consul -n consul
```
