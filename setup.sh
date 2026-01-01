#!/bin/bash

echo "Setting up Skydive Forecast..."

# Clone microservices
git clone https://github.com/michalsarniewicz/skydive-forecast-gateway.git
git clone https://github.com/michalsarniewicz/skydive-forecast-user-service.git
git clone https://github.com/michalsarniewicz/skydive-forecast-analysis-service.git
git clone https://github.com/michalsarniewicz/skydive-forecast-location-service.git
git clone https://github.com/michalsarniewicz/skydive-forecast-config-server.git
git clone https://github.com/michalsarniewicz/skydive-forecast-svc-config.git

echo "Setup complete"
echo "Run: docker-compose up --build"