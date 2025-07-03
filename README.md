# Consul on Kubernetes

A fully automated production-like Consul deployment on Kubernetes with high availability, security, and monitoring.

## Overview

This project provides a **complete automation solution** for deploying HashiCorp Consul on Kubernetes with:

- **3-node high availability cluster** with proper distribution
- **ACLs enabled** for security with automatic bootstrap token generation
- **Service mesh (Consul Connect)** for microservices communication
- **Prometheus monitoring** with ingress access
- **UI access via ingress** with local domain names
- **Complete automation** - deploy and cleanup with single commands
- **Production-like configuration** optimized for lab environments

## Environment

⚠️ **Lab Environment Only** - This configuration is intended for learning and experimentation purposes and should not be used in production environments.

## Prerequisites

- Docker Desktop with Kubernetes enabled or kind cluster
- kubectl configured to access your cluster
- consul-k8s CLI tool installed
- nginx ingress controller (for UI access)

## Quick Start (Automated)

### 1. Install Prerequisites

```bash
# Install consul-k8s CLI
brew install hashicorp/tap/consul-k8s

# Verify installation
consul-k8s version
```

### 2. Deploy Consul (Fully Automated)

```bash
# Clone this repository
git clone <repository-url>
cd consul/k8s

# Deploy everything with one command
./deploy-consul.sh

# Add /etc/hosts entries for local access
./setup-hosts.sh
```

The deployment script will:

- ✅ Check all prerequisites
- ✅ Deploy 3-node HA Consul cluster
- ✅ Configure ACLs and service mesh
- ✅ Set up Prometheus monitoring with ingress
- ✅ Output the bootstrap token for UI access
- ✅ Provide complete access instructions

### 3. Access the Services

After deployment, access:

- **Consul UI**: <http://consul.local>
- **Prometheus**: <http://prometheus.local>

Use the bootstrap token displayed during deployment to log into the Consul UI.

### 4. Cleanup (Fully Automated)

```bash
# Remove everything with one command
./cleanup-consul.sh --auto --auto-hosts
```

The cleanup script will:

- ✅ Remove all Consul pods and services
- ✅ Delete persistent volumes and data
- ✅ Clean up ACL tokens and secrets
- ✅ Remove custom resources and configurations
- ✅ Delete ingresses and namespace
- ✅ Remove /etc/hosts entries (with --auto-hosts)

## Script Options

### Deployment Script (`deploy-consul.sh`)

```bash
./deploy-consul.sh
```

This script handles everything automatically:

- Prerequisites checking
- Existing deployment detection and cleanup
- 3-node Consul cluster deployment
- ACL bootstrap token retrieval
- Ingress configuration
- Status reporting

### Cleanup Script (`cleanup-consul.sh`)

```bash
# Interactive cleanup
./cleanup-consul.sh

# Automated cleanup (no prompts)
./cleanup-consul.sh --auto

# Automated cleanup with hosts file cleaning
./cleanup-consul.sh --auto --auto-hosts
```

Options:

- `--auto` / `--yes` / `-y`: Skip confirmation prompts
- `--auto-hosts`: Automatically remove /etc/hosts entries
- `--help` / `-h`: Show help message

### Setup Script (`setup-hosts.sh`)

```bash
./setup-hosts.sh
```

Adds required entries to `/etc/hosts` for local domain access.

## Configuration Details

The `values.yaml` file includes:

- **ACLs**: `global.acls.manageSystemACLs: true` - Enables ACLs for security
- **Service Mesh**: `connectInject.enabled: true` - Enables Consul Connect
- **Monitoring**: `prometheus.enabled: true` - Integrates with Prometheus
- **UI Ingress**: Configured for nginx ingress with `consul.local` hostname
- **High Availability**: 3 server replicas distributed across all nodes
- **Control-plane Scheduling**: Tolerations allow scheduling on control-plane for full cluster utilization

## Manual Installation (Alternative)

If you prefer manual installation:

### Install consul-k8s CLI

```bash
# Install consul-k8s CLI
brew install hashicorp/tap/consul-k8s

# Verify installation
consul-k8s version
```

### Deploy Consul

```bash
# Deploy Consul using consul-k8s
consul-k8s install -config-file=values.yaml

# Monitor the deployment
kubectl get pods -n consul
```

### Configure Local Access

Add the following entries to your `/etc/hosts` file:

```text
127.0.0.1 consul.local
127.0.0.1 prometheus.local
```

### Access the Consul UI

1. Wait for all pods to be ready:

   ```bash
   kubectl wait --for=condition=ready pod -l app=consul -n consul --timeout=300s
   ```

2. Access the UI at: <http://consul.local>

### Bootstrap ACLs and Get Token

When ACLs are enabled, Consul automatically generates a bootstrap token. Retrieve it:

```bash
# Get the bootstrap token
kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d

# Alternative: Get token and copy to clipboard (macOS)
kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d | pbcopy
```

### Login to Consul UI

1. Navigate to <http://consul.local>
2. Click "Log in with ACLs"
3. Paste the bootstrap token from previous step
4. Click "Login"

You should now have full access to the Consul UI with administrative privileges.

## Accessing Prometheus

Prometheus is installed as part of the Consul deployment for metrics collection.

### Port Forward (Quick Access)

```bash
kubectl port-forward -n consul svc/prometheus-server 9090:80
```

Then access Prometheus at: <http://localhost:9090>

### Ingress Access (Permanent)

First, apply the Prometheus ingress:

```bash
kubectl apply -f prometheus-ingress.yaml
```

Add to your `/etc/hosts` file:

```text
127.0.0.1 prometheus.local
```

Then access Prometheus at: <http://prometheus.local>

### Prometheus Queries for Consul

Try these sample queries in Prometheus:

- `consul_up` - Check if Consul servers are up
- `consul_raft_leader` - Current Raft leader status
- `consul_serf_member_status` - Member status in the cluster
- `consul_catalog_services` - Number of services in catalog

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

## Architecture

This deployment creates:

- **3 Consul Servers**: High availability cluster with leader election
- **Connect Inject**: Automatic sidecar injection for service mesh
- **Prometheus**: Metrics collection and monitoring
- **Ingress Controllers**: Local domain access to UI and monitoring
- **ACL System**: Security with automatic bootstrap token generation

The servers are distributed across all available nodes using tolerations and anti-affinity rules to ensure high availability.

## Security Features

- **ACLs Enabled**: All communication secured with access control lists
- **TLS Encryption**: All Consul communication encrypted
- **Service Mesh**: Consul Connect provides service-to-service encryption
- **Bootstrap Token**: Securely generated and retrievable for admin access
- **Namespace Isolation**: All resources deployed in dedicated namespace

## Monitoring

- **Prometheus Integration**: Automatic metrics collection
- **Consul Metrics**: Built-in server and client metrics
- **Custom Dashboards**: Ready for Grafana integration
- **Health Checks**: Kubernetes health checks for all components

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the automation scripts
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

