#!/bin/bash
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATUS_FILE="$ROOT/shared_flags/status.json"

echo '{"status": "deploying"}' > "$STATUS_FILE"

echo "Re-deploying the 5G Core Network..."
docker compose -f "$ROOT/compose-files/docker-compose.loadtest.yaml" down
docker compose -f "$ROOT/compose-files/docker-compose.gnbs.yaml" down

docker stop ue-loadtester >/dev/null 2>&1
docker rm -f ue-loadtester >/dev/null 2>&1

echo "Reading the number of gNBs and UEs from the database..."

NB_GNBS=$(docker exec -i db mongosh open5gs --quiet --eval "db.gnbs.countDocuments({})" | grep -o '[0-9]\+')
NB_UES=$(docker exec -i db mongosh open5gs --quiet --eval "db.subscribers.countDocuments({})" | grep -o '[0-9]\+')

echo "Re-deploying the 5G Core Network with $NB_GNBS gNBs and $NB_UES UEs..."

sudo bash "$ROOT/scripts/start_gnbs.sh" "$NB_GNBS"

echo "Starting gNBs..."
docker compose -f "$ROOT/compose-files/docker-compose.gnbs.yaml" up -d
sleep 5

echo "Deploying $NB_UES UEs..."
docker compose -f "$ROOT/compose-files/docker-compose.loadtest.yaml" --env-file="$ROOT/.env" run -d --name ue-loadtester --rm -e NB_UES="$NB_UES" -e loadtest="n" ue-loadtester
echo '{"status": "ready"}' > "$STATUS_FILE"
echo "5G Network re-deployed successfully!"