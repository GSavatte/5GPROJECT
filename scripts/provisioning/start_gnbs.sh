#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

NUM_GNBS=$1

echo "[INFO] Generating configuration files for $NUM_GNBS gNB antennas..."

COMPOSE_FILE="$PROJECT_ROOT/compose-files/docker-compose.gnbs.yaml"
CONFIG_DIR="$PROJECT_ROOT/config-files/gnb/generated"

mkdir -p $CONFIG_DIR

rm -f $COMPOSE_FILE
rm -f $CONFIG_DIR/*.yaml

echo "services:" > $COMPOSE_FILE

for i in $(seq 1 $NUM_GNBS); do
    HOSTNAME=$(printf "gnb%02d" $i)
    CONFIG_FILE="${CONFIG_DIR}/${HOSTNAME}.yaml"
    
    sed -e "s/GNB_ID_PLACEHOLDER/$i/g" -e "s/GNB_HOSTNAME_PLACEHOLDER/${HOSTNAME}/g" "$PROJECT_ROOT/config-files/gnb/templates/gnb-template.yaml" > $CONFIG_FILE 
    
    cat <<EOF >> $COMPOSE_FILE
    $HOSTNAME:
        container_name: $HOSTNAME
        image: "ghcr.io/borjis131/gnb:v3.2.7"
        command: "-c /UERANSIM/config/${HOSTNAME}.yaml"
        networks:
            open5gs:
                aliases:
                - ${HOSTNAME}.ueransim.org
        configs:
            - source: ${HOSTNAME}_config
              target: /UERANSIM/config/${HOSTNAME}.yaml
EOF
done

echo "" >> $COMPOSE_FILE
echo "configs:" >> $COMPOSE_FILE

for i in $(seq 1 $NUM_GNBS); do
    GNB_NAME=$(printf "gnb%02d" $i)

    cat << EOF >> $COMPOSE_FILE
    ${GNB_NAME}_config:
        file: ${CONFIG_DIR}/${GNB_NAME}.yaml
EOF

done

echo "" >> "$COMPOSE_FILE"
echo "networks:" >> "$COMPOSE_FILE"
echo "  open5gs:" >> "$COMPOSE_FILE"
echo "    external: true" >> "$COMPOSE_FILE"

echo "[INFO] Configuration files for $NUM_GNBS gNB antennas generated successfully."