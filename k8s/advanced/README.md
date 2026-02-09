# Advanced Kubernetes Topics

This directory contains advanced configurations that are **optional** for the basic learning path.

## Contents

### ingress.yaml - HTTP Routing with Ingress

**What it does:** Routes external HTTP traffic to services based on hostname/path rules.

**Why it's advanced:**
- Requires installing an Ingress Controller (nginx-ingress, traefik, etc.)
- Adds complexity with annotations and routing rules
- Not needed for basic service exposure (NodePort or port-forward work fine)

**When to use:**
- You want to learn about Ingress and routing
- You need to expose multiple services on one IP
- You want to add TLS/HTTPS termination
- You're simulating production-like setups

## Using Ingress (Optional)

### 1. Install nginx-ingress controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 2. Change Service back to ClusterIP

Edit `k8s/service.yaml`:
```yaml
spec:
  type: ClusterIP  # Change from NodePort
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: http
    # Remove nodePort line
```

Apply:
```bash
kubectl apply -f k8s/service.yaml
```

### 3. Apply Ingress

```bash
kubectl apply -f k8s/advanced/ingress.yaml
```

### 4. Access via Ingress

```bash
# Direct access (if KIND is configured with port mapping to 80)
curl http://localhost/

# With custom hostname
curl -H "Host: go-app.local" http://localhost/
```

## Why Start Simple?

**Basic Setup (Current):**
- Service with NodePort → Direct access at `localhost:30080`
- Easy to understand: one concept (Service)
- Works immediately
- Perfect for learning core Kubernetes

**With Ingress (Advanced):**
- Service (ClusterIP) + Ingress Controller + Ingress Rules
- Three concepts to understand
- Requires installation and configuration
- Better for production-like scenarios

## Other Advanced Topics (Future)

Ideas for expanding your learning:

### ConfigMaps and Secrets
Store configuration separately from code.

**Example ConfigMap:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: go-demo
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  FEATURE_FLAG: "true"
```

Use in Deployment:
```yaml
envFrom:
- configMapRef:
    name: app-config
```

### Persistent Storage
Add a database with persistent volumes.

### Horizontal Pod Autoscaling
Scale based on CPU/memory usage.

```bash
kubectl autoscale deployment go-app \
  --min=2 --max=10 \
  --cpu-percent=80 \
  -n go-demo
```

### Network Policies
Control traffic between pods.

### StatefulSets
For stateful applications (databases, etc.).

### Jobs and CronJobs
Run batch workloads and scheduled tasks.

## Learn More

- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [Ingress Controllers Comparison](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
