#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📡 Copie du script d'optimisation dans le conteneur db..."
docker cp "$SCRIPT_DIR/k_means_optimization.js" db:/tmp/k_means_optimization.js

echo "🚀 Exécution de l'optimisation K-means..."
docker exec -i db mongosh open5gs --quiet /tmp/k_means_optimization.js

echo "✅ Terminé. Les UE concernées seront reconnectées automatiquement si mobility_controller.sh est en cours d'exécution."