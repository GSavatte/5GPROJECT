#!/bin/bash

echo "Démarrage du cœur de réseau..."
docker compose up -d amf ausf bsf nrf nssf pcf smf1 smf2 smf3 upf1 upf2 upf3 udm udr
sleep 5

echo "Démarrage des antennes (gNBs)..."
docker compose up -d gnb1 gnb2 gnb3 gnb4
sleep 5

echo "Démarrage progressif des UEs..."
UE_CONTAINERS=("ue1" "ue2" "ue3" "ue4" "ue5" "ue6" "ue7" "ue8" "ue9" "ue10")

for ue in "${UE_CONTAINERS[@]}"; do
    echo "  -> Allumage de $ue"
    docker compose up -d "$ue"
    sleep 2 
done

echo "Réseau entièrement déployé."