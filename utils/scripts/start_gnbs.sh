#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

read -p "Combien d'antennes gNB déployer ? " NUM_GNBS

echo "Génération des fichiers de configuration pour $NUM_GNBS antennes gNB..."

COMPOSE_FILE="$PROJECT_ROOT/compose-files/docker-compose.gnbs.yaml"
CONFIG_DIR="$PROJECT_ROOT/config-files/generated_gnbs"

mkdir -p $CONFIG_DIR

rm -f $COMPOSE_FILE
rm -f $CONFIG_DIR/*.yaml

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

echo "" >> "$COMPOSE_FILE"
echo "networks:" >> "$COMPOSE_FILE"
echo "  open5gs:" >> "$COMPOSE_FILE"
echo "    external: true" >> "$COMPOSE_FILE"

echo "Fichiers de configuration pour $NUM_GNBS antennes gNB générés avec succès."

echo "Insertion des gNBs dans la base de données..."

for i in $(seq 1 $NUM_GNBS); do
    GNB_NAME="gnb${i}"
    GNB_ID=$i

    SEED1=$((10#$(date +%N) + RANDOM))
    SEED2=$((10#$(date +%N) + RANDOM))

    POSX=$(awk -v base=48.117883 -v seed="$SEED1" 'BEGIN {srand(seed); printf "%.6f", base + ((rand() - 0.5) * 0.01)}')
    POSY=$(awk -v base=-1.640991 -v seed="$SEED2" 'BEGIN {srand(seed); printf "%.6f", base + ((rand() - 0.5) * 0.02)}')

    echo "Ajout de $GNB_NAME à la position ($POSX, $POSY)..."

    sudo docker exec -i db mongosh open5gs --eval "
    db.gnbs.insertOne({
        \"gnbId\": \"$GNB_ID\",
        \"name\": \"$GNB_NAME\",
        \"location\": { \"lat\": $POSX, \"lng\": $POSY },
        \"supportedSlices\": [{ \"sst\": 1, \"sd\": \"000001\" }, { \"sst\": 2, \"sd\": \"000001\" }, { \"sst\": 3, \"sd\": \"000001\" }],
        \"schema_version\": 1
    })"
done