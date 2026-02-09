# Persistent Storage in Kubernetes

## Overview

By default, containers are **ephemeral** - when a pod dies, all data inside it is lost. Persistent Volumes (PV) and Persistent Volume Claims (PVC) solve this problem by providing storage that survives pod restarts and rescheduling.

## Core Concepts

### Persistent Volume (PV)
A piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It's a **cluster-level resource** that exists independently of any pod.

**Think of it as:** The actual physical/virtual disk

### Persistent Volume Claim (PVC)
A **request for storage** by a user. It's like a pod - pods consume node resources, PVCs consume PV resources.

**Think of it as:** A reservation or request for disk space

### Storage Class
A way to describe different "classes" of storage (fast SSD, slow HDD, etc.). Enables **dynamic provisioning** of PVs.

**Think of it as:** A template for creating storage on-demand

## The Flow

```
1. Admin creates PV (or uses StorageClass for dynamic provisioning)
   ↓
2. User creates PVC requesting specific size/access mode
   ↓
3. Kubernetes binds PVC to suitable PV
   ↓
4. Pod mounts PVC as a volume
   ↓
5. Data persists even if pod is deleted
```

## Files in This Directory

| File | Purpose |
|------|---------|
| `local-pv.yaml` | Persistent Volume using local node storage |
| `pvc.yaml` | Persistent Volume Claim requesting storage |
| `deployment-with-storage.yaml` | Example deployment using PVC |
| `statefulset-example.yaml` | StatefulSet with automatic PVC creation |

## Quick Start

### 1. Create the Persistent Volume
```bash
kubectl apply -f k8s/advanced/storage/local-pv.yaml
```

### 2. Create the Persistent Volume Claim
```bash
kubectl apply -f k8s/advanced/storage/pvc.yaml
```

### 3. Verify Binding
```bash
kubectl get pv
kubectl get pvc -n go-demo
```

You should see STATUS: Bound

### 4. Use in Deployment
```bash
kubectl apply -f k8s/advanced/storage/deployment-with-storage.yaml
```

### 5. Test Persistence
```bash
# Run the test
make test-storage

# This will:
# - Write data to the persistent volume
# - Delete the pod
# - Verify data still exists in new pod
```

## Access Modes

PVs support different access modes:

- **ReadWriteOnce (RWO)**: Single node can mount read-write
- **ReadOnlyMany (ROX)**: Many nodes can mount read-only
- **ReadWriteMany (RWX)**: Many nodes can mount read-write

**Note:** Local volumes (what we use in KIND) only support RWO.

## Reclaim Policies

What happens to PV when PVC is deleted:

- **Retain**: PV remains with data intact (manual cleanup needed)
- **Delete**: PV and its data are deleted
- **Recycle**: Data is scrubbed, PV becomes available again (deprecated)

## Storage Classes in KIND

KIND uses the `standard` StorageClass by default, which provisions local storage automatically. This means you can skip creating PVs manually and just create PVCs!

```bash
# Check available storage classes
kubectl get storageclass
```

## Use Cases

### When to Use Persistent Storage

✅ **Yes:**
- Databases (PostgreSQL, MySQL, MongoDB)
- File uploads and user data
- Logs and metrics storage
- Caches that should survive restarts
- StatefulSets (Kafka, Elasticsearch, etc.)

❌ **No:**
- Stateless applications
- Temporary/cache data that can be rebuilt
- Configuration (use ConfigMaps instead)
- Secrets (use Secrets)

## Dynamic vs Static Provisioning

### Static Provisioning
1. Admin creates PV manually
2. User creates PVC
3. Kubernetes binds them

**Good for:** On-premises, specific hardware, testing

### Dynamic Provisioning
1. User creates PVC with StorageClass
2. Kubernetes automatically creates PV
3. Automatic binding

**Good for:** Cloud environments, production, scalability

KIND supports dynamic provisioning out of the box!

## Example: Data Persistence Test

```bash
# 1. Deploy app with storage
kubectl apply -f k8s/advanced/storage/deployment-with-storage.yaml

# 2. Write data
kubectl exec -n go-demo deployment/storage-demo -- sh -c "echo 'Hello from Kubernetes!' > /data/test.txt"

# 3. Read data
kubectl exec -n go-demo deployment/storage-demo -- cat /data/test.txt

# 4. Delete the pod (deployment will recreate it)
kubectl delete pod -n go-demo -l app=storage-demo

# 5. Wait for new pod
kubectl wait --for=condition=ready pod -n go-demo -l app=storage-demo --timeout=60s

# 6. Read data again - it's still there!
kubectl exec -n go-demo deployment/storage-demo -- cat /data/test.txt
```

## Troubleshooting

### PVC stuck in Pending
```bash
# Check events
kubectl describe pvc my-pvc -n go-demo

# Common causes:
# - No suitable PV available
# - No StorageClass configured
# - Insufficient capacity
```

### Pod stuck in ContainerCreating
```bash
# Check pod events
kubectl describe pod my-pod -n go-demo

# Common causes:
# - PVC not bound
# - Volume mount issues
# - Node affinity problems
```

### Data not persisting
```bash
# Verify PVC is used in pod
kubectl get pod my-pod -n go-demo -o yaml | grep -A 10 volumes

# Check if volume is actually mounted
kubectl exec my-pod -n go-demo -- mount | grep /data
```

## Best Practices

1. **Use StorageClasses** - Enable dynamic provisioning
2. **Set resource requests** - Specify exact size needed
3. **Choose right access mode** - RWO for most use cases
4. **Set reclaim policy** - Retain for production data
5. **Backup important data** - PVs can fail too
6. **Monitor usage** - Watch for full volumes
7. **Use StatefulSets** - For applications that need stable storage

## Learn More

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Dynamic Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

## Next Steps

1. ✅ Start with `pvc.yaml` and dynamic provisioning
2. 📚 Try the storage demo deployment
3. 🧪 Run `make test-storage` to see persistence in action
4. 🚀 Explore StatefulSets for advanced use cases
