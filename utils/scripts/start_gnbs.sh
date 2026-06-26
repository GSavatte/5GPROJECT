#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

read -p "Combien d'antennes gNB déployer ? " NUM_GNBS

echo "Génération des fichiers de configuration pour $NUM_GNBS antennes gNB..."

COMPOSE_FILE="$PROJECT_ROOT/compose-files/docker-compose.gnbs.yaml"
CONFIG_DIR="$PROJECT_ROOT/config-files/generated_gnbs"

mkdir -p $CONFIG_DIR

echo "services:" > $COMPOSE_FILE

for i in $(seq 1 $NUM_GNBS); do
    HOSTNAME="gnb${i}"
    CONFIG_FILE="${CONFIG_DIR}/${HOSTNAME}.yaml"
    
    sed -e "s/GNB_ID_PLACEHOLDER/$i/g" "$PROJECT_ROOT/config-files/templates/gnb-template.yaml" > $CONFIG_FILE
    
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
        depends_on:
        - amf
        - smf1
        - smf2
        - smf3
        - pcf
        - udr
EOF
done

echo "" >> $COMPOSE_FILE
echo "configs:" >> $COMPOSE_FILE

for i in $(seq 1 $NUM_GNBS); do
    GNB_NAME="gnb${i}"

    cat << EOF >> $COMPOSE_FILE
    ${GNB_NAME}_config:
        file: ${CONFIG_DIR}/${GNB_NAME}.yaml
EOF

done

echo "Fichiers de configuration pour $NUM_GNBS antennes gNB générés avec succès."