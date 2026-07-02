const MAX_ITER=100;

const nb_ues = parseInt(process.env.NB_UES);
const nb_gnbs = parseInt(process.env.NB_GNBS);


if (isNaN(nb_ues) || nb_ues <= 0 || isNaN(nb_gnbs) || nb_gnbs <= 0) {
    console.error("❌ Erreur : Les variables NB_UES et NB_GNBS doivent être des nombres valides.");
    process.exit(1);
}

db.subscribers.deleteMany({});
db.gnbs.deleteMany({});

console.log(`Lancement de l'injection de ${nb_ues} UEs dans la base de données...`);

let uePositions = [];

for (let i = 1; i <= nb_ues*2; i+=2) {
    const imsiSuffix = i.toString().padStart(10, "0");
    const imsiSuffix2 = (i+1).toString().padStart(10, "0");
    const imsiVal = "20801" + imsiSuffix;
    const imsiVal2 = "20801" + imsiSuffix2;
    const posX = 48.117883 + ((Math.random() - 0.5) * 0.01);
    const posY = -1.640991 + ((Math.random() - 0.5) * 0.02);

    const posX2 = 48.117883 + ((Math.random() - 0.5) * 0.01);
    const posY2 = -1.640991 + ((Math.random() - 0.5) * 0.02);

    uePositions.push({ latitude: posX, longitude: posY });
    uePositions.push({ latitude: posX2, longitude: posY2 });


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

    db.subscribers.insertOne({
        "alias": `Test Subscriber ${i+1} URLLC`,
        "position": { "latitude": posX2, "longitude": posY2 },
        "imsi": imsiVal2,
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
    })
}

optimizeGnbPlacement(nb_gnbs, uePositions);

function optimizeGnbPlacement(nb_gnbs, uePositions) {
    console.log(`📡 Optimisation du placement de $${nb_gnbs} gnbs`)

    let centroids = [];

    for (let i=0; i<nb_gnbs; i++) {
        const randomUe = uePositions[Math.floor(Math.random() * uePositions.length)];
        centroids.push(randomUe);
    }

    const getSqDistance = (p1,p2) => Math.pow(p1.latitude - p2.latitude, 2)+Math.pow(p1.longitude - p2.longitude, 2);

    let converged = false;
    let iterations=0;

    while (!converged && iterations<MAX_ITER) {
        let clusters = Array.from({ length: nb_gnbs }, () => []);

        for (let ue of uePositions) {
            let minC = 0;
            let minDist = getSqDistance(ue, centroids[0]);
            for (let c=1; c<nb_gnbs; c++) {
                let d = getSqDistance(ue, centroids[c]);
                if (d<minDist){
                    minDist=d;
                    minC=c;
                }
            }
            clusters[minC].push(ue);
        }
        let moved = false;
        for(let c = 0; c<nb_gnbs; c++) {
            if(clusters[c].length===0) continue;
            let sumLat=0, sumLng=0;
            for(let p of clusters[c]) {
                sumLat+=p.latitude;
                sumLng+=p.longitude;
            }
            let newLat = sumLat/clusters[c].length;
            let newLng = sumLng/clusters[c].length;
            if(Math.abs(centroids[c].latitude-newLat)>1e-6 || Math.abs(centroids[c].longitude-newLng)>1e-6){
                moved = true;
            }

            centroids[c] = { latitude: newLat, longitude: newLng };
        }
        if(!moved) converged=true;
        iterations++;
    }

    console.log(`✅ Optimisation terminée en ${iterations} itérations !`);

    console.log(`Insertion des positions optimisées dans la base de données...`);

    for(let c=0; c<nb_gnbs; c++) {
        db.gnbs.insertOne({
            "gnbId": `${c}`,
            "name": `gnb${c}`,
            "location": { "lat": centroids[c].latitude, "lng": centroids[c].longitude },
            "supportedSlices": [{ "sst": 1, "sd": "000001" }, { "sst": 2, "sd": "000001" }, { "sst": 3, "sd": "000001" }],
            "schema_version": 1
        });
    }

    console.log(`✅ Insertion terminée !`);

}