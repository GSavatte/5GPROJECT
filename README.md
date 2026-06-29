# 5G Network Deployment Project

This repository contains a complete 5G Standalone deployment based on Open5GS and UERANSIM. The project uses Docker to orchestrate the 5G Core Network and Radio Access Network components, enabling easy deployment, testing, and experimentation.

It serves as a practical environment for studying 5G architecture, network function interactions, subscriber management, PDU session establishment, and end-to-end connectivity between simulated UEs and the core network.

The long-term objective of this project is to provide a complete, production-inspired 5G laboratory environment that can be deployed as quickly and automatically as possible. Beyond core network deployment, the project aims to integrate centralized monitoring, performance metrics collection, and AI-assisted diagnostics to facilitate troubleshooting, network analysis, and operational visibility across the entire 5G infrastructure.

# Initial working bases

The initial implementation of the project revealed several limitations, particularly regarding Internet connectivity for end-user devices and the lack of modularity and transparency within the deployed architecture. The original solution was based on a monolithic pre-built image that grouped all network functions together, making maintenance, monitoring, and customization more difficult. To address these limitations, the project was redesigned using the work of [Borjis131](https://github.com/Borjis131) (https://github.com/Borjis131/docker-open5gs) as a foundation. This approach provides a modular deployment of a complete 5G infrastructure, including both the Core Network and the Radio Access Network (RAN).

# How to run the project ?

A user-friendly script has been written to easily deploy the network. 

1. First, clone the project :
```bash
git clone https://github.com/GSavatte/5GPROJECT.git
cd 5GPROJECT/
```

2. Run the script
```bash
sudo bash ./utils/scripts/start.sh
```

3. Answer questions asked by the script (number of gNBs, either to deploy the webui or not, start the monitoring, start load-testing etc.)

To stop the project, you can run the `stop.sh` script which will stop all the containers and **clear the database** :

```bash
sudo bash ./utils/scripts/stop.sh
```