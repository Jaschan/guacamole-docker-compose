# Fishtalk Custom Branding - Production Deployment Guide

## Overview
This guide explains how to deploy the custom Fishtalk branding to your production Guacamole instance.

## Files to Deploy

- `branding/branding-themepark.css` - Main CSS file
- `branding/images/custom-logo.png` - Login screen logo
- `branding/images/custom-footer.png` - Footer image
- `index/index.html` - Modified HTML with title enforcement

## Deployment Methods

### Docker Container Deployment

#### Step 1: Copy Files to Container
```bash
# Copy CSS file
docker cp branding/branding-themepark.css YOUR_GUACAMOLE_CONTAINER:/home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css

# Copy logo files
docker cp branding/images/custom-logo.png YOUR_GUACAMOLE_CONTAINER:/home/guacamole/tomcat/webapps/guacamole/images/custom-logo.png
docker cp branding/images/custom-footer.png YOUR_GUACAMOLE_CONTAINER:/home/guacamole/tomcat/webapps/guacamole/images/custom-footer.png

# Copy favicon files (using custom logo)
docker cp branding/images/custom-logo.png YOUR_GUACAMOLE_CONTAINER:/home/guacamole/tomcat/webapps/guacamole/images/logo-64.png
docker cp branding/images/custom-logo.png YOUR_GUACAMOLE_CONTAINER:/home/guacamole/tomcat/webapps/guacamole/images/logo-144.png

# Copy modified index.html (with title enforcement)
docker cp index/index.html YOUR_GUACAMOLE_CONTAINER:/home/guacamole/tomcat/webapps/guacamole/index.html
```

#### Step 2: Restart Container
```bash
docker restart YOUR_GUACAMOLE_CONTAINER
```

### Kubernetes Deployment

#### Step 1: Create ConfigMap for Static Files
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: guacamole-branding
  namespace: your-namespace
data:
  custom-branding.css: |
    # Content of branding/branding-themepark.css goes here
  index.html: |
    # Content of index/index.html goes here
```

#### Step 2: Create ConfigMap for Images
```bash
# Create ConfigMap from image files
kubectl create configmap guacamole-images \
  --from-file=custom-logo.png=branding/images/custom-logo.png \
  --from-file=custom-footer.png=branding/images/custom-footer.png \
  --from-file=logo-64.png=branding/images/custom-logo.png \
  --from-file=logo-144.png=branding/images/custom-logo.png \
  -n your-namespace
```

#### Step 3: Mount ConfigMaps in Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guacamole
spec:
  template:
    spec:
      containers:
      - name: guacamole
        image: guacamole/guacamole:latest
        volumeMounts:
        - name: branding-css
          mountPath: /home/guacamole/tomcat/webapps/guacamole/app/custom-branding.css
          subPath: custom-branding.css
        - name: branding-index
          mountPath: /home/guacamole/tomcat/webapps/guacamole/index.html
          subPath: index.html
        - name: branding-images
          mountPath: /home/guacamole/tomcat/webapps/guacamole/images/
      volumes:
      - name: branding-css
        configMap:
          name: guacamole-branding
      - name: branding-index
        configMap:
          name: guacamole-branding
      - name: branding-images
        configMap:
          name: guacamole-images
```

### VM/Server Deployment

#### Step 1: Locate Guacamole Installation
```bash
# Find your Guacamole web directory (typically one of these):
# /var/lib/tomcat*/webapps/guacamole/
# /opt/tomcat/webapps/guacamole/
# /usr/share/tomcat*/webapps/guacamole/
```

#### Step 2: Backup Original Files
```bash
# Create backup directory
mkdir -p /opt/guacamole-backup/$(date +%Y%m%d_%H%M%S)

# Backup original files
cp /path/to/guacamole/app/custom-branding.css /opt/guacamole-backup/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
cp /path/to/guacamole/index.html /opt/guacamole-backup/$(date +%Y%m%d_%H%M%S)/
cp /path/to/guacamole/images/logo-*.png /opt/guacamole-backup/$(date +%Y%m%d_%H%M%S)/
```

#### Step 3: Deploy Files
```bash
# Copy CSS file
cp branding/branding-themepark.css /path/to/guacamole/app/custom-branding.css

# Copy images
cp branding/images/custom-logo.png /path/to/guacamole/images/
cp branding/images/custom-footer.png /path/to/guacamole/images/
cp branding/images/custom-logo.png /path/to/guacamole/images/logo-64.png
cp branding/images/custom-logo.png /path/to/guacamole/images/logo-144.png

# Copy index.html
cp index/index.html /path/to/guacamole/index.html

# Set proper permissions
chown -R tomcat:tomcat /path/to/guacamole/
chmod 644 /path/to/guacamole/app/custom-branding.css
chmod 644 /path/to/guacamole/index.html
chmod 644 /path/to/guacamole/images/*
```

#### Step 4: Restart Tomcat
```bash
# Ubuntu/Debian
sudo systemctl restart tomcat9

# CentOS/RHEL
sudo systemctl restart tomcat

# Or restart the specific service name
sudo systemctl restart YOUR_TOMCAT_SERVICE
```

## Verification

### Web Interface
- Navigate to your Guacamole URL
- Verify browser tab shows "Fishtalk" title
- Check login page shows custom branding
- Test login functionality

### File Deployment
```bash
# Verify files exist
ls -la /path/to/guacamole/app/custom-branding.css
ls -la /path/to/guacamole/images/custom-logo.png
ls -la /path/to/guacamole/index.html

# Check CSS is loaded
curl -s YOUR_GUACAMOLE_URL/guacamole/app/custom-branding.css | grep -i "#00BBE4"
```

## Troubleshooting

### Issue: Changes Not Visible
**Solution:**
1. Clear browser cache (Ctrl+F5)
2. Try incognito/private browsing mode
3. Check if CSS file is loading: `curl YOUR_URL/guacamole/app/custom-branding.css`

### Issue: Login Broken
**Solution:**
1. Restore original index.html from backup
2. Check Tomcat logs: `tail -f /var/log/tomcat*/catalina.out`
3. Verify file permissions are correct

### Issue: Images Not Loading
**Solution:**
1. Check image file paths and permissions
2. Verify image files were copied correctly
3. Check browser developer tools for 404 errors

## Rollback Procedure

### Quick Rollback
```bash
# Restore from backup
cp /opt/guacamole-backup/TIMESTAMP/index.html /path/to/guacamole/
cp /opt/guacamole-backup/TIMESTAMP/logo-*.png /path/to/guacamole/images/
rm /path/to/guacamole/app/custom-branding.css  # Remove custom CSS

# Restart service
sudo systemctl restart tomcat9
```

## Production Notes

- Always backup original files before deployment
- Test in staging environment first
- If using CDN, purge cache after deployment
- Deploy to all instances in HA environments
- Monitor logs during deployment
