#!/bin/bash

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================
# Each option, if provided, short-circuits the corresponding interactive prompt.
# Without any flags, the script behaves exactly as before (fully interactive)..
#
# Available options:
#   --rebuild                Rebuild all Docker images without using cache (skips the prompt)
#   --import                 Import configuration from the WebUI (skips the prompt)
#   --no-import               Generate via seeder rather than importing (skips the prompt)
#   --nb-gnbs=N               Number of gNBs to generate (only in --no-import mode)
#   --nb-ues=N                Number of UEs to generate (only in --no-import mode)
#   --webui / --no-webui      Launch or not the WebUI (skips the prompt post-generation)
#   --monitoring / --no-monitoring   Launch or not the monitoring (skips the prompt)
#   --loadtest-count=N        Number of UEs for the load test (0 = none, skips the prompt)
# ==============================================================================

REBUILD=false

for arg in "$@"; do
    case $arg in
        --rebuild) REBUILD=true ;;
        --import) IMPORT_MODE="y" ;;
        --no-import) IMPORT_MODE="n" ;;
        --nb-gnbs=*) NB_GNBS="${arg#*=}" ;;
        --nb-ues=*) NB_UES="${arg#*=}" ;;
        --webui) launch="y" ;;
        --no-webui) launch="n" ;;
        --monitoring) monitor="y" ;;
        --no-monitoring) monitor="n" ;;
        --loadtest-count=*) LOADTEST_COUNT="${arg#*=}" ;;
        *)
            echo "[WARN] Unknown option ignored : $arg"
            ;;
    esac
done

if [[ "$REBUILD" == "true" ]]; then
    echo "[INFO] Complete rebuild requested. All Docker images will be rebuilt without cache."

    echo "-> Build of the 5G Core Network and WebUI..."
    docker compose -f compose-files/docker-compose.yml --env-file=.env build --no-cache

    echo "-> Build of the gNBs..."
    docker compose -f compose-files/docker-compose.gnbs.yaml build --no-cache

    echo "-> Build of the monitoring..."
    docker compose -f compose-files/docker-compose.monitoring.yaml build --no-cache

    echo "-> Build of the load testing tools..."
    docker compose -f compose-files/docker-compose.loadtest.yaml build --no-cache

    echo "[INFO] All Docker images rebuilt successfully."
    echo "--------------------------------------------------------"
fi

echo "[INFO] Starting the 5G Core Network and its components..."
docker compose -f compose-files/docker-compose.yml --env-file=.env up -d amf ausf bsf db nrf nssf pcf smf1 smf2 smf3 upf1 upf2 upf3 udm udr
sleep 2

if [ -z "$IMPORT_MODE" ]; then
    read -p "Do you want to import an existing configuration from the WebUI? (y/n) " IMPORT_MODE
fi


if [[ "$IMPORT_MODE" == "y" || "$IMPORT_MODE" == "Y" ]]; then
    echo "[INFO] Launching the WebUI..."
    docker compose -f compose-files/docker-compose.yml --env-file=.env up -d webui
    sleep 2
    echo "[INFO] WebUI launched. Access it via http://localhost:9999 to import your configuration."
    echo "[INFO] Waiting for data insertion into MongoDB..."

    NB_GNBS=0
    while [ -z "$NB_GNBS" ] || [ "$NB_GNBS" -eq 0 ]; do
        sleep 3
        NB_GNBS=$(docker exec -i db mongosh open5gs --quiet --eval "db.gnbs.countDocuments({})" | grep -o '[0-9]\+')
    done

    echo "[INFO] Data imported successfully from the WebUI. Number of gNBs detected: $NB_GNBS"

else
    if [ -z "$NB_UES" ]; then
        read -p "How many UEs do you want to generate? " NB_UES
    fi
    if [ -z "$NB_GNBS" ]; then
        read -p "How many gNBs do you want to generate? " NB_GNBS
    fi

    echo "[INFO] Starting the seeder with $NB_UES UEs and $NB_GNBS gNBs..."
    docker compose -f compose-files/docker-compose.yml --env-file=.env run --rm -e NB_UES="$NB_UES" -e NB_GNBS="$NB_GNBS" db-seeder
    sleep 2
fi






sudo bash scripts/provisioning/start_gnbs.sh "$NB_GNBS"

echo "[INFO] Starting the gNB antennas..."

docker compose -f compose-files/docker-compose.gnbs.yaml up -d
sleep 5

echo "[INFO] 5G network deployed successfully."

if [[ "$IMPORT_MODE" != "y" && "$IMPORT_MODE" != "Y" ]]; then
    if [ -z "$launch" ]; then
        read -p "Do you want to launch the web interface that allows you to manage subscribers, access the network map, and more? (y/n) " launch
    fi
    if [[ "$launch" == "y" || "$launch" == "Y" ]]; then
        echo "[INFO] Starting the web interface..."
        docker compose --env-file=.env -f compose-files/docker-compose.yml up -d webui
        sleep 2
        echo "[INFO] Web interface launched. Access it via http://localhost:9999"
    fi
fi

if [ -z "$monitor" ]; then
    read -p "Do you want to start 5G network monitoring? (y/n) " monitor
fi
if [[ "$monitor" == "y" || "$monitor" == "Y" ]]; then
    echo "[INFO] Starting monitoring..."
    docker compose --env-file=.env -f compose-files/docker-compose.monitoring.yaml up -d
    sleep 2
    echo "[INFO] Monitoring started. Access it via http://localhost:3000 (login: admin, password: admin)"
fi


if [ -z "$LOADTEST_COUNT" ]; then
    read -p "How many UEs do you want to include in the load test? (Enter 0 for none): " LOADTEST_COUNT
fi

if ! [[ "$LOADTEST_COUNT" =~ ^[0-9]+$ ]]; then
    echo "[ERROR] Please enter a valid number."
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

echo "[INFO] Starting the SDN mobility controller..."
nohup bash scripts/mobility/sdn-controller.sh > logs/sdn-controller.log 2>&1 &
echo $! > shared_flags/sdn-controller.pid
echo "[INFO] SDN controller started in the background (PID: $(cat shared_flags/sdn-controller.pid)). Logs: logs/sdn-controller.log"

echo "========================================================"
echo "[INFO] 5G network deployed!"
echo "[INFO] The SDN controller is active. Waiting for updates from the WebUI..."
echo "[INFO] Leave this terminal open to keep the simulator running. (Ctrl+C to quit, then run stop.sh for a clean and complete shutdown)"
echo "========================================================"

while true; do
    if [[ -f "$FLAG_FILE" ]]; then
        echo "[INFO] Redeployment signal detected. Executing the redeployment script..."
        rm -f "$FLAG_FILE"
        bash "$REDEPLOY_SCRIPT"
        echo "[INFO] Redeployment completed. Resuming signal wait..."
    fi
    sleep 2
done