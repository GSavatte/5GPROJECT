#!/bin/bash

UES_TO_TEST=50
COUNT=0

echo "Démarrage du test de charge avec $UES_TO_TEST UEs..."

INTERFACES=$(ip link show | grep -oP 'uesimtun\d+')

for tun in $INTERFACES; do
    if [ "$COUNT" -ge "$UES_TO_TEST" ]; then
        break
    fi

    echo "Génération de trafic sur l'interface $tun..."

    while true; do
        curl --interface "$tun" -o /dev/null -s http://ipv4.download.thinkbroadband.com/10MB.zip
        sleep 2
    done &

    COUNT=$((COUNT + 1))
done

echo "Test de charge lancé avec $COUNT UEs. Appuyez sur Ctrl+C pour arrêter le test..."
wait