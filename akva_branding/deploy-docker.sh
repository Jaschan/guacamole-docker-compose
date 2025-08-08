#!/bin/bash

# Fishtalk Custom Branding - Docker Deployment Script
# Usage: ./deploy-docker.sh CONTAINER_NAME

set -e

CONTAINER_NAME=${1:-"guacamole"}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎨 Deploying Fishtalk Custom Branding to container: $CONTAINER_NAME"
echo "=================================================="

# Check if container exists
if ! docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "❌ Error: Container '$CONTAINER_NAME' not found"
    echo "Available containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

# Check if container is running
if ! docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "⚠️  Warning: Container '$CONTAINER_NAME' is not running"
    read -p "Do you want to start it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker start $CONTAINER_NAME
        echo "✅ Container started"
        sleep 3
    else
        echo "❌ Deployment cancelled - container must be running"
        exit 1
    fi
fi

echo "📁 Deploying files..."

# Create backup inside container
echo "Creating backup..."
docker exec $CONTAINER_NAME mkdir -p /tmp/guacamole-backup-$(date +%Y%m%d_%H%M%S)
docker exec $CONTAINER_NAME cp -f /home/guacamole/tomcat/webapps/guacamole/index.html /tmp/guacamole-backup-$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
docker exec $CONTAINER_NAME cp -f /home/guacamole/tomcat/webapps/guacamole/images/logo-64.png /tmp/guacamole-backup-$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
docker exec $CONTAINER_NAME cp -f /home/guacamole/tomcat/webapps/guacamole/images/logo-144.png /tmp/guacamole-backup-$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true

# Deploy CSS file
echo "Deploying CSS..."
docker cp "$SCRIPT_DIR/branding/branding-themepark.css" $CONTAINER_NAME:/home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css

# Deploy images
echo "Deploying images..."
docker cp "$SCRIPT_DIR/branding/images/custom-logo.png" $CONTAINER_NAME:/home/guacamole/tomcat/webapps/guacamole/images/custom-logo.png
docker cp "$SCRIPT_DIR/branding/images/custom-footer.png" $CONTAINER_NAME:/home/guacamole/tomcat/webapps/guacamole/images/custom-footer.png

# Deploy favicon files (using custom logo)
echo "Deploying favicon..."
docker cp "$SCRIPT_DIR/branding/images/custom-logo.png" $CONTAINER_NAME:/home/guacamole/tomcat/webapps/guacamole/images/logo-64.png
docker cp "$SCRIPT_DIR/branding/images/custom-logo.png" $CONTAINER_NAME:/home/guacamole/tomcat/webapps/guacamole/images/logo-144.png

# Deploy modified index.html
echo "Deploying index.html..."
docker cp "$SCRIPT_DIR/index/index.html" $CONTAINER_NAME:/home/guacamole/tomcat/webapps/guacamole/index.html

# Set permissions
echo "Setting permissions..."
docker exec -u root $CONTAINER_NAME chown guacamole:guacamole /home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css
docker exec -u root $CONTAINER_NAME chown guacamole:guacamole /home/guacamole/tomcat/webapps/guacamole/index.html
docker exec -u root $CONTAINER_NAME chown guacamole:guacamole /home/guacamole/tomcat/webapps/guacamole/images/custom-logo.png
docker exec -u root $CONTAINER_NAME chown guacamole:guacamole /home/guacamole/tomcat/webapps/guacamole/images/custom-footer.png
docker exec -u root $CONTAINER_NAME chown guacamole:guacamole /home/guacamole/tomcat/webapps/guacamole/images/logo-64.png
docker exec -u root $CONTAINER_NAME chown guacamole:guacamole /home/guacamole/tomcat/webapps/guacamole/images/logo-144.png

echo "🔄 Restarting container..."
docker restart $CONTAINER_NAME

echo "⏳ Waiting for container to be ready..."
sleep 10

# Verify deployment
echo "🔍 Verifying deployment..."
if docker exec $CONTAINER_NAME test -f /home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css; then
    echo "✅ CSS file deployed successfully"
else
    echo "❌ CSS file deployment failed"
fi

if docker exec $CONTAINER_NAME test -f /home/guacamole/tomcat/webapps/guacamole/images/custom-logo.png; then
    echo "✅ Logo file deployed successfully"
else
    echo "❌ Logo file deployment failed"
fi

if docker exec $CONTAINER_NAME grep -q "Fishtalk" /home/guacamole/tomcat/webapps/guacamole/index.html 2>/dev/null; then
    echo "✅ Index.html updated successfully"
else
    echo "❌ Index.html update failed"
fi

echo ""
echo "🎉 Deployment completed!"
echo "=================================================="
echo "✅ Custom branding deployed to: $CONTAINER_NAME"
echo "🌐 Changes include:"
echo "   • Browser title: 'Fishtalk'"
echo "   • Custom logo (25% larger)"
echo "   • Turquoise buttons (#00BBE4)"
echo "   • Dark theme with custom gradients"
echo "   • Custom login screen branding"
echo ""
echo "📋 Next steps:"
echo "   1. Open your Guacamole URL in browser"
echo "   2. Hard refresh (Ctrl+F5) to clear cache"
echo "   3. Verify the branding appears correctly"
echo "   4. Test login functionality"
echo ""
echo "🔧 Rollback command (if needed):"
echo "   docker exec $CONTAINER_NAME rm /home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css"
echo "   docker restart $CONTAINER_NAME"
