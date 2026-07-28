#!/bin/bash

if [[ "$1" == "--rebuild" ]]; then
    echo "⚠️ Attention : Reconstruction complète des images sans utiliser le cache..."
    
    echo "-> Build du cœur de réseau et WebUI..."
    docker compose -f compose-files/docker-compose.yml --env-file=.env build --no-cache
    
    echo "-> Build des antennes (gNBs)..."
    docker compose -f compose-files/docker-compose.gnbs.yaml build --no-cache
    
    echo "-> Build du monitoring..."
    docker compose -f compose-files/docker-compose.monitoring.yaml build --no-cache
    
    echo "-> Build des outils de test de charge..."
    docker compose -f compose-files/docker-compose.loadtest.yaml build --no-cache
    
    echo "✅ Reconstruction terminée avec succès."
    echo "--------------------------------------------------------"
fi

echo "Démarrage du cœur de réseau..."
docker compose -f compose-files/docker-compose.yml --env-file=.env up -d amf ausf bsf db nrf nssf pcf smf1 smf2 smf3 upf1 upf2 upf3 udm udr
sleep 2
# sudo bash utils/scripts/clear.sh




read -p "Voulez-vous importer une configuration existante depuis la WebUI ? (y/n) " IMPORT_MODE


if [[ "$IMPORT_MODE" == "y" || "$IMPORT_MODE" == "Y" ]]; then
    echo "Lancement de la WebUI..."
    docker compose -f compose-files/docker-compose.yml --env-file=.env up -d webui
    sleep 2
    echo "WebUI lancée. Accédez-y via http://localhost:9999 pour importer votre configuration."
    echo "⏳ En attente de l'insertion des données dans MongoDB..."
    
    NB_GNBS=0
    while [ -z "$NB_GNBS" ] || [ "$NB_GNBS" -eq 0 ]; do
        sleep 3
        NB_GNBS=$(docker exec -i db mongosh open5gs --quiet --eval "db.gnbs.countDocuments({})" | grep -o '[0-9]\+')
    done

    echo "✅ Données importées avec succès depuis la WebUI. Nombre d'antennes gNB détectées : $NB_GNBS"

else
    read -p "Combien d'UEs voulez-vous générer ? " NB_UES
    read -p "Combien de gNBs voulez-vous générer ? " NB_GNBS

    echo "Démarrage du seeder avec $NB_UES UEs et $NB_GNBS gNBs..."
    docker compose -f compose-files/docker-compose.yml --env-file=.env run --rm -e NB_UES="$NB_UES" -e NB_GNBS="$NB_GNBS" db-seeder
    sleep 2
fi






sudo bash scripts/provisioning/start_gnbs.sh "$NB_GNBS"

echo "Démarrage des antennes (gNBs)..."

docker compose -f compose-files/docker-compose.gnbs.yaml up -d
sleep 5

echo "Réseau 5G déployé avec succès."

if [[ "$IMPORT_MODE" != "y" && "$IMPORT_MODE" != "Y" ]]; then
    read -p "Voulez-vous lancer l'interface web permettant de gérer les subscribers, accéder à la carte du réseau etc... ? (y/n) " launch
    if [[ "$launch" == "y" || "$launch" == "Y" ]]; then
        echo "Lancement de l'interface web..."
        docker compose --env-file=.env -f compose-files/docker-compose.yml up -d webui
        sleep 2
        echo "Interface web lancée. Accédez-y via http://localhost:9999"
    fi
fi

read -p "Voulez-vous lancer le monitoring du réseau 5G ? (y/n) " monitor
if [[ "$monitor" == "y" || "$monitor" == "Y" ]]; then
    echo "Lancement du monitoring..."
    docker compose --env-file=.env -f compose-files/docker-compose.monitoring.yaml up -d 
    sleep 2
    echo "Monitoring lancé. Accédez-y via http://localhost:3000 (login: admin, password: admin)"
fi


read -p "Combien d'UEs voulez-vous impliquer dans le test de charge ? (Entrez 0 pour aucun) : " LOADTEST_COUNT

if ! [[ "$LOADTEST_COUNT" =~ ^[0-9]+$ ]]; then
    echo "Erreur : Veuillez entrer un nombre valide."
    exit 1
fi

if [ "$LOADTEST_COUNT" -gt 0 ]; then
    docker compose --env-file=.env -f compose-files/docker-compose.loadtest.yaml up -d internet-sim
    sleep 0.5
fi

docker compose --env-file=.env -f compose-files/docker-compose.loadtest.yaml run -d --name ue-loadtester --rm -e NB_UES="$NB_UES" -e LOADTEST_COUNT="$LOADTEST_COUNT" ue-loadtester

mkdir -p ./shared_flags
FLAG_FILE="./shared_flags/redeploy.flag"
REDEPLOY_SCRIPT="./scripts/lifecycle/re-deploy.sh"

rm -f "$FLAG_FILE"

echo "Démarrage du contrôleur SDN (mobilité)..."
nohup bash scripts/mobility/sdn-controller.sh > logs/sdn-controller.log 2>&1 &
echo $! > shared_flags/sdn-controller.pid
echo "✅ Contrôleur SDN lancé en arrière-plan (PID: $(cat shared_flags/sdn-controller.pid)). Logs : logs/sdn-controller.log"

echo "========================================================"
echo "✅ Réseau 5G déployé !"
echo "Le contrôleur SDN est actif. En attente de mises à jour depuis la WebUI..."
echo "Laissez ce terminal ouvert pour maintenir le simulateur. (Ctrl+C pour quitter puis executez stop.sh pour un arrêt propre et complet)"
echo "========================================================"

while true; do
    if [[ -f "$FLAG_FILE" ]]; then
        echo "Signal de redéploiement détecté. Exécution du script de redéploiement..."
        rm -f "$FLAG_FILE"
        bash "$REDEPLOY_SCRIPT"
        echo "Redéploiement terminé. Reprise de l'attente de signal..."
    fi
    sleep 2
done