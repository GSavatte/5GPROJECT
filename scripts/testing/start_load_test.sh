#!/bin/bash

SINK_IP=$(getent hosts internet-sim | awk '{ print $1 }')

if [ -z "$SINK_IP" ]; then
    echo "[ERROR] Unable to find the IP of the internet-sim container."
    echo "[INFO] Please ensure that the container is running and on the same network."
    exit 1
fi

echo "[INFO] Target found at address : $SINK_IP"
echo "[INFO] Starting the traffic storm on $LOADTEST_COUNT UEs..."

INTERFACES=$(ip link show | grep -o 'uesimtun[0-9]*' | head -n "$LOADTEST_COUNT")

for INTERFACE in $INTERFACES; do

    MAX_WAIT=20
    WAIT_COUNT=0

    while ! ip addr show $INTERFACE | grep -q "inet "; do
        sleep 0.5
        WAIT_COUNT=$((WAIT_COUNT+1))
        
        if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
            echo "[WARN] Timeout : Interface $INTERFACE did not get an IP address after $MAX_WAIT seconds. Skipping..."
            break
        fi
    done

    sleep 0.$((RANDOM % 5))

    curl --interface $INTERFACE -o /dev/null http://$SINK_IP/1GB.bin &
done

echo "[INFO] Traffic storm initiated on $LOADTEST_COUNT UEs. Monitor the load test in the logs of the ue-loadtester container."
wait