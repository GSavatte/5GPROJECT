#!/bin/bash
echo "[INFO] Starting the provisioning of UEs..."
sleep 0.1
echo "[INFO] Installing necessary packages..."
apt-get update -y > /dev/null 2>&1
apt-get install curl -y > /dev/null 2>&1
echo "[INFO] Installation completed."

echo "[INFO] Installing MongoDB..."
curl -sL https://downloads.mongodb.com/compass/mongosh-2.2.5-linux-x64.tgz -o /tmp/mongosh.tgz
tar -zxvf /tmp/mongosh.tgz -C /tmp/ > /dev/null 2>&1
cp /tmp/mongosh-*-linux-x64/bin/mongosh /usr/local/bin/
echo "[INFO] MongoDB installation completed."

nombre_ues="${NB_UES:-200}"
NUM_GNBS=$(ls -1 /generated_gnbs/ | wc -l)

echo "[INFO] Number of detected gNB antennas: $NUM_GNBS"

echo "[INFO] Database ready. Resolving antennas..."

declare -A GNB_HOSTS
for id in $(seq 1 $NUM_GNBS); do

  HOSTNAME=$(printf "gnb%02d" $id)
  FQDN="${HOSTNAME}.ueransim.org"
  RESOLVED=""
  MAX_RETRIES=15
  COUNT=0
  
  while [ -z "$RESOLVED" ] && [ $COUNT -lt $MAX_RETRIES ]; do
    RESOLVED=$(getent hosts "$FQDN" | awk '{ print $1 }' | head -n 1)

    if [ -z "$RESOLVED" ]; then
       echo "[INFO] Waiting for the network for $HOSTNAME (Attempt $((COUNT+1))/$MAX_RETRIES)..."
       sleep 1
       COUNT=$((COUNT+1))
    fi
  done

  if [ -z "$RESOLVED" ]; then
     echo "[ERROR] DNS not found for $HOSTNAME after $MAX_RETRIES seconds."
     GNB_HOSTS[$id]=$FQDN
  else
     echo "[INFO] Antenna $HOSTNAME reachable via: $FQDN (Current IP: $RESOLVED)"
     GNB_HOSTS[$id]=$FQDN
  fi
done

echo "[INFO] Starting the simulation..."

get_closest_gnb_id() {
  local imsi=$1
  
  mongosh "mongodb://db:27017/open5gs" --quiet --eval "
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
  " | grep -Eo '[0-9]+' | tail -n 1
}

echo "[INFO] Starting dynamic generation based on location..."

for i in $(seq 1 3 $nombre_ues); do
  SUFFIX=$(printf "%010d" $i)
  IMSI="imsi-20801$SUFFIX"
  GNB_ID=$(get_closest_gnb_id "20801$SUFFIX")
  GNB_TARGET=${GNB_HOSTS[$GNB_ID]}

  if [ -z "$GNB_TARGET" ]; then
     echo "[WARN] Empty hostname for UE $IMSI (Read GNB_ID: '$GNB_ID')"
  fi
  
  sed -e "s/IMSI_PLACEHOLDER/$IMSI/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET/g" /ue_templates/ue-template.yaml > "/tmp/ue-${IMSI}.yaml"
  /UERANSIM/nr-ue -c "/tmp/ue-${IMSI}.yaml" > "/tmp/logs-${IMSI}.txt" 2>&1 &
  sleep 0.15

  if [ $((i+1)) -le $nombre_ues ]; then
    SUFFIX2=$(printf "%010d" $((i+1)))
    IMSI2="imsi-20801$SUFFIX2"
    GNB_ID2=$(get_closest_gnb_id "20801$SUFFIX2")
    GNB_TARGET2=${GNB_HOSTS[$GNB_ID2]}

    if [ -z "$GNB_TARGET2" ]; then
       echo "[WARN] Empty hostname for UE $IMSI2 (Read GNB_ID: '$GNB_ID2')"
    fi
    
    sed -e "s/IMSI_PLACEHOLDER/$IMSI2/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET2/g" /ue_templates/ue-template2.yaml > "/tmp/ue-${IMSI2}.yaml"
    /UERANSIM/nr-ue -c "/tmp/ue-${IMSI2}.yaml" > "/tmp/logs-${IMSI2}.txt" 2>&1 &
    sleep 0.15
  fi

  if [ $((i+2)) -le $nombre_ues ]; then
    SUFFIX3=$(printf "%010d" $((i+2)))
    IMSI3="imsi-20801$SUFFIX3"
    GNB_ID3=$(get_closest_gnb_id "20801$SUFFIX3")
    GNB_TARGET3=${GNB_HOSTS[$GNB_ID3]}

    if [ -z "$GNB_TARGET3" ]; then
       echo "[WARN] Empty hostname for UE $IMSI3 (Read GNB_ID: '$GNB_ID3')"
    fi
    
    sed -e "s/IMSI_PLACEHOLDER/$IMSI3/g" -e "s/GNB_PLACEHOLDER/$GNB_TARGET3/g" /ue_templates/ue-template3.yaml > "/tmp/ue-${IMSI3}.yaml"
    /UERANSIM/nr-ue -c "/tmp/ue-${IMSI3}.yaml" > "/tmp/logs-${IMSI3}.txt" 2>&1 &
    sleep 0.1
  fi
  
  sleep 0.2
done

echo "[INFO] All UEs have been launched and attached to the gNB antennas."

sleep 2

if [ "${LOADTEST_COUNT:-0}" -gt 0 ]; then
  dd if=/dev/zero of=/testing/1GB.bin bs=1M count=1000
  echo "[INFO] Starting the load test on $LOADTEST_COUNT UEs..."
  bash /testing/start_load_test.sh
fi

tail -f /dev/null