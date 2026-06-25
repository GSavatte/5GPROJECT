#!/bin/bash

SINK_IP=$(getent hosts internet-sim | awk '{ print $1 }')

if [ -z "$SINK_IP" ]; then
    echo "Erreur : Impossible de trouver l'IP du conteneur internet-sim."
    echo "Le conteneur est-il bien allumé et sur le même réseau ?"
    exit 1
fi

echo "Cible trouvée à l'adresse : $SINK_IP"
echo "Lancement de la tempête de trafic sur 100 UEs..."

for i in {0..399}; do
    curl --interface uesimtun$i -o /dev/null http://$SINK_IP/1GB.bin &
done

echo "Les 100 téléchargements sont en cours en arrière-plan !"
wait