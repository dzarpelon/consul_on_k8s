# Project Structure

This document describes the functional organization of the Consul on Kubernetes project.

## Directory Structure

```
consul-k8s/
├── README.md                 # Main documentation
├── Makefile                  # Build and deployment automation
├── deploy.sh                 # Main deployment orchestrator
├── cleanup.sh                # Main cleanup orchestrator
├── .env                      # Project configuration
├── config/                   # Configuration files
│   └── values.yaml          # Consul Helm values
├── scripts/                  # Automation scripts
│   ├── deploy-consul.sh     # Core deployment logic
│   ├── cleanup-consul.sh    # Core cleanup logic
│   └── setup-hosts.sh       # /etc/hosts management
├── manifests/               # Kubernetes manifests
│   └── prometheus-ingress.yaml
└── docs/                    # Documentation
    ├── ARCHITECTURE.md      # System architecture
    └── TROUBLESHOOTING.md   # Common issues and solutions
```

## Functional Organization

### Root Level

- **README.md**: Primary documentation and quick start guide
- **Makefile**: Convenient targets for common operations
- **deploy.sh**: Main entry point for deployment
- **cleanup.sh**: Main entry point for cleanup
- **.env**: Project configuration and environment variables

### Configuration (`config/`)

Contains all configuration files:

- **values.yaml**: Consul Helm chart configuration
- Future: Additional config files for different environments

### Scripts (`scripts/`)

Contains executable automation scripts:

- **deploy-consul.sh**: Core deployment logic
- **cleanup-consul.sh**: Core cleanup logic
- **setup-hosts.sh**: /etc/hosts file management
- Future: Additional utility scripts

### Manifests (`manifests/`)

Contains Kubernetes YAML manifests:

- **prometheus-ingress.yaml**: Prometheus ingress configuration
- Future: Additional manifests for extensions

### Documentation (`docs/`)

Contains detailed documentation:

- **ARCHITECTURE.md**: System design and component overview
- **TROUBLESHOOTING.md**: Common issues and solutions
- Future: Additional documentation files

## Usage Patterns

### Simple Usage (Recommended)

```bash
# Deploy
make deploy

# Check status
make status

# Cleanup
make cleanup
```

### Direct Script Usage

```bash
# Deploy
./deploy.sh

# Cleanup
./cleanup.sh --auto
```

### Advanced Usage

```bash
# Deploy with custom config
cd config && ../scripts/deploy-consul.sh

# Port forward for development
make dev

# Get logs
make logs
```

## Design Principles

1. **Separation of Concerns**: Each directory has a specific purpose
2. **Modularity**: Components can be used independently
3. **Convenience**: Multiple ways to accomplish tasks
4. **Documentation**: Clear documentation for each component
5. **Maintainability**: Easy to understand and modify

## Benefits

- **Clear Organization**: Easy to find and understand components
- **Reusability**: Scripts and configs can be reused
- **Extensibility**: Easy to add new features
- **Maintainability**: Logical structure makes maintenance easier
- **Automation**: Multiple levels of automation available
