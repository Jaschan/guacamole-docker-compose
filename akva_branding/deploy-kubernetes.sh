#!/bin/bash

# Fishtalk Custom Branding - Kubernetes Deployment Script
# Usage: ./deploy-kubernetes.sh [NAMESPACE]

set -e

NAMESPACE=${1:-"default"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚢 Deploying Fishtalk Custom Branding to Kubernetes"
echo "Namespace: $NAMESPACE"
echo "=================================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster"
    echo "Please ensure your kubectl context is configured correctly"
    exit 1
fi

echo "✅ Connected to cluster: $(kubectl config current-context)"

# Create namespace if it doesn't exist
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "📦 Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
else
    echo "✅ Using existing namespace: $NAMESPACE"
fi

# Create ConfigMap for CSS and HTML files
echo "📝 Creating ConfigMap for CSS and HTML files..."
kubectl create configmap guacamole-branding-files \
    --from-file=custom-branding.css="$SCRIPT_DIR/branding/branding-themepark.css" \
    --from-file=index.html="$SCRIPT_DIR/index/index.html" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMap for image files
echo "🖼️  Creating ConfigMap for image files..."
kubectl create configmap guacamole-branding-images \
    --from-file=custom-logo.png="$SCRIPT_DIR/branding/images/custom-logo.png" \
    --from-file=custom-footer.png="$SCRIPT_DIR/branding/images/custom-footer.png" \
    --from-file=logo-64.png="$SCRIPT_DIR/branding/images/custom-logo.png" \
    --from-file=logo-144.png="$SCRIPT_DIR/branding/images/custom-logo.png" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ ConfigMaps created successfully"

echo ""
echo "📋 Next steps for Kubernetes deployment:"
echo "=================================================="
echo "1. Update your existing Guacamole Deployment to include the volume mounts:"
echo ""
echo "   volumeMounts:"
echo "   - name: branding-css"
echo "     mountPath: /home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css"
echo "     subPath: custom-branding.css"
echo "   - name: branding-html"
echo "     mountPath: /home/guacamole/tomcat/webapps/guacamole/index.html"
echo "     subPath: index.html"
echo "   - name: branding-images"
echo "     mountPath: /home/guacamole/tomcat/webapps/guacamole/images/custom-logo.png"
echo "     subPath: custom-logo.png"
echo "   - name: branding-images"
echo "     mountPath: /home/guacamole/tomcat/webapps/guacamole/images/custom-footer.png"
echo "     subPath: custom-footer.png"
echo "   - name: branding-images"
echo "     mountPath: /home/guacamole/tomcat/webapps/guacamole/images/logo-64.png"
echo "     subPath: logo-64.png"
echo "   - name: branding-images"
echo "     mountPath: /home/guacamole/tomcat/webapps/guacamole/images/logo-144.png"
echo "     subPath: logo-144.png"
echo ""
echo "   volumes:"
echo "   - name: branding-css"
echo "     configMap:"
echo "       name: guacamole-branding-files"
echo "       items:"
echo "       - key: custom-branding.css"
echo "         path: custom-branding.css"
echo "   - name: branding-html"
echo "     configMap:"
echo "       name: guacamole-branding-files"
echo "       items:"
echo "       - key: index.html"
echo "         path: index.html"
echo "   - name: branding-images"
echo "     configMap:"
echo "       name: guacamole-branding-images"
echo ""
echo "2. Apply your updated deployment:"
echo "   kubectl apply -f your-guacamole-deployment.yaml -n $NAMESPACE"
echo ""
echo "3. Or use the provided example deployment:"
echo "   kubectl apply -f kubernetes-deployment.yaml -n $NAMESPACE"
echo ""
echo "🔍 Verification commands:"
echo "   kubectl get configmaps -n $NAMESPACE | grep branding"
echo "   kubectl get pods -n $NAMESPACE -l app=guacamole"
echo "   kubectl logs -n $NAMESPACE -l app=guacamole"
echo ""
echo "🔧 Rollback commands (if needed):"
echo "   kubectl delete configmap guacamole-branding-files -n $NAMESPACE"
echo "   kubectl delete configmap guacamole-branding-images -n $NAMESPACE"
echo "   kubectl rollout undo deployment/guacamole -n $NAMESPACE"
