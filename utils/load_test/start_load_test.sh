#!/bin/bash

SINK_IP=$(getent hosts internet-sim | awk '{ print $1 }')

if [ -z "$SINK_IP" ]; then
    echo "Erreur : Impossible de trouver l'IP du conteneur internet-sim."
    echo "Le conteneur est-il bien allumé et sur le même réseau ?"
    exit 1
fi

echo "Cible trouvée à l'adresse : $SINK_IP"
echo "Lancement de la tempête de trafic sur 100 UEs..."

INTERFACES=$(ip link show | grep -o 'uesimtun[0-9]*')

for INTERFACE in $INTERFACES; do

    MAX_WAIT=20
    WAIT_COUNT=0

    while ! ip addr show $INTERFACE | grep -q "inet "; do
        sleep 0.5
        WAIT_COUNT=$((WAIT_COUNT+1))
        
        if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
            echo "⚠️ Timeout : L'interface $INTERFACE n'a pas reçu d'IP à temps."
            break
        fi
    done

    sleep 0.$((RANDOM % 5))

    curl --interface $INTERFACE -o /dev/null http://$SINK_IP/1GB.bin &
done

echo "Les 100 téléchargements sont en cours en arrière-plan !"
wait