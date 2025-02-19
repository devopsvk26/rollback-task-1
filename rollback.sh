#!/bin/bash

echo "Checking v2 container status..."

# Check if v2 exists
if docker ps -a | grep -q myapp-v2; then
    echo "v2 container found. Stopping and removing it..."
    docker stop myapp-v2
    docker rm myapp-v2
else
    echo "No v2 container found. Skipping removal."
fi

# Check if v1 is running
if docker ps | grep -q myapp-v1; then
    echo "v1 is already running!"
else
    echo "v1 is not running. Starting it now..."
    docker run -d --name myapp-v1 -p 5000:80 myapp:v1
fi
