#!/bin/bash
echo "Installation de curl..."
sleep 0.5
apt-get update -y > /dev/null 2>&1
apt-get install curl -y > /dev/null 2>&1
echo "Installation de curl terminée."

echo "Installation de mongodb..."
curl -sL https://downloads.mongodb.com/compass/mongosh-2.2.5-linux-x64.tgz -o /tmp/mongosh.tgz
tar -zxvf /tmp/mongosh.tgz -C /tmp/ > /dev/null 2>&1
cp /tmp/mongosh-*-linux-x64/bin/mongosh /usr/local/bin/
echo "Installation de mongodb terminée."

nombre_ues="${NB_UES:-200}"
NUM_GNBS=$(ls -1 /generated_gnbs/ | wc -l)

echo "Nombre d'antennes gNB détectées : $NUM_GNBS"

echo "Base de données prête. Résolution des antennes..."

declare -A GNB_IPS
for id in $(seq 1 $NUM_GNBS); do
  
  HOSTNAME=$(printf "gnb%02d" $id)
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

get_closest_gnb_id() {
  local imsi=$1
  
  mongosh "mongodb://db:27017/open5gs" --eval "
    
    const ue = db.subscribers.findOne({ imsi: '${imsi}' });
    
    if (ue) {
      const closest = db.gnbs.aggregate([
        {
          \$addFields: {
            distance: {
              \$add: [
                { \$pow: [{ \$subtract: ['\$location.lat', ue.position.latitude] }, 2] },
                { \$pow: [{ \$subtract: ['\$location.lng', ue.position.longitude] }, 2] }
              ]
            }
          }
        },
        { \$sort: { distance: 1 } },
        { \$limit: 1 }
      ]).toArray()[0];
      
      if (closest) print(closest.gnbId);
    }
  "
}

echo "Démarrage de la génération dynamique basée sur la localisation..."

for i in $(seq 1 3 $nombre_ues); do
  SUFFIX=$(printf "%010d" $i)
  SUFFIX2=$(printf "%010d" $((i+1)))
  SUFFIX3=$(printf "%010d" $((i+2)))
  IMSI="imsi-20801$SUFFIX"
  IMSI2="imsi-20801$SUFFIX2"
  IMSI3="imsi-20801$SUFFIX3"
  
  GNB_ID=$(get_closest_gnb_id "20801$SUFFIX")
  GNB_ID2=$(get_closest_gnb_id "20801$SUFFIX2")
  GNB_ID3=$(get_closest_gnb_id "20801$SUFFIX3")
  
  if [ -z "$GNB_ID" ]; then GNB_ID=1; fi
  if [ -z "$GNB_ID2" ]; then GNB_ID2=1; fi
  if [ -z "$GNB_ID3" ]; then GNB_ID3=1; fi
  
  GNB_TARGET=${GNB_IPS[$GNB_ID]} 
  GNB_TARGET2=${GNB_IPS[$GNB_ID2]}
  GNB_TARGET3=${GNB_IPS[$GNB_ID3]}
  
  sed -e "s/IMSI_PLACEHOLDER/$IMSI/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET/g" /config/ue-template.yaml > "/tmp/ue-${IMSI}.yaml"
  sed -e "s/IMSI_PLACEHOLDER/$IMSI2/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET2/g" /config/ue-template2.yaml > "/tmp/ue-${IMSI2}.yaml"
  sed -e "s/IMSI_PLACEHOLDER/$IMSI3/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET3/g" /config/ue-template3.yaml > "/tmp/ue-${IMSI3}.yaml"
  
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI}.yaml" > "/tmp/logs-${IMSI}.txt" 2>&1 &
  sleep 0.15
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI2}.yaml" > "/tmp/logs-${IMSI2}.txt" 2>&1 &
  sleep 0.15
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI3}.yaml" > "/tmp/logs-${IMSI3}.txt" 2>&1 &
  sleep 0.1
  
  sleep 0.2
done

echo "Toutes les UEs ont été lancées et rattachées aux antennes gNB."

sleep 2

if [ "${loadtest:-"n"}" = "y" ]; then
  dd if=/dev/zero of=/config/1GB.bin bs=1M count=1000
  echo "Lancement du test de charge..."
  bash /config/start_load_test.sh
fi

tail -f /dev/null
