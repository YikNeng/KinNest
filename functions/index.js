// 1. IMPORT v2 SCHEDULER AND ADMIN
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

// 2. INITIALIZE THE APP
admin.initializeApp();

// 3. YOUR SCHEDULED FUNCTION (Using v2 Syntax)
exports.checkOverdueReminders = onSchedule("every 5 minutes", async (event) => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();

    // Query for overdue, uncompleted reminders that haven't been notified yet
    const snapshot = await db.collection('reminders')
        .where('scheduledTime', '<', now)
        .where('isCompleted', '==', false)
        // Ensure you handle the case where 'isOverdueNotified' might not exist yet
        .where('isOverdueNotified', '==', false)
        .get();

    if (snapshot.empty) {
        console.log("No overdue reminders found.");
        return null;
    }

    const batch = db.batch();
    let updateCount = 0;

    snapshot.forEach((doc) => {
        const reminder = doc.data();

        // --- LOGIC TO SEND NOTIFICATION ---
        // In a real app, you would fetch the user's FCM token here 
        // and send a push notification via admin.messaging().send(...)
        console.log(`Sending Alert: Reminder "${reminder.title}" is overdue!`);

        // --- MARK AS NOTIFIED ---
        // We update the flag so we don't spam the user every 5 minutes
        batch.update(doc.ref, { isOverdueNotified: true });
        updateCount++;
    });

    if (updateCount > 0) {
        await batch.commit();
    }

    console.log(`Processed ${updateCount} overdue reminders.`);
    return null;
});

// NEW: Listen for new notifications added to a user's profile
exports.sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
        return;
    }

    const notificationData = snapshot.data();
    const userId = event.params.userId;
    const db = admin.firestore();

    // 1. Get the user's FCM token from their profile
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) {
        console.log(`No token found for user ${userId}`);
        return;
    }

    // 2. Construct the message payload
    const message = {
        notification: {
            title: notificationData.title,
            body: notificationData.body,
        },
        token: fcmToken,
        data: {
            // Add extra data if needed (e.g., for navigation)
            type: notificationData.type || 'general',
            relatedId: notificationData.relatedId || '',
        },
        android: {
            notification: {
                channelId: "high_importance_channel", // Must match AndroidManifest
                priority: "high",
            }
        }
    };

    // 3. Send the message
    try {
        await admin.messaging().send(message);
        console.log(`Notification sent to user ${userId}`);

        // Optional: Mark as "sent" in Firestore
        await snapshot.ref.update({ status: 'sent' });
    } catch (error) {
        console.error('Error sending notification:', error);
    }
});