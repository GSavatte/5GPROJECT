const MAX_ITER = 100;

const nb_gnbs = db.gnbs.countDocuments();

if (nb_gnbs === 0) {
    console.error("[ERROR] No gNB found in the database. Please run init_network.js first.");
    quit(1);
}

const uePositions = db.subscribers.find({}, { position: 1 }).toArray()
    .map(ue => ({ latitude: parseFloat(ue.position.latitude), longitude: parseFloat(ue.position.longitude) }));

if (uePositions.length === 0) {
    console.error("[ERROR] No UEs found in the database. Please run init_network.js first.");
    quit(1);
}

console.log(`\n[INFO] K-means optimization of the placement of ${nb_gnbs} gNBs on ${uePositions.length} UEs...`);

const getSqDistance = (p1, p2) => Math.pow(p1.latitude - p2.latitude, 2) + Math.pow(p1.longitude - p2.longitude, 2);

let centroids = [];
for (let i = 0; i < nb_gnbs; i++) {
    const randomUe = uePositions[Math.floor(Math.random() * uePositions.length)];
    centroids.push({
        latitude: randomUe.latitude + 0.0002,
        longitude: randomUe.longitude + 0.0002
    });
}

let converged = false;
let iterations = 0;

while (!converged && iterations < MAX_ITER) {
    iterations++;
    let clusters = Array.from({ length: nb_gnbs }, () => []);

    for (let ue of uePositions) {
        let minC = 0;
        let minDist = getSqDistance(ue, centroids[0]);
        for (let c = 1; c < nb_gnbs; c++) {
            let d = getSqDistance(ue, centroids[c]);
            if (d < minDist) {
                minDist = d;
                minC = c;
            }
        }
        clusters[minC].push(ue);
    }

    let moved = false;

    for (let c = 0; c < nb_gnbs; c++) {
        if (clusters[c].length === 0) continue;
        let sumLat = 0, sumLng = 0;

        for (let p of clusters[c]) {
            sumLat += p.latitude;
            sumLng += p.longitude;
        }

        let newLat = sumLat / clusters[c].length;
        let newLng = sumLng / clusters[c].length;

        if (Math.abs(centroids[c].latitude - newLat) > 1e-6 || Math.abs(centroids[c].longitude - newLng) > 1e-6) {
            moved = true;
        }

        centroids[c] = { latitude: newLat, longitude: newLng };
    }

    if (!moved) {
        converged = true;
        console.log(`[INFO] Convergence reached in ${iterations} iterations.`);
    }
}

if (!converged) {
    console.log(`[WARN] No convergence after ${MAX_ITER} iterations, keeping the last obtained result.`);
}

console.log(`\n[INFO] Updating the positions of the gNBs in the database...`);
for (let c = 0; c < nb_gnbs; c++) {
    const gnbId = `${c + 1}`;
    db.gnbs.updateOne(
        { gnbId: gnbId },
        { $set: { "location.lat": centroids[c].latitude, "location.lng": centroids[c].longitude } }
    );
    console.log(`  gnb${(c + 1).toString().padStart(2, '0')} -> lat: ${centroids[c].latitude.toFixed(6)}, lng: ${centroids[c].longitude.toFixed(6)}`);
}

console.log(`\n[INFO] Recalculating the closest gNB for each UE...`);
const allGnbs = db.gnbs.find({}).toArray();
const subscribers = db.subscribers.find({}).toArray();

let flagged = 0;
const bulkOps = [];

for (const ue of subscribers) {
    const uePos = { latitude: parseFloat(ue.position.latitude), longitude: parseFloat(ue.position.longitude) };

    let closestGnb = null;
    let minDistance = Infinity;
    for (const gnb of allGnbs) {
        const d = getSqDistance(uePos, { latitude: parseFloat(gnb.location.lat), longitude: parseFloat(gnb.location.lng) });
        if (d < minDistance) {
            minDistance = d;
            closestGnb = gnb;
        }
    }

    if (closestGnb && String(closestGnb.gnbId) !== String(ue.current_gnb) && ue.handover_status !== 'pending') {
        bulkOps.push({
            updateOne: {
                filter: { imsi: ue.imsi },
                update: { $set: { handover_status: 'pending', target_gnb: closestGnb.gnbId } }
            }
        });
        flagged++;
    }
}

if (bulkOps.length > 0) {
    db.subscribers.bulkWrite(bulkOps);
}

console.log(`\n✅ Optimization completed. ${flagged} UE(s) flagged for handover to their new closest gNB.`);
console.log(`   Make sure that mobility_controller.sh is running for the reconnections to execute.`);