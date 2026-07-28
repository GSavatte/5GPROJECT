#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Copying optimization script into the db container..."
docker cp "$SCRIPT_DIR/k_means_optimization.js" db:/tmp/k_means_optimization.js

echo "[INFO] Executing K-means optimization..."
docker exec -i db mongosh open5gs --quiet /tmp/k_means_optimization.js

echo "[INFO] Completed. The affected UEs will be reconnected automatically if mobility_controller.sh is running."