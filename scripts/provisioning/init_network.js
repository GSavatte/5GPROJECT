const nb_ues = parseInt(process.env.NB_UES);
const nb_gnbs = parseInt(process.env.NB_GNBS);

if (isNaN(nb_ues) || nb_ues <= 0 || isNaN(nb_gnbs) || nb_gnbs <= 0) {
    console.error("[ERROR] : NB_UES and NB_GNBS environment variables must be positive integers.");
    process.exit(1);
}

console.log(`\n[INFO] Cleaning up the database...`);
db.subscribers.deleteMany({});
db.gnbs.deleteMany({});

let uePositions = [];

console.log(`\n[INFO] Generating ${nb_ues} UEs...`);
for (let i = 1; i <= nb_ues; i += 3) {
    const imsiSuffix = i.toString().padStart(10, "0");
    const imsiSuffix2 = (i+1).toString().padStart(10, "0");
    const imsiSuffix3 = (i+2).toString().padStart(10, "0");

    const posX = 48.117883 + ((Math.random() - 0.5) * 0.01);
    const posY = -1.640991 + ((Math.random() - 0.5) * 0.02);

    const posX2 = 48.117883 + ((Math.random() - 0.5) * 0.01);
    const posY2 = -1.640991 + ((Math.random() - 0.5) * 0.02);

    const posX3 = 48.117883 + ((Math.random() - 0.5) * 0.01);
    const posY3 = -1.640991 + ((Math.random() - 0.5) * 0.02);

    uePositions.push({ latitude: posX, longitude: posY });
    uePositions.push({ latitude: posX2, longitude: posY2 });
    uePositions.push({ latitude: posX3, longitude: posY3 });

    db.subscribers.insertOne({
        "alias": `Test Subscriber ${i} URLLC`,
        "position": { "latitude": posX, "longitude": posY },
        "imsi": "20801" + imsiSuffix,
        "subscribed_rau_tau_timer": 12,
        "network_access_mode": 0,
        "subscriber_status": 0,
        "access_restriction_data": 32,
        "slice": [{ "sst": 1, "sd": "000001", "default_indicator": true, "session": [{ "name": "internet", "type": 3, "pcc_rule": [], "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } }, "qos": { "index": 9, "arp": { "priority_level": 8, "pre_emption_capability": 1, "pre_emption_vulnerability": 1 } } }] }],
        "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
        "security": { "k": "00000000000000000000000000000000", "amf": "8000", "op": null, "opc": "00000000000000000000000000000000", "sqn": NumberLong("0") },
        "schema_version": 1
    });

    if ((i + 1) <= nb_ues) {
        db.subscribers.insertOne({
            "alias": `Test Subscriber ${i + 1} URLLC`,
            "position": { "latitude": posX2, "longitude": posY2 },
            "imsi": "20801" + imsiSuffix2,
            "subscribed_rau_tau_timer": 12,
            "network_access_mode": 0,
            "subscriber_status": 0,
            "access_restriction_data": 32,
            "slice": [{ "sst": 2, "sd": "000001", "default_indicator": true, "session": [{ "name": "internet", "type": 3, "pcc_rule": [], "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } }, "qos": { "index": 9, "arp": { "priority_level": 8, "pre_emption_capability": 1, "pre_emption_vulnerability": 1 } } }] }],
            "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
            "security": { "k": "00000000000000000000000000000000", "amf": "8000", "op": null, "opc": "00000000000000000000000000000000", "sqn": NumberLong("0") },
            "schema_version": 1
        });
    }

    if ((i + 2) <= nb_ues) {
        db.subscribers.insertOne({
            "alias": `Test Subscriber ${i + 2} URLLC`,
            "position": { "latitude": posX3, "longitude": posY3 },
            "imsi": "20801" + imsiSuffix3,
            "subscribed_rau_tau_timer": 12,
            "network_access_mode": 0,
            "subscriber_status": 0,
            "access_restriction_data": 32,
            "slice": [{ "sst": 3, "sd": "000001", "default_indicator": true, "session": [{ "name": "internet", "type": 3, "pcc_rule": [], "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } }, "qos": { "index": 9, "arp": { "priority_level": 8, "pre_emption_capability": 1, "pre_emption_vulnerability": 1 } } }] }],
            "ambr": { "uplink": { "value": 1, "unit": 3 }, "downlink": { "value": 1, "unit": 3 } },
            "security": { "k": "00000000000000000000000000000000", "amf": "8000", "op": null, "opc": "00000000000000000000000000000000", "sqn": NumberLong("0") },
            "schema_version": 1
        });
    }
}

console.log(`\n[INFO] Random placement of ${nb_gnbs} gNBs...`);
for (let c = 0; c < nb_gnbs; c++) {
    const randomUe = uePositions[Math.floor(Math.random() * uePositions.length)];

    db.gnbs.insertOne({
        "gnbId": `${c + 1}`,
        "name": `gnb${(c + 1).toString().padStart(2, '0')}`,
        "location": {
            "lat": randomUe.latitude + 0.0002,
            "lng": randomUe.longitude + 0.0002
        },
        "supportedSlices": [{ "sst": 1, "sd": "000001" }, { "sst": 2, "sd": "000001" }, { "sst": 3, "sd": "000001" }],
        "schema_version": 1
    });
}

console.log(`\n[INFO] Initialization completed successfully. Run optimize_gnb_placement.js whenever you want to optimize the placement of gNBs via K-means.`);