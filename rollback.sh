#!/bin/bash

set -e  # Exit if any command fails

echo "🔄 Checking v2 container status..."

# Stop and remove v2 if it exists
if docker ps -a | grep -q myapp-v2; then
    echo "⚠️ v2 container found. Stopping and removing it..."
    docker stop myapp-v2 && docker rm myapp-v2
else
    echo "✅ No v2 container found. Skipping removal."
fi

# Check if v1 is running
if docker ps | grep -q myapp-v1; then
    echo "✅ v1 is already running!"
else
    echo "🚀 v1 is not running. Starting it now..."
    docker run -d --name myapp-v1 -p 5000:80 myapp:v1 || { echo "❌ Failed to start v1"; exit 1; }
fi

# Revert Nginx to point back to v1
echo "🔄 Rolling back Nginx configuration..."
sed -i 's/myapp-v2/myapp-v1/' /etc/nginx/nginx.conf || { echo "❌ Failed to revert Nginx config"; exit 1; }
systemctl reload nginx || { echo "❌ Failed to reload Nginx"; exit 1; }

# Send Slack notification
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    echo "📢 Sending rollback alert to Slack..."
    curl -X POST -H 'Content-type: application/json' --data '{"text":"🚨 Deployment failed! Rolled back to v1."}' "$SLACK_WEBHOOK_URL"
else
    echo "⚠️ SLACK_WEBHOOK_URL not set. Skipping Slack alert."
fi

echo "✅ Rollback completed successfully!"
exit 0
