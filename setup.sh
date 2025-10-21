#!/bin/bash

echo "Setting up Skydive Forecast..."

# Clone microservices
git clone https://github.com/user/skydive-forecast-gateway.git
git clone https://github.com/user/skydive-forecast-user-service.git
git clone https://github.com/user/skydive-forecast-analysis-service.git
git clone https://github.com/user/skydive-forecast-location-service.git

echo "Setup complete"
echo "Run: docker-compose up --build"