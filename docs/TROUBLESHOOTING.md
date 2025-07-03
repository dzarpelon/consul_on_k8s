# Troubleshooting Guide

## Common Issues and Solutions

### Deployment Issues

#### Prerequisites Not Met

**Problem**: Script fails with "kubectl is required but not installed"
**Solution**:

```bash
# Install kubectl
brew install kubectl

# Verify installation
kubectl version --client
```

**Problem**: Script fails with "Cannot connect to Kubernetes cluster"
**Solution**:

```bash
# Check cluster connection
kubectl cluster-info

# If using Docker Desktop, ensure Kubernetes is enabled
# If using kind, ensure cluster is running
kind get clusters
```

#### Consul Installation Fails

**Problem**: `consul-k8s install` fails with timeout
**Solution**:

```bash
# Check if nodes have sufficient resources
kubectl top nodes

# Check pod events for errors
kubectl get events -n consul --sort-by=.metadata.creationTimestamp

# Increase timeout and retry
consul-k8s install -config-file=config/values.yaml --timeout=10m
```

### Access Issues

#### UI Not Accessible

**Problem**: Cannot access `http://consul.local`
**Solution**:

```bash
# Check if /etc/hosts entry exists
grep consul.local /etc/hosts

# If not, add it
echo "127.0.0.1 consul.local" | sudo tee -a /etc/hosts

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress -n consul
```

**Problem**: Ingress controller not found
**Solution**:

```bash
# Install nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
```

#### Bootstrap Token Issues

**Problem**: Cannot retrieve bootstrap token
**Solution**:

```bash
# Check if secret exists
kubectl get secret consul-bootstrap-acl-token -n consul

# If secret exists but empty, wait for ACL initialization
kubectl wait --for=condition=ready pod -l app=consul -n consul --timeout=300s

# Check ACL initialization logs
kubectl logs -n consul -l app=consul-server-acl-init

# Manual token retrieval
kubectl get secret consul-bootstrap-acl-token -n consul -o jsonpath='{.data.token}' | base64 -d
```

### Performance Issues

#### Slow Deployment

**Problem**: Deployment takes too long
**Solution**:

```bash
# Check resource constraints
kubectl describe nodes

# Check pod resource requests/limits
kubectl describe pods -n consul

# Monitor deployment progress
kubectl get pods -n consul -w
```

#### High Resource Usage

**Problem**: Consul pods using too much CPU/memory
**Solution**:

```bash
# Check resource usage
kubectl top pods -n consul

# Adjust resource limits in values.yaml
# Restart deployment
make cleanup && make deploy
```

### Networking Issues

#### Service Mesh Not Working

**Problem**: Services cannot communicate via service mesh
**Solution**:

```bash
# Check if Connect is enabled
kubectl get pods -n consul -l app=consul-connect-injector

# Verify sidecar injection
kubectl describe pod <your-pod> -n <your-namespace>

# Check Connect configuration
kubectl exec -n consul consul-server-0 -- consul connect ca get-config
```

#### DNS Resolution Issues

**Problem**: Services cannot resolve Consul DNS
**Solution**:

```bash
# Check CoreDNS configuration
kubectl get configmap coredns -n kube-system -o yaml

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it -- nslookup consul.service.consul
```

### Data Issues

#### Data Loss

**Problem**: Consul data disappeared after pod restart
**Solution**:

```bash
# Check persistent volume claims
kubectl get pvc -n consul

# Check persistent volumes
kubectl get pv

# Verify storage class
kubectl get storageclass

# Check if PVs are bound
kubectl describe pvc -n consul
```

#### Backup and Restore

**Problem**: Need to backup/restore Consul data
**Solution**:

```bash
# Create snapshot
kubectl exec -n consul consul-server-0 -- consul snapshot save backup.snap

# List snapshots
kubectl exec -n consul consul-server-0 -- consul snapshot inspect backup.snap

# Restore snapshot (requires cluster restart)
kubectl exec -n consul consul-server-0 -- consul snapshot restore backup.snap
```

## Debugging Commands

### Cluster Status

```bash
# Check all resources
kubectl get all -n consul

# Check cluster members
kubectl exec -n consul consul-server-0 -- consul members

# Check service catalog
kubectl exec -n consul consul-server-0 -- consul catalog services
```

### Logs

```bash
# All Consul logs
kubectl logs -n consul -l app=consul --tail=100

# Specific server logs
kubectl logs -n consul consul-server-0 -f

# Connect injector logs
kubectl logs -n consul -l app=consul-connect-injector
```

### Configuration

```bash
# Check configuration
kubectl exec -n consul consul-server-0 -- consul config read -kind service-defaults -name global

# Validate configuration
kubectl exec -n consul consul-server-0 -- consul validate /consul/config
```

## Getting Help

If you're still having issues:

1. Check the official Consul documentation
2. Review Kubernetes events: `kubectl get events -n consul`
3. Check resource usage: `kubectl top pods -n consul`
4. Review logs: `kubectl logs -n consul -l app=consul`
5. Open an issue with:
   - Your Kubernetes version
   - Error messages
   - Output of `kubectl get pods -n consul -o wide`
