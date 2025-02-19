#!/bin/bash

set -e  # Exit on any error
trap rollback ERR  # Trigger rollback if an error occurs

# Variables
OLD_CONTAINER="app_v1"
NEW_CONTAINER="app_v2"
PORT_OLD=5000
PORT_NEW=5001
IMAGE="my-dockerhub-repo/my-app:v2"

rollback() {
  echo "Rollback triggered..."
  # Start the old container if stopped
  docker ps -a | grep -q "$OLD_CONTAINER" || docker start $OLD_CONTAINER
  # Stop and remove the new container
  docker stop $NEW_CONTAINER || true
  docker rm $NEW_CONTAINER || true
  echo "Rollback completed. Old container ($OLD_CONTAINER) is active."
}

# Step 1: Stop any existing new containers
echo "Cleaning up old attempts..."
docker stop $NEW_CONTAINER || true
docker rm $NEW_CONTAINER || true

# Step 2: Run the new container
echo "Deploying new container ($NEW_CONTAINER)..."
docker run -d --name $NEW_CONTAINER -p $PORT_NEW:5000 $IMAGE

# Step 3: Update the reverse proxy
echo "Updating reverse proxy to route traffic to $NEW_CONTAINER..."
cat > /etc/nginx/conf.d/my_app.conf <<EOL
server {
    listen 80;

    location / {
        proxy_pass http://localhost:$PORT_NEW;  # Route traffic to the new container
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOL

nginx -s reload

# Step 4: Validate the new deployment
echo "Validating the new container..."
sleep 5
curl -f http://localhost:$PORT_NEW || (echo "Validation failed!" && exit 1)

# Step 5: Remove the old container
echo "Validation successful. Removing old container ($OLD_CONTAINER)..."
docker stop $OLD_CONTAINER || true
docker rm $OLD_CONTAINER || true

echo "Deployment completed successfully!"
