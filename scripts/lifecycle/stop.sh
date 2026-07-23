#!/bin/bash

echo "Arrêt complet du réseau 5G et de tous les conteneurs associés..."

docker stop ue-loadtester >/dev/null 2>&1
docker rm -f ue-loadtester >/dev/null 2>&1

docker compose --env-file=.env -f compose-files/docker-compose.gnbs.yaml down
docker compose --env-file=.env -f compose-files/docker-compose.loadtest.yaml down
docker compose --env-file=.env -f compose-files/docker-compose.monitoring.yaml down
sudo bash scripts/lifecycle/clear.sh
docker compose --env-file=.env -f compose-files/docker-compose.yml down --remove-orphans

echo "Tous les conteneurs associés au réseau ont été stoppés."

