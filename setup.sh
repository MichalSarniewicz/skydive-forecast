#!/bin/bash
set -e

echo ""
echo "========================================"
echo " Skydive Forecast - Environment Setup"
echo "========================================"
echo ""

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PARENT_DIR="$(dirname "$BASE_DIR")"

echo "Cloning repositories into:"
echo "$PARENT_DIR"
echo ""

cd "$PARENT_DIR"

TOTAL=6
COUNT=0

clone_repo() {
  COUNT=$((COUNT+1))
  echo "[$COUNT/$TOTAL] Cloning $1..."
  git clone "$2"
  echo "[$COUNT/$TOTAL] $1 cloned successfully"
  echo ""
}

clone_repo "Gateway" "https://github.com/michalsarniewicz/skydive-forecast-gateway.git"
clone_repo "User Service" "https://github.com/michalsarniewicz/skydive-forecast-user-service.git"
clone_repo "Analysis Service" "https://github.com/michalsarniewicz/skydive-forecast-analysis-service.git"
clone_repo "Location Service" "https://github.com/michalsarniewicz/skydive-forecast-location-service.git"
clone_repo "Config Server" "https://github.com/michalsarniewicz/skydive-forecast-config-server.git"
clone_repo "Service Config" "https://github.com/michalsarniewicz/skydive-forecast-svc-config.git"

echo "========================================"
echo " Setup completed successfully"
echo "========================================"
echo ""
echo "Run: make start (or docker-compose up --build)"
echo ""
