#!/bin/bash

echo "=============================================="
echo "🚀 DÉBUT DU DIAGNOSTIC DU RÉSEAU 5G"
echo "=============================================="

UE_CONTAINERS=("ue1" "ue2" "ue3" "ue4" "ue5" "ue6" "ue7" "ue8" "ue9" "ue10")
GNB_CONTAINERS=("gnb1" "gnb2" "gnb3" "gnb4")

echo -e "\n[1/3] VÉRIFICATION DES ANTENNES (gNB)"
for gnb in "${GNB_CONTAINERS[@]}"; do
    if [ "$(docker inspect -f '{{.State.Running}}' "$gnb" 2>/dev/null)" = "true" ]; then
        if docker logs "$gnb" 2>&1 | grep -q "NG Setup procedure is successful"; then
            echo "✅ $gnb : Connecté à l'AMF"
        else
            echo "⚠️ $gnb : Tourne, mais non connecté au cœur de réseau"
        fi
    else
        echo "❌ $gnb : CRASH (Conteneur arrêté)"
    fi
done

echo -e "\n[2/3] VÉRIFICATION DE L'ACCÈS INTERNET DES UEs (8.8.8.8)"
for ue in "${UE_CONTAINERS[@]}"; do
    if [ "$(docker inspect -f '{{.State.Running}}' "$ue" 2>/dev/null)" = "true" ]; then
        if docker exec "$ue" ping -c 1 -W 1 -I uesimtun0 8.8.8.8 &> /dev/null; then
            echo "✅ $ue : Accès Internet OK"
        else
            echo "❌ $ue : ÉCHEC PING"
        fi
    else
        echo "❌ $ue : CRASH (Vérifier IMSI/Keys)"
    fi
done

echo -e "\n[3/3] VÉRIFICATION DE LA COMMUNICATION ENTRE UEs"
IP_UE1=$(docker exec ue1 ip -4 addr show uesimtun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -z "$IP_UE1" ]; then
    echo "⚠️ Impossible de récupérer l'IP de ue1. Test interne annulé."
else
    echo "➡️ IP de référence (ue1) : $IP_UE1"
    for ue in "${UE_CONTAINERS[@]}"; do
        if [ "$ue" != "ue1" ]; then
            if docker exec "$ue" ping -c 1 -W 1 -I uesimtun0 "$IP_UE1" &> /dev/null; then
                echo "✅ $ue -> ue1 : Communication OK"
            else
                echo "❌ $ue -> ue1 : ÉCHEC PING (Slices isolées ou erreur de routage)"
            fi
        fi
    done
fi

echo "=============================================="
echo "🏁 FIN DES TESTS"
echo "=============================================="