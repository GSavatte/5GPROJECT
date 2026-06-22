#!/bin/bash

echo "Installation de curl..."
sleep 5
apt-get update -y > /dev/null 2>&1
apt-get install curl -y > /dev/null 2>&1
echo "Installation de curl terminée."

nombre_ues=200
NUM_GNBS=4

echo "Base de données prête. Résolution des antennes..."

declare -A GNB_IPS
for id in $(seq 1 $NUM_GNBS); do
  
  HOSTNAME="gnb${id}" 
  
  # On interroge le système pour récupérer l'IPv4 brute
  IP=$(getent hosts $HOSTNAME | awk '{ print $1 }' | head -n 1)
  
  if [ -z "$IP" ]; then
     echo "IP introuvable pour $HOSTNAME."
     GNB_IPS[$id]=$HOSTNAME # on garde le nom s'il ne trouve pas l'IP
  else
     echo "✅ Antenne $HOSTNAME trouvée sur l'IP : $IP"
     GNB_IPS[$id]=$IP
  fi
done

echo "Démarrage de la simulation..."

for i in $(seq 1 $nombre_ues); do
  SUFFIX=$(printf "%010d" $i)
  IMSI="imsi-20801$SUFFIX"
  
  GNB_ID=$(( ((i - 1) % NUM_GNBS) + 1 ))
  GNB_TARGET=${GNB_IPS[$GNB_ID]} 
  
  sed -e "s/IMSI_PLACEHOLDER/$IMSI/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET/g" /config/ue-template.yaml > "/tmp/ue-${IMSI}.yaml"
  
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI}.yaml" > "/tmp/logs-${IMSI}.txt" 2>&1 &
  
  sleep 0.1 
done

echo "Simulation lancée."
tail -f /dev/null