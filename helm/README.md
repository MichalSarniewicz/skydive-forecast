# Skydive Forecast - Kubernetes Deployment with Helm

This directory contains Helm charts for deploying Skydive Forecast microservices to Kubernetes.

## Prerequisites

- Kubernetes cluster (Minikube, Kind, or cloud provider)
- Helm 3.x installed
- kubectl configured

## Quick Start

### 1. Install Helm Chart

```bash
# Install with default values
helm install skydive-forecast ./skydive-forecast -n skydive-forecast --create-namespace

# Install with custom values
helm install skydive-forecast ./skydive-forecast -n skydive-forecast --create-namespace -f custom-values.yaml
```

### 2. Verify Deployment

```bash
# Check all pods
kubectl get pods -n skydive-forecast

# Check services
kubectl get svc -n skydive-forecast

# Check deployments
kubectl get deployments -n skydive-forecast
```

### 3. Access Services

```bash
# Gateway (LoadBalancer)
kubectl get svc gateway -n skydive-forecast

# Port-forward for local access
kubectl port-forward svc/gateway 8080:8080 -n skydive-forecast
```

## Architecture

```
Kubernetes Cluster
├── Namespace: skydive-forecast
├── Config Server (1 replica)
├── Gateway (2 replicas) - LoadBalancer
├── User Service (2 replicas)
├── Analysis Service (2 replicas)
├── Location Service (2 replicas)
├── PostgreSQL (StatefulSet)
├── Redis (StatefulSet)
├── Kafka + Zookeeper (StatefulSet)
├── Prometheus
└── Grafana - LoadBalancer
```

## Configuration

### values.yaml Structure

```yaml
global:
  namespace: skydive-forecast
  imagePullPolicy: IfNotPresent

configServer:
  enabled: true
  replicaCount: 1
  resources: {...}

gateway:
  enabled: true
  replicaCount: 2
  service:
    type: LoadBalancer
  resources: {...}

# ... other services
```

### Custom Configuration

Create `custom-values.yaml`:

```yaml
gateway:
  replicaCount: 3
  resources:
    requests:
      memory: "1Gi"
      cpu: "1000m"
```

Apply:
```bash
helm upgrade skydive-forecast ./skydive-forecast -n skydive-forecast -f custom-values.yaml
```

## Scaling

```bash
# Scale gateway
kubectl scale deployment gateway --replicas=3 -n skydive-forecast

# Or via Helm
helm upgrade skydive-forecast ./skydive-forecast -n skydive-forecast --set gateway.replicaCount=3
```

## Monitoring

### Prometheus
```bash
kubectl port-forward svc/prometheus-server 9090:9090 -n skydive-forecast
# Access: http://localhost:9090
```

### Grafana
```bash
kubectl get svc grafana -n skydive-forecast
# Access via LoadBalancer IP or port-forward
kubectl port-forward svc/grafana 3000:3000 -n skydive-forecast
# Login: admin/admin
```

## Health Checks

All services include:
- **Liveness Probe**: `/actuator/health` (restarts unhealthy pods)
- **Readiness Probe**: `/actuator/health` (removes from service if not ready)

## Resource Management

Default resource limits per service:

| Service | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|-------------|----------------|-----------|--------------|
| Config Server | 250m | 256Mi | 500m | 512Mi |
| Gateway | 500m | 512Mi | 1000m | 1Gi |
| Microservices | 500m | 512Mi | 1000m | 1Gi |

## Uninstall

```bash
helm uninstall skydive-forecast -n skydive-forecast
kubectl delete namespace skydive-forecast
```

## Production Considerations

### 1. Image Registry
Update `values.yaml` with your registry:
```yaml
gateway:
  image:
    repository: your-registry.io/skydive-forecast/gateway
    tag: v1.0.0
```

### 2. Secrets Management
Use Kubernetes Secrets for sensitive data:
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=secret \
  -n skydive-forecast
```

### 3. Ingress
Add Ingress for external access:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: skydive-forecast-ingress
spec:
  rules:
  - host: api.skydiveforecast.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gateway
            port:
              number: 8080
```

### 4. Persistent Volumes
Configure storage classes for databases:
```yaml
postgresql:
  primary:
    persistence:
      storageClass: "fast-ssd"
      size: 20Gi
```

## Testing Locally

### Minikube
```bash
minikube start --cpus=4 --memory=8192
eval $(minikube docker-env)
# Build images
docker build -t skydive-forecast/gateway:latest ../skydive-forecast-gateway
# Install chart
helm install skydive-forecast ./skydive-forecast -n skydive-forecast --create-namespace
```

### Kind
```bash
kind create cluster --name skydive-forecast
# Load images
kind load docker-image skydive-forecast/gateway:latest --name skydive-forecast
# Install chart
helm install skydive-forecast ./skydive-forecast -n skydive-forecast --create-namespace
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Deploy to Kubernetes
  run: |
    helm upgrade --install skydive-forecast ./helm/skydive-forecast \
      --namespace skydive-forecast \
      --create-namespace \
      --set gateway.image.tag=${{ github.sha }}
```

## Troubleshooting

```bash
# Check pod logs
kubectl logs -f deployment/gateway -n skydive-forecast

# Describe pod for events
kubectl describe pod <pod-name> -n skydive-forecast

# Check config
kubectl get configmap -n skydive-forecast

# Check secrets
kubectl get secrets -n skydive-forecast
```

## License

This project is part of the Skydive Forecast system.
