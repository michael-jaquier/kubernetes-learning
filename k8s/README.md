# Kubernetes Manifests

This directory contains the Kubernetes manifest files for deploying the Go application.

## Files Overview

| File | Purpose | What it Does |
|------|---------|--------------|
| `namespace.yaml` | Creates isolated environment | Organizes resources in a dedicated namespace |
| `deployment.yaml` | Manages application pods | Ensures desired number of app replicas are running |
| `service.yaml` | Provides stable network endpoint | Load balances traffic to application pods (NodePort for easy access) |

**Note:** Ingress has been moved to `advanced/` directory. Start with the basics first!

## Deployment Order

While Kubernetes handles dependencies well, a logical order is:

```bash
1. namespace.yaml      # Create the namespace first
2. deployment.yaml     # Deploy the application
3. service.yaml        # Expose the application (NodePort)
```

Apply all at once:
```bash
kubectl apply -f k8s/
```

After deployment, access your app at: **http://localhost:30080**

## Quick Reference

### View all resources
```bash
kubectl get all -n go-demo
```

### Check pod logs
```bash
kubectl logs -n go-demo -l app=go-app -f
```

### Describe a resource
```bash
kubectl describe deployment go-app -n go-demo
```

### Update a deployment (after changing manifest)
```bash
kubectl apply -f k8s/deployment.yaml
```

### Delete all resources
```bash
kubectl delete -f k8s/
```

### Scale replicas
```bash
kubectl scale deployment go-app -n go-demo --replicas=5
```

### Watch pods in real-time
```bash
kubectl get pods -n go-demo -w
```

## Common Modifications

### Change number of replicas

Edit `deployment.yaml`:
```yaml
spec:
  replicas: 5  # Change from 3 to 5
```

### Add environment variables

Edit `deployment.yaml`:
```yaml
env:
- name: APP_ENV
  value: "production"
- name: LOG_LEVEL
  value: "debug"
```

### Add resource limits

Edit `deployment.yaml`:
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

### Change service type

Edit `service.yaml`:
```yaml
spec:
  type: NodePort  # Change from ClusterIP
```

## Debugging Tips

### Pod not starting?
```bash
# Check pod status
kubectl get pods -n go-demo

# View events
kubectl describe pod <pod-name> -n go-demo

# Check logs
kubectl logs <pod-name> -n go-demo
```

### Image pull errors?
```bash
# Verify image exists in registry
curl http://localhost:5001/v2/_catalog

# Check image name in deployment.yaml matches pushed image
```

### Service not accessible?
```bash
# Check service endpoints
kubectl get endpoints -n go-demo

# Verify selector matches pod labels
kubectl get pods -n go-demo --show-labels
```

## Advanced: Rolling Updates

When you update the image version:

```bash
# Method 1: Update deployment.yaml and apply
kubectl apply -f k8s/deployment.yaml

# Method 2: Set image directly
kubectl set image deployment/go-app go-app=localhost:5001/go-app:v2 -n go-demo

# Watch the rollout
kubectl rollout status deployment/go-app -n go-demo

# View rollout history
kubectl rollout history deployment/go-app -n go-demo

# Rollback if needed
kubectl rollout undo deployment/go-app -n go-demo
```

## Best Practices

1. **Always use namespaces** - Isolate resources
2. **Label everything** - Makes selection and organization easy
3. **Set resource limits** - Prevents resource starvation
4. **Use health checks** - Enable self-healing
5. **Version your images** - Avoid using `:latest` in production
6. **ConfigMaps for config** - Keep configuration separate from code
7. **Secrets for sensitive data** - Never hardcode credentials

## Learn More

- See `../KUBERNETES.md` for detailed concept explanations
- See `../README.md` for project overview
