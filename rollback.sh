#!/bin/bash

set -ex  # 'e' stops on error, 'x' prints each command before execution

echo "🔄 Pulling the latest v2 image..."
docker pull $DOCKER_USERNAME/my-app:v2 || { echo "❌ Failed to pull v2 image"; exit 1; }

echo "🚀 Running new container (v2)..."
docker run -d --name my-app-v2 -p 5001:5000 $DOCKER_USERNAME/my-app:v2 || { echo "❌ Failed to start v2 container"; exit 1; }

echo "🔄 Updating Nginx config to point to v2..."
sed -i 's/my-app-v1/my-app-v2/' /etc/nginx/nginx.conf || { echo "❌ Failed to update Nginx config"; exit 1; }
systemctl reload nginx || { echo "❌ Failed to reload Nginx"; exit 1; }

echo "🩺 Waiting for v2 health check..."
sleep 10
if curl -f http://localhost:5001/health; then
    echo "✅ v2 is healthy. Removing v1..."
    docker stop my-app-v1 && docker rm my-app-v1 || { echo "❌ Failed to remove v1"; exit 1; }
    echo "🎉 Deployment successful!"
else
    echo "🚨 Deployment failed. Rolling back to v1..."
    docker stop my-app-v2 && docker rm my-app-v2 || { echo "❌ Failed to remove v2"; exit 1; }
    sed -i 's/my-app-v2/my-app-v1/' /etc/nginx/nginx.conf || { echo "❌ Failed to revert Nginx config"; exit 1; }
    systemctl reload nginx || { echo "❌ Failed to reload Nginx after rollback"; exit 1; }
    curl -X POST -H 'Content-type: application/json' --data '{"text":"🚨 Deployment failed! Rolling back to v1."}' $SLACK_WEBHOOK_URL
    exit 1
fi
