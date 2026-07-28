const TICK_RATE = parseInt(process.env.TICK_RATE) || 1000; // Default to 1000 ms if not set
const HYSTERESIS = parseFloat(process.env.HYSTERESIS) || 0.0005;

export function startMobilityEngine(db){
    console.log("Starting mobility engine...");
    const subscribersCollection = db.collection('subscribers')

    const gnbsCollection = db.collection('gnbs')

    setInterval(async () => {
        try {
            const [movingUEs, allGnbs] = await Promise.all([
                subscribersCollection.find({ isMoving: true }).toArray(),
                gnbsCollection.find({}).toArray()
            ]);
            if (movingUEs.length === 0 || allGnbs.length === 0) return;

            const bulkOps = [];

            for (const ue of movingUEs) {
                const startX = parseFloat(ue.position.latitude);
                const startY = parseFloat(ue.position.longitude);
                const destX = parseFloat(ue.destination.latitude);
                const destY = parseFloat(ue.destination.longitude);
                const speed = parseFloat(ue.speed) || 0.0003;

                const dx = destX - startX;
                const dy = destY - startY;
                const distance = Math.sqrt(dx * dx + dy * dy);

                let newX, newY;
                let isMoving=true;

                if (distance <= speed) {
                    newX = destX;
                    newY = destY;
                    isMoving = false;
                    console.log(`🏁 UE ${ue.imsi} arrivé à destination !`);
                } else {
                    const ratio = speed / distance;
                    newX = startX + dx * ratio;
                    newY = startY + dy * ratio;
                }

                // ======================
                // Algo de handover
                // ======================

                let currentGnbDistance = Infinity;
                let closestGnb = null;
                let minDistance = Infinity;

                for (const gnb of allGnbs) {
                    const gnbDx = newX - parseFloat(gnb.location.lat);
                    const gnbDy = newY - parseFloat(gnb.location.lng);
                    const gnbDistance = Math.sqrt(gnbDx * gnbDx + gnbDy * gnbDy);

                    if (gnbDistance < minDistance) {
                        minDistance = gnbDistance;
                        closestGnb = gnb;
                    }

                    if (String(gnb.gnbId) === String(ue.current_gnb)) {
                        currentGnbDistance = gnbDistance;
                    }
                }

                let updateStatus = ue.handover_status;
                let updatedTargetGnb = ue.target_gnb;

                if (closestGnb && String(closestGnb.gnbId) !== String(ue.current_gnb) && ue.handover_status !== 'pending') {
                    if (minDistance + HYSTERESIS < currentGnbDistance) {
                        console.log(`📡 Handover flaggé pour ${ue.imsi} vers gNB ${closestGnb.gnbId}`);
                        updateStatus = 'pending';
                        updatedTargetGnb = closestGnb.gnbId;
                    }
                }

                bulkOps.push({
                    updateOne: {
                        filter: { imsi: ue.imsi },
                        update: {
                            $set: {
                                'position.latitude': newX,
                                'position.longitude': newY,
                                isMoving: isMoving,
                                handover_status: updateStatus,
                                target_gnb: updatedTargetGnb
                            }
                        }
                    }
                });
            }

            if (bulkOps.length > 0) {
                await subscribersCollection.bulkWrite(bulkOps);
            }
        } catch (error) {
            console.error("Error in mobility engine:", error);
        }
    }, TICK_RATE);
}