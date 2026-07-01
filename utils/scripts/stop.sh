#!/bin/bash

echo "Arrêt complet du réseau 5G et de tous les conteneurs associés..."
docker compose --env-file=.env -f compose-files/docker-compose.gnbs.yaml down
docker compose --env-file=.env -f compose-files/docker-compose.loadtest.yaml down
docker compose --env-file=.env -f compose-files/docker-compose.monitoring.yaml down
sudo bash utils/scripts/clear.sh
docker compose --env-file=.env -f compose-files/docker-compose.yml down

echo "Tous les conteneurs associés au réseau ont été stoppés."

