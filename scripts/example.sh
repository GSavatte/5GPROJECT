# A script to helps insert subscribers into the database for testing purposes. It uses the `mongosh` command to execute MongoDB commands inside a Docker container named `db`.
# The script inserts two subscriber documents into the `subscribers` collection of the `open5gs` database.
# Each subscriber has an IMSI, RAU/TAU timer, network access mode, subscriber status, access restriction data, slice information, AMBR (Aggregate Maximum Bit Rate), and security information.

echo "Inserting a 1st test subscriber (eMBB) connected to gNB1 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 1 eMBB",
    "position": { "latitude": 48.115438, "longitude": -1.63576 },
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

echo "Inserting a 2nd test subscriber (eMBB) connected to gNB1 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 2 eMBB",
    "position": { "latitude": 48.116442, "longitude": -1.634358 },
    "imsi": "208011234567892",
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

echo "Inserting a 3rd test subscriber (URLLC) connected to gNB1 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 3 URLLC",
    "position": { "latitude": 48.118326, "longitude": -1.633844 },
    "imsi": "208011234567893",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 2,
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

echo "Inserting a 4th test subscriber (URLLC) connected to gNB2 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 4 URLLC",
    "position": { "latitude": 48.120291, "longitude": -1.633466 },
    "imsi": "208011234567894",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 2,
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

echo "Inserting a 5th test subscriber (mMTC) connected to gNB2 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 5 mMTC",
    "position": { "latitude": 48.121687, "longitude": -1.633388 },
    "imsi": "208011234567895",
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

echo "Inserting a 6th test subscriber (mMTC) connected to gNB2 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 6 mMTC",
    "position": { "latitude": 48.124029, "longitude": -1.633951 },
    "imsi": "208011234567896",
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

echo "Inserting a 7th test subscriber (eMBB) connected to gNB3 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 7 eMBB",
    "position": { "latitude": 48.120512, "longitude": -1.63952 },
    "imsi": "208011234567897",
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

echo "Inserting a 8th test subscriber (URLLC) connected to gNB3 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 8 URLLC",
    "position": { "latitude": 48.122776, "longitude": -1.640064 },
    "imsi": "208011234567898",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 2,
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

echo "Inserting a 9th test subscriber (URLLC) connected to gNB4 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 9 URLLC",
    "position": { "latitude": 48.119092, "longitude": -1.644759 },
    "imsi": "208011234567899",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 2,
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

echo "Inserting a 10th test subscriber (URLLC) connected to gNB4 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.subscribers.insertOne({
    "alias": "Test Subscriber 10 URLLC",
    "position": { "latitude": 48.11763, "longitude": -1.645283 },
    "imsi": "208011234567810",
    "subscribed_rau_tau_timer": 12,
    "network_access_mode": 0,
    "subscriber_status": 0,
    "access_restriction_data": 32,
    "slice": [{
        "sst": 2,
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

echo "All test subscribers have been inserted into the database."
echo "Inserting gNB1 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.gnbs.insertOne({
    "gnbId": "gnb1",
    "name": "gNB 1",
    "location": { "lat": 48.117634, "lng": -1.636123 },
    "supportedSlices": [{ "sst": 1, "sd": "000001" }, { "sst": 2, "sd": "000001" }, { "sst": 3, "sd": "000001" }],
    "schema_version": 1
})'

echo "Inserting gNB2 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.gnbs.insertOne({
    "gnbId": "gnb2",
    "name": "gNB 2",
    "location": { "lat": 48.122221, "lng": -1.63492 },
    "supportedSlices": [{ "sst": 1, "sd": "000001" }, { "sst": 2, "sd": "000001" }, { "sst": 3, "sd": "000001" }],
    "schema_version": 1
})'

echo "Inserting gNB3 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.gnbs.insertOne({
    "gnbId": "gnb3",
    "name": "gNB 3",
    "location": { "lat": 48.121533, "lng": -1.640428 },
    "supportedSlices": [{ "sst": 1, "sd": "000001" }, { "sst": 2, "sd": "000001" }],
    "schema_version": 1
})'

echo "Inserting gNB4 into the database..."
sudo docker exec -it db mongosh open5gs --eval '
db.gnbs.insertOne({
    "gnbId": "gnb4",
    "name": "gNB 4",
    "location": { "lat": 48.118484, "lng": -1.648209 },
    "supportedSlices": [{ "sst": 1, "sd": "000001" }, { "sst": 2, "sd": "000001" }],
    "schema_version": 1
})'