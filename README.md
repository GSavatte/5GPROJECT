# 5G Network Deployment Project

This repository contains a complete 5G Standalone deployment based on Open5GS and UERANSIM. The project uses Docker to orchestrate the 5G Core Network and Radio Access Network components, enabling easy deployment, testing, and experimentation.

It serves as a practical environment for studying 5G architecture, network function interactions, subscriber management, PDU session establishment, and end-to-end connectivity between simulated UEs and the core network.

The long-term objective of this project is to provide a complete, production-inspired 5G laboratory environment that can be deployed as quickly and automatically as possible. Beyond core network deployment, the project aims to integrate centralized monitoring, performance metrics collection, and AI-assisted diagnostics to facilitate troubleshooting, network analysis, and operational visibility across the entire 5G infrastructure.

# Initial working bases

The initial implementation of the project revealed several limitations, particularly regarding Internet connectivity for end-user devices and the lack of modularity and transparency within the deployed architecture. The original solution was based on a monolithic pre-built image that grouped all network functions together, making maintenance, monitoring, and customization more difficult. To address these limitations, the project was redesigned using the work of [Borjis](https://github.com/Borjis131) (https://github.com/Borjis131/docker-open5gs) as a foundation. This approach provides a modular deployment of a complete 5G infrastructure, including both the Core Network and the Radio Access Network (RAN).

# Current state

The current implementation is based on a simplified network slicing setup consisting of:

- 2 User Equipments
- 2 network slices
- Each UE is currently assigned to it's own dedicated slice

This configuration allows us to validate the good health of the network.

# How to setup this first basic network ?

1. Clone this repository
```bash
git clone https://github.com/GSavatte/5GPROJECT.git
cd 5GPROJECT/
```

2. Create logs folder and initialize database by starting the network
```bash
sudo docker compose up
```

3. Currently, there is no webUI to regsiter UEs in the database. However, you can add them manually using those commands :

```bash
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "imsi": "208011234567891",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 1,
        "sd": "000001",
        "default_indicator": true,
        "session": [{
            "name": "internet",
            "type": 3,
            "pcc_rule": [],
            "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
            "qos": { "index": 9, "arp": { "priority_level": 8, "pre_emption_capability": 1, "pre_emption_vulnerability": 1 } }
        }]
    }],
    "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
    "security": { "k": "00000000000000000000000000000000", "amf": "8000", "op": null, "opc": "00000000000000000000000000000000", "sqn": NumberLong(0) },
    "schema_version": 1
})'
```

```bash
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "imsi": "208011234567892",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 1,
        "sd": "000002",
        "default_indicator": true,
        "session": [{
            "name": "internet",
            "type": 3,
            "pcc_rule": [],
            "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
            "qos": { "index": 9, "arp": { "priority_level": 8, "pre_emption_capability": 1, "pre_emption_vulnerability": 1 } }
        }]
    }],
    "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
    "security": { "k": "00000000000000000000000000000000", "amf": "8000", "op": null, "opc": "00000000000000000000000000000000", "sqn": NumberLong(0) },
    "schema_version": 1
})'
```
These commands reuse the numbers written in the configs (imsi) and indicate the slice on which they will operate.

4. Restart the devices so they can connect.

```bash
sudo docker restart ue1 ue2
```

# Test the connection :

1. On device #1 :

```bash
sudo docker exec -it ue1 ping 8.8.8.8
```

2. On device #2 : 
```bash
sudo docker exec -it ue2 ping 8.8.8.8
```

# Project Objectives

One of the main goals of this project is to extend the current architecture by introducing:

- Multiple additional UEs
- More network slices with varied configurations
- Support for multiple gNodeBs (gNBs)
- The ability to assign gNBs to a geographical point to simulate a real-world network

Another objective is to add clear and useful indicators for monitoring the network. Finally, attempting to implement an AI model to manage the network more easily and quickly would also be a goal.