#!/bin/bash

echo "[INFO] Stopping the entire 5G network and all associated containers..."

docker stop ue-loadtester >/dev/null 2>&1
docker rm -f ue-loadtester >/dev/null 2>&1

docker compose --env-file=.env -f compose-files/docker-compose.gnbs.yaml down
docker compose --env-file=.env -f compose-files/docker-compose.loadtest.yaml down
docker compose --env-file=.env -f compose-files/docker-compose.monitoring.yaml down
sudo bash scripts/lifecycle/clear.sh
docker compose --env-file=.env -f compose-files/docker-compose.yml down --remove-orphans

if [ -f shared_flags/sdn-controller.pid ]; then
    kill "$(cat shared_flags/sdn-controller.pid)" 2>/dev/null
    rm -f shared_flags/sdn-controller.pid
fi

echo "[INFO] All containers associated with the network have been stopped."
