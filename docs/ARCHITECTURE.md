# Architecture Documentation

## Overview

This deployment creates a production-like Consul cluster on Kubernetes with the following components:

## Components

### Core Services

- **Consul Servers (3 replicas)**: Provide the core Consul functionality

  - Leader election via Raft consensus
  - Distributed across nodes for high availability
  - Persistent storage for data durability

- **Consul Connect Injector**: Enables service mesh capabilities

  - Automatic sidecar proxy injection
  - Service-to-service encryption
  - Traffic management and observability

- **Consul Controller**: Manages custom resources
  - Handles Consul CRDs (Custom Resource Definitions)
  - Manages configuration updates
  - Ensures desired state compliance

### Monitoring

- **Prometheus**: Metrics collection and alerting
  - Scrapes Consul metrics automatically
  - Provides monitoring dashboards
  - Integrates with Grafana (optional)

### Security

- **ACL System**: Access control and authentication

  - Bootstrap token for initial access
  - Fine-grained permissions
  - Token-based authentication

- **TLS Encryption**: Secure communication
  - All inter-node communication encrypted
  - Automatic certificate management
  - Secure client connections

### Networking

- **Ingress Controllers**: External access to services
  - Consul UI accessible via `consul.local`
  - Prometheus UI accessible via `prometheus.local`
  - nginx ingress controller required

## Data Flow

1. **Client Requests** → Ingress Controller → Consul UI/API
2. **Service Discovery** → Consul Servers → Service Catalog
3. **Service Mesh** → Connect Injector → Envoy Sidecars
4. **Monitoring** → Prometheus → Consul Metrics
5. **Security** → ACL System → Token Validation

## High Availability

- **3-Node Cluster**: Fault tolerance with leader election
- **Node Distribution**: Pods spread across available nodes
- **Persistent Storage**: Data survives pod restarts
- **Health Checks**: Automatic failure detection and recovery

## Scaling

- **Horizontal**: Add more Consul servers by increasing replicas
- **Vertical**: Increase resource limits for existing pods
- **Storage**: Persistent volumes automatically resize

## Security Model

- **Network Policies**: Control traffic between pods
- **RBAC**: Kubernetes role-based access control
- **ACLs**: Consul access control lists
- **TLS**: Encrypted communication at all levels
