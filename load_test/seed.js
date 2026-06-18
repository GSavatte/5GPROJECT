const nombre_ues = 200;
const slice_sst = 1;
const slice_sd= "000001";

print(`Lancement de l'injection de ${nombre_ues} UEs dans la base de données...`);

for (let i = 1; i <= nombre_ues; i++) {
  const imsiSuffix = i.toString().padStart(10, "0");
  const imsiVal = "20801" + imsiSuffix;
    const posX = 48.117883 + ((Math.random() - 0.5) * 0.01);
    const posY = -1.640991 + ((Math.random() - 0.5) * 0.02);

  db.subscribers.insertOne({
    "alias": `Test Subscriber ${i} URLLC`,
    "position": { "latitude": posX, "longitude": posY },
    "imsi": imsiVal,
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
    })
}
print(`✅ ${nombre_ues} abonnés préparés avec succès !`);