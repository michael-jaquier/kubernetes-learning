# kubectl Primer

## What is kubectl?

**kubectl** (pronounced "kube-control" or "kube-cuttle") is the command-line tool for interacting with Kubernetes clusters. It's your primary interface for:

- Deploying applications
- Inspecting and managing cluster resources
- Viewing logs and debugging
- Executing commands in containers

Think of kubectl as the "remote control" for Kubernetes - every action you take on a cluster goes through kubectl.

## Installation

### macOS (Homebrew)

```bash
# Install kubectl
brew install kubectl

# Verify installation
kubectl version --client
```

### macOS (Direct Download)

```bash
# Download the latest release
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/arm64/kubectl"

# Make it executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

### Linux

```bash
# Download latest
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable and move
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

### Windows (Chocolatey)

```powershell
choco install kubernetes-cli
```

### Verify Installation

```bash
kubectl version --client --output=yaml
```

## kubectl Basics

### Command Structure

```bash
kubectl [command] [TYPE] [NAME] [flags]
```

Examples:
```bash
kubectl get pods
#       │   │
#       │   └─ Resource type
#       └───── Command (action)

kubectl get pods my-pod -n my-namespace -o yaml
#                 │       │              │
#                 │       │              └─ Output format flag
#                 │       └──────────────── Namespace flag
#                 └──────────────────────── Resource name
```

## Essential Commands

### Cluster Information

```bash
# View cluster info
kubectl cluster-info

# View nodes in cluster
kubectl get nodes

# Node details
kubectl describe node <node-name>

# Cluster version
kubectl version
```

### Working with Resources

#### Get (List resources)

```bash
# List all pods in current namespace
kubectl get pods

# List pods in specific namespace
kubectl get pods -n go-demo

# List all pods in all namespaces
kubectl get pods --all-namespaces
# or
kubectl get pods -A

# List with more details
kubectl get pods -o wide

# List multiple resource types
kubectl get pods,services,deployments -n go-demo

# Watch for changes (auto-refresh)
kubectl get pods -w
```

#### Describe (Detailed information)

```bash
# Detailed info about a pod
kubectl describe pod <pod-name> -n go-demo

# Describe includes:
# - Metadata and labels
# - Status and conditions
# - Events (very useful for debugging!)
# - Resource usage
# - Volume mounts
```

#### Create/Apply (Deploy resources)

```bash
# Create resource from file
kubectl create -f deployment.yaml

# Apply (create or update)
kubectl apply -f deployment.yaml

# Apply entire directory
kubectl apply -f k8s/

# Apply from URL
kubectl apply -f https://example.com/manifest.yaml
```

#### Delete (Remove resources)

```bash
# Delete by file
kubectl delete -f deployment.yaml

# Delete by name and type
kubectl delete pod my-pod -n go-demo

# Delete all pods with label
kubectl delete pods -l app=go-app -n go-demo

# Delete namespace (deletes everything in it!)
kubectl delete namespace go-demo
```

### Logs and Debugging

```bash
# View pod logs
kubectl logs <pod-name> -n go-demo

# Follow logs (stream)
kubectl logs -f <pod-name> -n go-demo

# Logs from previous crashed container
kubectl logs <pod-name> --previous -n go-demo

# Logs from specific container in multi-container pod
kubectl logs <pod-name> -c <container-name> -n go-demo

# Logs from all pods with label
kubectl logs -l app=go-app -n go-demo --tail=50
```

### Execute Commands in Pods

```bash
# Interactive shell in pod
kubectl exec -it <pod-name> -n go-demo -- /bin/sh

# Run single command
kubectl exec <pod-name> -n go-demo -- ls -la

# Execute in specific container
kubectl exec -it <pod-name> -c <container-name> -n go-demo -- /bin/sh
```

### Port Forwarding

```bash
# Forward local port to pod
kubectl port-forward <pod-name> 8080:8080 -n go-demo

# Forward to service (load balanced)
kubectl port-forward service/go-app-service 8080:80 -n go-demo

# Then access: http://localhost:8080
```

### Scaling

```bash
# Scale deployment to 5 replicas
kubectl scale deployment go-app --replicas=5 -n go-demo

# Autoscale based on CPU
kubectl autoscale deployment go-app --min=2 --max=10 --cpu-percent=80 -n go-demo
```

### Updates and Rollouts

```bash
# Update image
kubectl set image deployment/go-app go-app=myapp:v2 -n go-demo

# Check rollout status
kubectl rollout status deployment/go-app -n go-demo

# View rollout history
kubectl rollout history deployment/go-app -n go-demo

# Rollback to previous version
kubectl rollout undo deployment/go-app -n go-demo

# Rollback to specific revision
kubectl rollout undo deployment/go-app --to-revision=2 -n go-demo

# Pause rollout
kubectl rollout pause deployment/go-app -n go-demo

# Resume rollout
kubectl rollout resume deployment/go-app -n go-demo
```

### Labels and Selectors

```bash
# Show labels
kubectl get pods --show-labels -n go-demo

# Filter by label
kubectl get pods -l app=go-app -n go-demo
kubectl get pods -l 'environment in (production,staging)' -n go-demo

# Add label to pod
kubectl label pod <pod-name> environment=production -n go-demo

# Remove label
kubectl label pod <pod-name> environment- -n go-demo
```

## Output Formats

```bash
# YAML output (full resource definition)
kubectl get pod <pod-name> -o yaml -n go-demo

# JSON output
kubectl get pod <pod-name> -o json -n go-demo

# Wide output (more columns)
kubectl get pods -o wide -n go-demo

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase -n go-demo

# JSONPath (extract specific fields)
kubectl get pods -o jsonpath='{.items[*].metadata.name}' -n go-demo

# Name only (useful for scripts)
kubectl get pods -o name -n go-demo
```

## Contexts and Namespaces

### Contexts (managing multiple clusters)

```bash
# List contexts (clusters)
kubectl config get-contexts

# Current context
kubectl config current-context

# Switch context
kubectl config use-context kind-kind

# View full config
kubectl config view
```

### Namespaces

```bash
# List namespaces
kubectl get namespaces

# Set default namespace for context
kubectl config set-context --current --namespace=go-demo

# Now all commands use go-demo namespace by default
kubectl get pods  # same as: kubectl get pods -n go-demo
```

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# kubectl alias
alias k=kubectl

# Common operations
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kpf='kubectl port-forward'

# With namespace
alias kgpn='kubectl get pods -n'
alias kln='kubectl logs -n'
```

## Quick Reference Card

| Task | Command |
|------|---------|
| Get resource | `kubectl get <type> [name]` |
| Describe resource | `kubectl describe <type> <name>` |
| Create from file | `kubectl apply -f <file>` |
| Delete resource | `kubectl delete <type> <name>` |
| View logs | `kubectl logs <pod-name>` |
| Exec into pod | `kubectl exec -it <pod> -- /bin/sh` |
| Port forward | `kubectl port-forward <pod> 8080:80` |
| Scale deployment | `kubectl scale deployment <name> --replicas=3` |
| Get events | `kubectl get events` |
| Get all resources | `kubectl get all` |

## Common Workflows

### Deploy an Application

```bash
# 1. Apply manifests
kubectl apply -f k8s/

# 2. Check deployment status
kubectl rollout status deployment/go-app -n go-demo

# 3. View pods
kubectl get pods -n go-demo

# 4. Check logs
kubectl logs -l app=go-app -n go-demo
```

### Debug a Failing Pod

```bash
# 1. Get pod status
kubectl get pods -n go-demo

# 2. Describe pod (check events!)
kubectl describe pod <pod-name> -n go-demo

# 3. View logs
kubectl logs <pod-name> -n go-demo

# 4. Check previous container logs (if crashed)
kubectl logs <pod-name> --previous -n go-demo

# 5. Execute into pod (if running)
kubectl exec -it <pod-name> -n go-demo -- /bin/sh
```

### Update an Application

```bash
# 1. Build new image
docker build -t localhost:5001/go-app:v2 app/
docker push localhost:5001/go-app:v2

# 2. Update deployment
kubectl set image deployment/go-app go-app=localhost:5001/go-app:v2 -n go-demo

# 3. Watch rollout
kubectl rollout status deployment/go-app -n go-demo

# 4. Verify
kubectl get pods -n go-demo
```

## kubectl Configuration

kubectl uses a config file at `~/.kube/config` to store:
- Cluster connection details
- Authentication credentials
- Context (cluster + namespace + user combinations)

KIND automatically updates this when you create a cluster.

View config:
```bash
kubectl config view
```

## Learning Resources

- [Official kubectl docs](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl book](https://kubectl.docs.kubernetes.io/)

## Pro Tips

1. **Use `-o wide`** for more information: `kubectl get pods -o wide`
2. **Use `--watch`** to monitor changes: `kubectl get pods -w`
3. **Use `--dry-run=client`** to preview without applying: `kubectl apply -f file.yaml --dry-run=client`
4. **Use `explain`** to learn about resources: `kubectl explain pod.spec.containers`
5. **Use `diff`** to see changes before applying: `kubectl diff -f file.yaml`
6. **Always specify namespace** with `-n` to avoid confusion
7. **Use labels** for grouping and bulk operations
8. **Check events** when debugging: `kubectl get events --sort-by='.lastTimestamp'`

## Next Steps

1. Install kubectl: `brew install kubectl`
2. Create a KIND cluster: `make cluster-create`
3. Try basic commands: `kubectl get nodes`
4. Deploy the app: `make deploy`
5. Explore resources: `kubectl get all -n go-demo`
6. View logs: `make logs`
7. Experiment and learn!
