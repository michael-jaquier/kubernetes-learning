# Kubernetes Networking Explained

## How You Access the Application

This project uses **NodePort** for easy, out-of-the-box access. Here's how it works:

### The Flow

```
Your Browser
    ↓
http://localhost:30080  ← You access here
    ↓
KIND Node (Docker container)
    ↓
Service: go-app-service:80
    ↓
Pod 1 (8080) ← Load balanced
Pod 2 (8080) ← across all
Pod 3 (8080) ← healthy pods
```

### Port Breakdown

| Port | Layer | Purpose |
|------|-------|---------|
| 30080 | NodePort | External access from your machine |
| 80 | Service | Internal cluster communication |
| 8080 | Container | Go application listening port |

## Service Types Explained

### 1. ClusterIP (Default)
**Internal only** - Can't access from outside the cluster.

```yaml
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
```

**When to use:**
- Internal microservices that only talk to each other
- Backend services behind an Ingress

**Access method:**
- Port-forward: `kubectl port-forward service/my-service 8080:80`
- From inside cluster: `curl http://my-service`

---

### 2. NodePort (What we use!)
**Exposes on each node** - Accessible from outside via node IP.

```yaml
spec:
  type: NodePort
  ports:
  - port: 80          # Service port
    targetPort: 8080  # Container port
    nodePort: 30080   # External port (30000-32767)
```

**When to use:**
- Development and learning
- When you don't have a cloud load balancer
- Simple external access

**Access method:**
- Direct: `http://localhost:30080`
- From any node: `http://<node-ip>:30080`

**Pros:**
- Simple, works immediately
- No additional components needed
- Good for learning

**Cons:**
- Non-standard ports (30000-32767 range)
- Need to manage node IPs
- Not ideal for production

---

### 3. LoadBalancer
**Creates cloud load balancer** - Gets external IP from cloud provider.

```yaml
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
```

**When to use:**
- Production on cloud platforms (AWS, GCP, Azure)
- Need standard ports (80, 443)
- High availability with cloud LB

**Access method:**
- External IP: `http://<external-ip>`
- Cloud provider assigns and manages the IP

**Note:** Doesn't work in KIND (no cloud provider).

---

### 4. ExternalName
**DNS alias** - Maps to external DNS name.

```yaml
spec:
  type: ExternalName
  externalName: api.example.com
```

**When to use:**
- Integrate external services
- Database hosted elsewhere
- Migration scenarios

---

## KIND-Specific Networking

### How KIND Maps Ports

KIND runs Kubernetes nodes as Docker containers. We configure port mappings in `kind-config.yaml`:

```yaml
nodes:
  - role: control-plane
    extraPortMappings:
    - containerPort: 30080  # Inside the KIND node
      hostPort: 30080       # On your laptop (localhost)
      protocol: TCP
```

This creates the connection:
```
localhost:30080 → KIND Docker Container:30080 → NodePort Service
```

### Why Port 30080?

NodePort services must use ports in range **30000-32767**. We chose 30080 because:
- It's in the valid range
- Easy to remember (30000 + 80)
- Mapped in our KIND config

## Alternative Access Methods

### Port-Forward (Development)
Tunnels any port you want to a service or pod.

```bash
kubectl port-forward -n go-demo service/go-app-service 8080:80
# Access: http://localhost:8080
```

**Pros:**
- Any port you want
- Works with any service type
- Good for debugging

**Cons:**
- Manual command needed
- Single connection (not load balanced at kubectl level)
- Stops when you close terminal

---

### Ingress (Production-like)
HTTP routing layer - routes based on hostname/path.

**Requires:**
- Ingress Controller (nginx, traefik, etc.)
- Additional configuration

**When to use:**
- Multiple services on one IP
- Path/host-based routing
- TLS/HTTPS termination
- Production-like setup

**Example:**
```yaml
# app1.example.com → service1
# app2.example.com → service2
# example.com/api → api-service
```

See `k8s/advanced/ingress.yaml` for details.

---

## Comparison Table

| Type | External Access | Use Case | Complexity |
|------|----------------|----------|------------|
| ClusterIP | ❌ No | Internal services | Low |
| NodePort | ✅ Yes (non-standard port) | Development | **Low ← We use this** |
| LoadBalancer | ✅ Yes (cloud LB) | Production (cloud) | Medium |
| Port-Forward | ✅ Yes (manual) | Debugging | Low |
| Ingress | ✅ Yes (HTTP routing) | Production (multi-service) | High |

## Service Discovery

Services get automatic DNS names:

```
# Short form (same namespace)
http://go-app-service

# Full form
http://go-app-service.go-demo.svc.cluster.local
         ↑              ↑        ↑      ↑
    service name    namespace  "service"  cluster domain
```

**Example from another pod:**
```bash
kubectl run test --image=curlimages/curl --rm -it -- sh
$ curl http://go-app-service.go-demo
# Works! No IP needed, just the service name
```

## Hands-On Testing

### 1. Check Service
```bash
kubectl get service go-app-service -n go-demo

# Output shows:
# TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
# NodePort   10.96.xxx.xxx   <none>        80:30080/TCP
#                                             ↑
#                                          NodePort!
```

### 2. Test from Outside Cluster
```bash
curl http://localhost:30080
# Should return HTML response
```

### 3. Test from Inside Cluster
```bash
kubectl run test-pod --image=curlimages/curl --rm -it -n go-demo -- \
  curl http://go-app-service

# Uses service name - DNS resolves it!
```

### 4. View Endpoints
```bash
kubectl get endpoints go-app-service -n go-demo

# Shows actual pod IPs the service routes to
# NAME              ENDPOINTS
# go-app-service    10.244.1.2:8080,10.244.2.3:8080,10.244.2.4:8080
```

### 5. Test Load Balancing
```bash
# Make multiple requests, see different pod names
for i in {1..10}; do
  curl -s http://localhost:30080/api/info | grep hostname
done

# You'll see different pod names - load balancing works!
```

## Troubleshooting

### Can't access localhost:30080

**Check service:**
```bash
kubectl get svc go-app-service -n go-demo
# Verify TYPE is NodePort and PORT(S) shows 80:30080/TCP
```

**Check KIND port mapping:**
```bash
docker port kind-control-plane
# Should show: 30080/tcp -> 0.0.0.0:30080
```

**Check pods are ready:**
```bash
kubectl get pods -n go-demo
# All should be Running and READY 1/1
```

### Connection refused

**Check if pods are running:**
```bash
kubectl get pods -n go-demo
kubectl logs -n go-demo -l app=go-app
```

**Check service endpoints:**
```bash
kubectl get endpoints go-app-service -n go-demo
# Should show pod IPs, not empty
```

## Next Steps

1. ✅ **Start here:** Use NodePort (current setup) - works immediately
2. 📚 **Learn more:** Experiment with port-forward
3. 🚀 **Advanced:** Try Ingress setup (see `k8s/advanced/`)

## Learn More

- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [KIND Networking](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
