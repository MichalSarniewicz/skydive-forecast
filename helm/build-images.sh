#!/bin/bash

# Build Docker images for Kubernetes deployment
set -e

echo "Building Docker images for Skydive Forecast..."

# Config Server
echo "Building config-server..."
cd ../skydive-forecast-config-server
docker build -t skydive-forecast/config-server:latest .

# Gateway
echo "Building gateway..."
cd ../skydive-forecast-gateway
docker build -t skydive-forecast/gateway:latest .

# User Service
echo "Building user-service..."
cd ../skydive-forecast-user-service
docker build -t skydive-forecast/user-service:latest .

# Analysis Service
echo "Building analysis-service..."
cd ../skydive-forecast-analysis-service
docker build -t skydive-forecast/analysis-service:latest .

# Location Service
echo "Building location-service..."
cd ../skydive-forecast-location-service
docker build -t skydive-forecast/location-service:latest .

echo "All images built successfully!"
echo ""
echo "Images:"
docker images | grep skydive-forecast
