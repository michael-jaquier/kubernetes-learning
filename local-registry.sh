#!/bin/bash

# Script to create a local Docker registry for KIND
# This registry runs as a Docker container and is accessible at localhost:5001

set -e

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

echo "🚀 Setting up local Docker registry for KIND..."

# Check if registry already exists
if [ "$(docker ps -a -q -f name=${REGISTRY_NAME})" ]; then
    echo "📦 Registry '${REGISTRY_NAME}' already exists"

    # Check if it's running
    if [ "$(docker ps -q -f name=${REGISTRY_NAME})" ]; then
        echo "✅ Registry is already running at localhost:${REGISTRY_PORT}"
    else
        echo "▶️  Starting existing registry..."
        docker start ${REGISTRY_NAME}
        echo "✅ Registry started at localhost:${REGISTRY_PORT}"
    fi
else
    echo "📦 Creating new registry container..."
    docker run -d \
        --name ${REGISTRY_NAME} \
        --restart=always \
        -p 127.0.0.1:${REGISTRY_PORT}:5000 \
        registry:2
    echo "✅ Registry created and running at localhost:${REGISTRY_PORT}"
fi

# Connect the registry to the KIND network if not already connected
echo "🔗 Connecting registry to KIND network..."
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' ${REGISTRY_NAME})" = 'null' ]; then
    docker network connect kind ${REGISTRY_NAME} 2>/dev/null || true
fi

# Document the local registry
# This creates a configmap in the cluster that documents the local registry
echo "📝 Documenting local registry in cluster..."
cat <<EOF | kubectl apply -f - 2>/dev/null || true
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo ""
echo "✨ Local registry setup complete!"
echo ""
echo "Registry Details:"
echo "  - Container name: ${REGISTRY_NAME}"
echo "  - Host address: localhost:${REGISTRY_PORT}"
echo "  - Cluster address: kind-registry:5001"
echo ""
echo "Usage:"
echo "  docker tag my-image:latest localhost:${REGISTRY_PORT}/my-image:latest"
echo "  docker push localhost:${REGISTRY_PORT}/my-image:latest"
echo ""
