# Consul Lab

A CLI tool for deploying production-like Consul clusters on Kubernetes with service mesh, monitoring, and security.

## What You Get

Deploy a complete Consul environment in minutes:

```bash
./consul-lab deploy
```

This creates:

- **3-node HA cluster** with automatic failover
- **Service mesh** ready for microservices
- **Web UI** accessible at `http://consul.local`
- **Prometheus monitoring** at `http://prometheus.local`
- **ACL security** with auto-generated admin token
- **Complete cleanup** with `./consul-lab cleanup`

## Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd consul/k8s

# 2. (Optional) Customize configuration
vim config/values.yaml

# 3. Deploy everything
./consul-lab deploy

# 4. Set up local access
./consul-lab setup-hosts

# 5. Access the UIs
./consul-lab ui         # Opens Consul UI
./consul-lab prometheus # Opens Prometheus UI

# 6. Clean up when done
./consul-lab cleanup --auto
```

## Before You Start

Ensure you have:

- Kubernetes cluster (Docker Desktop, kind, etc.)
- `kubectl` configured and working
- `consul-k8s` CLI installed (`brew install hashicorp/tap/consul-k8s`)
- nginx ingress controller running

## Configuration

The default configuration works out of the box, but you may want to customize it:

```bash
# Edit the main configuration file
vim config/values.yaml
```

Key settings you might want to modify:

- **Consul version**: Update `global.image` for different Consul versions
- **Replicas**: Change `server.replicas` (default: 3) for cluster size
- **Resources**: Adjust CPU/memory limits under `server.resources`
- **Storage**: Modify `server.storage` for persistent volume settings
- **Ingress**: Update `ui.ingress.hosts` for custom domain names

Example customizations:

```yaml
# Use different Consul version
global:
  image: hashicorp/consul:1.20.1

# Scale to 5 servers for larger cluster
server:
  replicas: 5

# Custom domain
ui:
  ingress:
    hosts:
      - host: consul.mycompany.local
```

After making changes, validate your configuration:

```bash
./consul-lab validate
```

## CLI Commands

```bash
./consul-lab help           # Show all available commands
./consul-lab deploy         # Deploy complete Consul cluster
./consul-lab status         # Check deployment status
./consul-lab logs           # View Consul logs
./consul-lab token          # Get bootstrap ACL token
./consul-lab cleanup        # Remove everything
./consul-lab port-forward ui # Port forward for development
```

## Project Structure

```text
consul-lab/
├── config/         # Configuration files (values.yaml)
├── scripts/        # Automation scripts
├── manifests/      # Kubernetes manifests
├── docs/           # Documentation
└── consul-lab      # Main CLI tool
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design and components
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Project Structure](docs/PROJECT_STRUCTURE.md) - Detailed structure explanation

## CLI Usage Examples

```bash
# Basic usage
./consul-lab validate                  # Check configuration first
./consul-lab deploy                    # Deploy with interactive prompts
./consul-lab cleanup --auto            # Cleanup without prompts
./consul-lab status                    # Check what's running

# Configuration workflow
vim config/values.yaml                 # Edit configuration
./consul-lab validate                  # Validate changes
./consul-lab deploy                    # Deploy with new config

# Development workflow
./consul-lab deploy                    # Deploy cluster
./consul-lab port-forward ui           # Access via localhost:8500
./consul-lab logs                      # Monitor logs
./consul-lab cleanup --auto            # Clean up

# Troubleshooting
./consul-lab validate                  # Check configuration
./consul-lab test                      # Run connectivity tests
./consul-lab token                     # Get admin token
```

## Environment

⚠️ **Lab Environment Only** - This configuration is intended for learning and experimentation purposes and should not be used in production environments.
