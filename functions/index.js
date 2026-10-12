const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Triggers when a new document is written to `broadcast_notifications/{docId}`.
 * Broadcasts high-priority FCM notification to the topic `all_users`.
 * When users have their app closed, the Android system tray receives this notification
 * with title, body, and custom data payload. Tapping it directly opens the novel episode!
 */
exports.sendBroadcastNotification = onDocumentCreated(
  'broadcast_notifications/{docId}',
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log('No data associated with event');
      return;
    }

    const data = snap.data();
    if (!data) return;

    const title = data.title || 'New Release!';
    const body = data.body || 'A new chapter has just been published.';
    const novelId = data.novelId || '';
    const episodeId = data.episodeId || '';
    const type = data.type || 'new_episode';
    const topic = data.topic || 'all_users';

    console.log(`Sending FCM broadcast to topic "${topic}": "${title}" - "${body}"`);

    const message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        novelId: novelId,
        episodeId: episodeId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'novels_destiny_notifications',
          priority: 'max',
          defaultSound: true,
          defaultVibrateTimings: true,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully dispatched FCM broadcast:', response);
      await snap.ref.update({
        status: 'sent',
        fcmMessageId: response,
        dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error('Error dispatching FCM broadcast:', error);
      await snap.ref.update({
        status: 'failed',
        error: error.message,
      });
    }
  }
);
