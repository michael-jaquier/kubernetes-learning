# KIND Go Nginx Demo

A hands-on Kubernetes learning project using KIND (Kubernetes IN Docker) to deploy a simple Go HTTP service behind Nginx.

## What is KIND?

**KIND** (Kubernetes IN Docker) is a tool for running local Kubernetes clusters using Docker container "nodes". It was primarily designed for testing Kubernetes itself, but is excellent for:

- Local development and testing
- CI pipelines
- Learning Kubernetes without cloud costs
- Quick cluster setup/teardown (seconds!)

**How it works:** KIND creates a Kubernetes cluster by running each "node" as a Docker container. The control plane and worker nodes all run as containers on your local machine.

**Benefits:**
- Fast: Cluster creation in ~30 seconds
- Lightweight: Runs entirely in Docker
- Isolated: Multiple clusters on one machine
- Free: No cloud costs
- Reset-friendly: Easy to destroy and recreate

## Prerequisites

- macOS (this guide)
- [Homebrew](https://brew.sh/) installed
- Docker Desktop running

## Installation

### 1. Install Docker Desktop

```bash
# If not already installed
brew install --cask docker
# Then start Docker Desktop from Applications
```

Or use the automated installer:
```bash
make install-docker
```

### 2. Install KIND

```bash
brew install kind
```

Or use the automated installer:
```bash
make install-kind
```

### 3. Install kubectl

```bash
brew install kubectl
```

Or use the automated installer:
```bash
make install-kubectl
```

**New to kubectl?** Read the [kubectl primer (KUBECTL.md)](./KUBECTL.md) for a comprehensive introduction to the Kubernetes command-line tool.

### 4. Verify installations

Check individual tools:
```bash
docker --version
kind --version
kubectl version --client
```

Or check all at once:
```bash
make check-all
```

Quick install everything:
```bash
make install-all
```

## Project Structure

```
kind-go-nginx-demo/
├── README.md                 # This file
├── KUBERNETES.md            # Kubernetes concepts explained
├── KUBECTL.md               # kubectl primer and command reference
├── NETWORKING.md            # Networking and service access explained
├── Makefile                 # Build and deployment automation
├── kind-config.yaml         # KIND cluster configuration
├── local-registry.sh        # Local registry setup script
├── app/
│   ├── main.go             # Go HTTP service
│   └── Dockerfile          # Container image definition
├── nginx/
│   └── nginx.conf          # Nginx configuration
└── k8s/
    ├── README.md           # Kubernetes manifests guide
    ├── namespace.yaml      # Namespace definition
    ├── deployment.yaml     # Application deployment
    ├── service.yaml        # Service definition (NodePort)
    └── advanced/           # Advanced topics (Ingress, etc.)
```

## Quick Start

### 1. Create KIND cluster with local registry

```bash
make cluster-create
```

This creates a Kubernetes cluster and a local Docker registry at `localhost:5001`.

### 2. Build and push the application

```bash
make build
make push
```

### 3. Deploy to Kubernetes

```bash
make deploy
```

### 4. Access the application

The app is automatically accessible at:
```bash
# Direct access via NodePort (easiest!)
http://localhost:30080

# Or use port-forward for custom port
make port-forward       # Maps to http://localhost:8080
```

### 5. Clean up

```bash
# Delete the cluster
make cluster-delete
```

## Learning Path

1. **Start here**: Read this README to understand KIND
2. **Check prerequisites**: Run `make check-all` to verify your setup
3. **Learn kubectl**: Read [KUBECTL.md](./KUBECTL.md) for kubectl fundamentals
4. **Explore the code**: Check `app/main.go` to see the simple Go service
5. **Understand containers**: Review `app/Dockerfile` to see how the app is containerized
6. **Learn Kubernetes**: Read [KUBERNETES.md](./KUBERNETES.md) for core concepts
7. **Study manifests**: Explore files in `k8s/` directory (heavily commented for learning!)
8. **Experiment**: Modify the code, rebuild, redeploy

## Common Commands

```bash
# View cluster info
kubectl cluster-info --context kind-kind

# List all resources
kubectl get all -n go-demo

# View logs
kubectl logs -n go-demo -l app=go-app -f

# Describe a pod
kubectl describe pod -n go-demo -l app=go-app

# Execute into a pod
kubectl exec -it -n go-demo <pod-name> -- /bin/sh

# Delete all resources
make clean
```

## Troubleshooting

### Docker not running
```bash
# Error: Cannot connect to the Docker daemon
# Solution: Start Docker Desktop
open -a Docker
```

### Port already in use
```bash
# Error: port 5001 is already allocated
# Solution: Stop the conflicting service or change the port in kind-config.yaml
lsof -ti:5001 | xargs kill -9
```

### Image not found
```bash
# Error: ErrImagePull or ImagePullBackOff
# Solution: Ensure you built and pushed the image
make build push
```

### Cannot access application
```bash
# Verify the pod is running
kubectl get pods -n go-demo

# Check logs for errors
kubectl logs -n go-demo -l app=go-app
```

## Next Steps

Once comfortable with this setup:

1. Add a database (PostgreSQL/MySQL)
2. Implement ConfigMaps and Secrets
3. Add monitoring (Prometheus/Grafana)
4. Try Horizontal Pod Autoscaling
5. Experiment with StatefulSets
6. Set up CI/CD pipelines

## Resources

- [KIND Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## License

MIT - Feel free to use this for learning!
