# A script to helps insert subscribers into the database for testing purposes. It uses the `mongosh` command to execute MongoDB commands inside a Docker container named `db`.
# The script inserts two subscriber documents into the `subscribers` collection of the `open5gs` database.
# Each subscriber has an IMSI, RAU/TAU timer, network access mode, subscriber status, access restriction data, slice information, AMBR (Aggregate Maximum Bit Rate), and security information.

echo "Inserting a 1st test subscriber (eMBB) into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 1",
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

echo "Inserting a 2nd test subscriber (eMBB) into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 2",
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

echo "Inserting a 3rd test subscriber (MIoT) into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 3",
    "imsi": "208011234567893",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 3,
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