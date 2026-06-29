#!/bin/bash
echo "Installation de curl..."
sleep 0.5
apt-get update -y > /dev/null 2>&1
apt-get install curl -y > /dev/null 2>&1
echo "Installation de curl terminée."

nombre_ues=400
NUM_GNBS=$(ls -1 /generated_gnbs/ | wc -l)

echo "Nombre d'antennes gNB détectées : $NUM_GNBS"

echo "Base de données prête. Résolution des antennes..."

declare -A GNB_IPS
for id in $(seq 1 $NUM_GNBS); do
  
  HOSTNAME="gnb${id}" 
  IP=""
  MAX_RETRIES=15
  COUNT=0
  
  while [ -z "$IP" ] && [ $COUNT -lt $MAX_RETRIES ]; do
    IP=$(getent hosts $HOSTNAME | awk '{ print $1 }' | head -n 1)
    
    if [ -z "$IP" ]; then
       echo "⏳ Attente du réseau pour $HOSTNAME (Tentative $((COUNT+1))/$MAX_RETRIES)..."
       sleep 1
       COUNT=$((COUNT+1))
    fi
  done
  
  if [ -z "$IP" ]; then
     echo "❌ IP définitivement introuvable pour $HOSTNAME après $MAX_RETRIES secondes."
     GNB_IPS[$id]=$HOSTNAME
  else
     echo "✅ Antenne $HOSTNAME trouvée sur l'IP : $IP"
     GNB_IPS[$id]=$IP
  fi
done

echo "Démarrage de la simulation..."

for i in $(seq 1 2 $nombre_ues); do
  SUFFIX=$(printf "%010d" $i)
  SUFFIX2=$(printf "%010d" $((i+1)))
  IMSI="imsi-20801$SUFFIX"
  IMSI2="imsi-20801$SUFFIX2"
  
  GNB_ID=$(( ((i - 1) % NUM_GNBS) + 1 ))
  GNB_ID2=$(( ((i) % NUM_GNBS) + 1 ))
  GNB_TARGET=${GNB_IPS[$GNB_ID]} 
  GNB_TARGET2=${GNB_IPS[$GNB_ID2]}
  
  sed -e "s/IMSI_PLACEHOLDER/$IMSI/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET/g" /config/ue-template.yaml > "/tmp/ue-${IMSI}.yaml"

  sed -e "s/IMSI_PLACEHOLDER/$IMSI2/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET2/g" /config/ue-template2.yaml > "/tmp/ue-${IMSI2}.yaml"
  
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI}.yaml" > "/tmp/logs-${IMSI}.txt" 2>&1 &
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI2}.yaml" > "/tmp/logs-${IMSI2}.txt" 2>&1 &
  
  sleep 0.13 
done

echo "Toutes les requêtes d'attachement on été envoyées aux gNBs. En attente de la création des interfaces réseau pour les UEs..."

sleep 5

bash -c "bash /config/generate_traffic.sh"