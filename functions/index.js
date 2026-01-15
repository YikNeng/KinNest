// 1. IMPORT REQUIRED MODULES
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// 2. INITIALIZE THE APP
if (!admin.apps.length) {
    admin.initializeApp();
}

// ==================================================================
// FUNCTION 1: CHECK OVERDUE REMINDERS (The Scheduler)
// ==================================================================
exports.checkOverdueReminders = onSchedule("every 5 minutes", async (event) => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();

    console.log("--- Starting Overdue Check ---");

    // 1. Find overdue items that haven't been notified yet
    const snapshot = await db.collection('reminders')
        .where('scheduledTime', '<', now)
        .where('isOverdueNotified', '==', false)
        .get();

    if (snapshot.empty) {
        console.log("No overdue reminders found.");
        return;
    }

    console.log(`FOUND ${snapshot.size} overdue reminders. Processing...`);

    const batch = db.batch();

    // 2. Process each overdue reminder
    for (const doc of snapshot.docs) {
        const data = doc.data();
        console.log(`Processing Reminder: "${data.title}" (ID: ${doc.id}, Group: ${data.groupId})`);

        // A. Mark as notified immediately to prevent loops
        batch.update(doc.ref, { isOverdueNotified: true });

        if (!data.groupId) {
            console.error(`ERROR: Reminder ${doc.id} has no groupId! Skipping notification.`);
            continue;
        }

        try {
            // B. Fetch Group to find Caregivers
            const groupDoc = await db.collection('groups').doc(data.groupId).get();

            if (!groupDoc.exists) {
                console.error(`ERROR: Group ${data.groupId} does not exist!`);
                continue;
            }

            const groupData = groupDoc.data();

            // --- NEW SAFETY LOGIC START ---

            // 1. Get the "Active Member List" (Source of Truth)
            // This prevents notifying users who were kicked out but still have an old "accepted" invitation.
            const activeMemberIds = groupData.memberIds || [];

            let targets = [];

            // 2. Always notify the Admin (The Group Owner)
            if (groupData.adminId) {
                targets.push(groupData.adminId);
            }

            // 3. Find "Caregivers" from the invitations array
            if (groupData.invitations && Array.isArray(groupData.invitations)) {

                // Step 3a: Get UIDs of everyone who accepted a 'caregiver' role
                const potentialCaregivers = groupData.invitations
                    .filter(inv =>
                        inv.status === 'accepted' &&
                        inv.role === 'caregiver' &&
                        inv.acceptedBy // The UID of the user
                    )
                    .map(inv => inv.acceptedBy);

                // Step 3b: CROSS-CHECK against 'activeMemberIds'
                // This ensures we ONLY notify caregivers who are still currently in the group.
                const activeCaregivers = potentialCaregivers.filter(uid =>
                    activeMemberIds.includes(uid)
                );

                targets = [...targets, ...activeCaregivers];
            }

            // 4. Remove duplicates (in case Admin is also listed as a caregiver)
            const finalRecipients = [...new Set(targets)];
            // --- NEW SAFETY LOGIC END ---

            console.log(`Found ${finalRecipients.length} active recipients to notify: ${JSON.stringify(finalRecipients)}`);

            if (finalRecipients.length === 0) {
                console.log("WARNING: No active caregivers or admin found to notify.");
            }

            // C. Create Notification for EACH Recipient
            finalRecipients.forEach(uid => {
                if (!uid) return;

                const notifRef = db.collection('users').doc(uid).collection('notifications').doc();
                console.log(`Queueing notification for User: ${uid}`);

                batch.set(notifRef, {
                    title: 'Overdue Reminder',
                    body: `Alert: "${data.title}" is overdue!`,
                    type: 'overdue',
                    relatedId: data.groupId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });

        } catch (e) {
            console.error(`CRITICAL ERROR processing group ${data.groupId}:`, e);
        }
    }

    // 3. Commit all changes (Updates to reminders + New notifications)
    await batch.commit();
    console.log("Batch commit complete. Check 'sendPushNotification' logs next.");
});


// ==================================================================
// FUNCTION 2: SEND PUSH NOTIFICATION (Enhanced)
// ==================================================================
exports.sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notificationData = snapshot.data();
    const userId = event.params.userId;
    const db = admin.firestore();

    console.log(`New notification detected for User: ${userId}`);

    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
        console.log(`ABORT: No FCM token found for user ${userId}.`);
        return;
    }

    const message = {
        notification: {
            title: notificationData.title,
            body: notificationData.body,
        },
        token: fcmToken,
        data: {
            type: notificationData.type || 'general',
            relatedId: notificationData.relatedId || '',
        },
        android: {
            notification: {
                channelId: "high_importance_channel",
                priority: "high",
            }
        }
    };

    try {
        await admin.messaging().send(message);
        console.log(`SUCCESS: Push notification sent to ${userId}`);
    } catch (error) {
        console.error('ERROR sending FCM message:', error);

        // --- NEW AUTO-CLEANUP LOGIC ---
        if (error.code === 'messaging/registration-token-not-registered' ||
            error.code === 'messaging/invalid-argument') {

            console.log(`Token invalid for user ${userId}. Deleting from Firestore to prevent future errors.`);

            // Delete the bad token so we don't try again
            await db.collection('users').doc(userId).update({
                fcmToken: admin.firestore.FieldValue.delete()
            });
        }
    }
});