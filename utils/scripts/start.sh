#!/bin/bash


echo "Démarrage du cœur de réseau..."
docker compose --env-file=.env -f compose-files/docker-compose.yml up -d amf ausf bsf db nrf nssf pcf smf1 smf2 smf3 upf1 upf2 upf3 udm udr
sleep 5

sudo bash utils/scripts/clear.sh
sudo bash utils/scripts/start_gnbs.sh

echo "Démarrage des antennes (gNBs)..."

docker compose -f compose-files/docker-compose.gnbs.yaml up -d
sleep 5

echo "Réseau 5G déployé avec succès."

read -p "Voulez-vous lancer l'interface web permettant de gérer les subscribers, accéder à la carte du réseau etc... ? (y/n) " launch
if [[ "$launch" == "y" || "$launch" == "Y" ]]; then
    echo "Lancement de l'interface web..."
    docker compose --env-file=.env -f compose-files/docker-compose.yml up -d webui
    sleep 2
    echo "Interface web lancée. Accédez-y via http://localhost:9999"
fi

read -p "Voulez-vous lancer le monitoring du réseau 5G ? (y/n) " monitor
if [[ "$monitor" == "y" || "$monitor" == "Y" ]]; then
    echo "Lancement du monitoring..."
    docker compose --env-file=.env -f compose-files/docker-compose.monitoring.yaml up -d 
    sleep 2
    echo "Monitoring lancé. Accédez-y via http://localhost:3000 (login: admin, password: admin)"
fi

read -p "Voulez-vous lancer un test de charge avec 400 UEs et générer du trafic vers le conteneur internet-sim ? (y/n) " loadtest
if [[ "$loadtest" == "y" || "$loadtest" == "Y" ]]; then
    echo "Lancement du test de charge..."
    docker compose --env-file=.env -f compose-files/docker-compose.loadtest.yaml up -d
    sleep 2
    echo "Test de charge lancé. Les logs des UEs sont disponibles dans le conteneur loadtest."
fi