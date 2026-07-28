#!/bin/bash

echo "==================================================="
echo "[INFO] Starting the mobility controller for UE handovers..."
echo "==================================================="

# ------------------------------------------------------------------------------
# PHASE 1: INITIALIZATION AND DNS RESOLUTION
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

NUM_GNBS=$(ls -1 $PROJECT_ROOT/config-files/gnb/generated/ | wc -l)
echo "[INFO] Number of detected gNBs: $NUM_GNBS"
echo "[INFO] Database ready. Resolving antennas..."

declare -A GNB_HOSTS

for id in $(seq 1 $NUM_GNBS); do
  HOSTNAME=$(printf "gnb%02d" $id)
  FQDN="${HOSTNAME}.ueransim.org"
  RESOLVED=""
  MAX_RETRIES=15
  COUNT=0

  while [ -z "$RESOLVED" ] && [ $COUNT -lt $MAX_RETRIES ]; do
    RESOLVED=$(docker exec -i ue-loadtester getent hosts "$FQDN" | awk '{ print $1 }' | tr -d '\r' | head -n 1)

    if [ -z "$RESOLVED" ]; then
       echo "[INFO] Waiting for the network for $HOSTNAME (Attempt $((COUNT+1))/$MAX_RETRIES)..."
       sleep 1
       COUNT=$((COUNT+1))
    fi
  done

  if [ -z "$RESOLVED" ]; then
     echo "[ERROR] DNS not found for $HOSTNAME after $MAX_RETRIES seconds."
     GNB_HOSTS[$id]=$FQDN
  else
     echo "[INFO] Antenna $HOSTNAME reachable via : $FQDN (Current IP : $RESOLVED)"
     GNB_HOSTS[$id]=$FQDN
  fi
done

echo "[INFO] Network initialization completed. Waiting for movements..."
echo "---------------------------------------------------"


while true; do
    PENDING_UES=$(docker exec -i db mongosh open5gs --quiet --eval "
        db.subscribers.find({ handover_status: 'pending' }).forEach(function(ue) {
            print(ue.imsi + ',' + ue.target_gnb);
        });
    ")

    if [ ! -z "$PENDING_UES" ]; then
        for line in $PENDING_UES; do
            RAW_IMSI=$(echo "$line" | cut -d',' -f1)
            IMSI="imsi-${RAW_IMSI}"
            TARGET_GNB_ID=$(echo "$line" | cut -d',' -f2)

            TARGET_HOST=${GNB_HOSTS[$TARGET_GNB_ID]}
            TARGET_HOSTNAME=$(printf "gnb%02d" $TARGET_GNB_ID)

            if [ -z "$TARGET_HOST" ]; then
                echo "[WARNING] Error: The gNB ID '$TARGET_GNB_ID' has no registered hostname. Handover ignored for $IMSI."
                continue
            fi

            echo "[INFO] Switching $IMSI to $TARGET_HOSTNAME (ID: $TARGET_GNB_ID - Host: $TARGET_HOST)..."

            NEW_SEARCH_LIST="$TARGET_HOST"

            docker exec ue-loadtester /UERANSIM/nr-cli "$IMSI" -e "deregister" >/dev/null 2>&1
            sleep 1

            docker exec ue-loadtester pkill -f "nr-ue -c /tmp/ue-${IMSI}.yaml"
            sleep 0.5

            docker exec ue-loadtester bash -c \
                "sed -i '/gnbSearchList:/,/^[a-zA-Z]/{/^[[:space:]]*- /d}' /tmp/ue-${IMSI}.yaml && \
                sed -i '/gnbSearchList:/a\  - ${TARGET_HOST}' /tmp/ue-${IMSI}.yaml"

            docker exec -d ue-loadtester bash -c \
                "/UERANSIM/nr-ue -c /tmp/ue-${IMSI}.yaml > /tmp/logs-${IMSI}.txt 2>&1"

            docker exec -i db mongosh open5gs --quiet --eval "
                db.subscribers.updateOne(
                    { imsi: '$RAW_IMSI' },
                    { \$set: { current_gnb: '$TARGET_GNB_ID', handover_status: 'completed' } }
                );
            " >/dev/null 2>&1

            echo "[INFO] Target UE $IMSI redeployed successfully on $TARGET_HOSTNAME."
        done
        echo "---------------------------------------------------"
    fi

    sleep 1
done