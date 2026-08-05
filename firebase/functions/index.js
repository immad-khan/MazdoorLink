// FCM delivery for MazdoorLink chat.
//
// Triggered whenever a message is created in a conversation. Sends a push
// notification to the *other* participant using their saved FCM token.
//
// Deploy with:  firebase deploy --only functions
// (requires firebase-tools: `npm i -g firebase-tools`, then `firebase login`)

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.sendMessageNotification = onDocumentCreated(
  'conversations/{conversationId}/messages/{messageId}',
  async (event) => {
    const msg = event.data.data();
    if (!msg || !msg.text) return;

    const senderId = msg.senderId || '';
    const conversationId = event.params.conversationId;

    const convSnap = await getFirestore()
      .collection('conversations')
      .doc(conversationId)
      .get();
    const conv = convSnap.exists ? convSnap.data() : {};
    const participants = conv.participants || [];
    const recipientId = participants.find((id) => id !== senderId);
    if (!recipientId) return;

    const userSnap = await getFirestore()
      .collection('users')
      .doc(recipientId)
      .get();
    const token = userSnap.exists ? userSnap.data().fcmToken : null;
    if (!token) return;

    const names = conv.participantNames || {};
    const images = conv.participantImages || {};
    const senderName = names[senderId] || 'Worker';
    const senderImage = images[senderId] || '';

    const message = {
      notification: {
        title: senderName,
        body: msg.text,
      },
      data: {
        conversationId,
        otherName: senderName,
        otherImage: senderImage,
        body: msg.text,
      },
      token,
      android: { priority: 'high' },
    };

    await getMessaging().send(message);
  }
);
