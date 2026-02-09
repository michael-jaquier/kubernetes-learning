# Kubernetes Core Concepts

This document explains the Kubernetes objects used in this project.

## What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform that automates deploying, scaling, and managing containerized applications.

**Key Problems it Solves:**
- Running containers at scale across multiple machines
- Self-healing (restart failed containers)
- Load balancing and service discovery
- Rolling updates and rollbacks
- Resource management (CPU, memory)
- Configuration and secret management

## Architecture Overview

```
┌─────────────────────────────────────────┐
│          Control Plane                  │
│  (API Server, Scheduler, Controllers)   │
└─────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼────┐      ┌────▼────┐
   │ Node 1  │      │ Node 2  │
   │ (Pods)  │      │ (Pods)  │
   └─────────┘      └─────────┘
```

## Core Objects Used in This Project

### 1. Namespace

**What:** Virtual clusters within a physical cluster. Provides isolation and organization.

**Why:** Separate environments (dev, staging, prod) or teams on the same cluster.

**Example:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: go-demo
```

**Key Points:**
- Resource names must be unique within a namespace
- ResourceQuotas can limit resources per namespace
- Default namespace is "default"

---

### 2. Deployment

**What:** Manages a set of identical Pods (replicas) and handles updates.

**Why:** Ensures your application is always running with desired number of replicas.

**Key Features:**
- Declarative updates (desired state)
- Rolling updates (zero downtime)
- Rollback capability
- Self-healing (recreates crashed pods)

**Example:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-app
spec:
  replicas: 3  # Run 3 identical pods
  selector:
    matchLabels:
      app: go-app
  template:
    metadata:
      labels:
        app: go-app
    spec:
      containers:
      - name: go-app
        image: localhost:5001/go-app:latest
        ports:
        - containerPort: 8080
```

**Key Concepts:**
- **Replicas:** Number of pod copies to run
- **Selector:** How Deployment finds its Pods
- **Template:** Pod specification (what to run)
- **Strategy:** How to update (RollingUpdate, Recreate)

---

### 3. Pod

**What:** The smallest deployable unit in Kubernetes. Contains one or more containers.

**Why:** Represents a single instance of your application.

**Key Points:**
- Pods are ephemeral (can be killed/recreated)
- Each pod gets its own IP address
- Containers in a pod share network namespace
- Usually managed by higher-level objects (Deployments)

**You typically don't create Pods directly** - Deployments create them for you.

---

### 4. Service

**What:** Stable network endpoint for a set of Pods. Provides load balancing.

**Why:** Pods are ephemeral with changing IPs. Services provide a stable DNS name and IP.

**Types:**
- **ClusterIP** (default): Only accessible within the cluster
- **NodePort**: Exposes on each Node's IP at a static port
- **LoadBalancer**: Cloud provider's load balancer
- **ExternalName**: Maps to DNS name

**Example:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: go-app-service
spec:
  type: ClusterIP
  selector:
    app: go-app  # Routes traffic to pods with this label
  ports:
  - port: 80         # Service port
    targetPort: 8080 # Container port
```

**How it works:**
1. Service watches for Pods matching the selector
2. Automatically updates endpoints as Pods come/go
3. Load balances traffic across healthy Pods
4. Provides DNS name: `<service-name>.<namespace>.svc.cluster.local`

---

### 5. Ingress

**What:** HTTP/HTTPS routing rules to services. Acts as a reverse proxy.

**Why:** Expose multiple services under one IP with path-based routing.

**Example:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-app-ingress
spec:
  rules:
  - host: go-app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: go-app-service
            port:
              number: 80
```

**Key Points:**
- Requires an Ingress Controller (nginx, traefik, etc.)
- Can handle TLS/SSL termination
- Supports virtual hosting (multiple domains)
- Can route based on paths or hosts

---

## How They Work Together

```
Internet/User
     │
     ▼
┌─────────────┐
│   Ingress   │ ◄── Routes traffic based on hostname/path
└─────────────┘
     │
     ▼
┌─────────────┐
│   Service   │ ◄── Load balances to healthy Pods
└─────────────┘
     │
     ├──────────┬──────────┐
     ▼          ▼          ▼
  ┌────┐    ┌────┐    ┌────┐
  │Pod1│    │Pod2│    │Pod3│ ◄── Managed by Deployment
  └────┘    └────┘    └────┘
```

**Flow:**
1. **Deployment** creates and manages Pods
2. **Service** discovers Pods via label selectors
3. **Ingress** routes external traffic to Service
4. Service load balances to Pods

## Labels and Selectors

**Labels:** Key-value pairs attached to objects for identification.

```yaml
metadata:
  labels:
    app: go-app
    version: v1
    environment: production
```

**Selectors:** Query labels to find resources.

```yaml
selector:
  matchLabels:
    app: go-app
```

**Why important:**
- Services use selectors to find Pods
- Deployments use selectors to manage Pods
- You can query: `kubectl get pods -l app=go-app`

## Configuration Management

### ConfigMaps
Store non-sensitive configuration data.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
```

### Secrets
Store sensitive data (passwords, tokens).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 encoded
```

## Health Checks

### Liveness Probe
Is the container alive? If fails, restart it.

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Readiness Probe
Is the container ready to serve traffic? If fails, remove from Service endpoints.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Resource Management

```yaml
resources:
  requests:      # Guaranteed resources
    memory: "64Mi"
    cpu: "250m"
  limits:        # Maximum allowed
    memory: "128Mi"
    cpu: "500m"
```

**Requests:** Scheduler uses this to place Pods
**Limits:** Enforced maximums (exceed = throttled/killed)

## Key Kubernetes Principles

1. **Declarative Configuration:** You declare desired state, K8s makes it happen
2. **Self-Healing:** K8s constantly reconciles actual state with desired state
3. **Immutable Infrastructure:** Don't modify running containers, deploy new versions
4. **Cattle, not Pets:** Pods are disposable and replaceable
5. **Labels Everywhere:** Flexible grouping and selection of resources

## Common kubectl Commands

```bash
# Get resources
kubectl get pods -n go-demo
kubectl get deployments -n go-demo
kubectl get services -n go-demo

# Describe (detailed info)
kubectl describe pod <pod-name> -n go-demo

# Logs
kubectl logs -f <pod-name> -n go-demo
kubectl logs -f -l app=go-app -n go-demo  # Follow logs by label

# Execute commands in container
kubectl exec -it <pod-name> -n go-demo -- /bin/sh

# Apply manifests
kubectl apply -f k8s/

# Delete resources
kubectl delete -f k8s/deployment.yaml

# Port forwarding (testing)
kubectl port-forward -n go-demo service/go-app-service 8080:80

# Scale deployment
kubectl scale deployment go-app -n go-demo --replicas=5

# Rollout status
kubectl rollout status deployment/go-app -n go-demo

# Rollback
kubectl rollout undo deployment/go-app -n go-demo
```

## Learning Resources

- [Kubernetes Basics Tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Patterns Book](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)
