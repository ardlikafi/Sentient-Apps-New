const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 1. Kirim Notifikasi Push saat ada Pesan Chat Baru
 * Berjalan otomatis di Google Cloud saat dokumen chat baru dibuat di Firestore.
 */
exports.onNewChatMessage = onDocumentCreated("chat_rooms/{roomId}/messages/{messageId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return null;

  const data = snapshot.data();
  const receiverId = data.receiver_id;
  const senderName = data.sender_name || "Seseorang";
  const text = data.text || "Mengirim pesan baru";
  const type = data.type || "text";

  if (!receiverId) return null;

  // Jika ajakan catur sudah memiliki challenge_id, onNewChessChallenge yang akan mengirim notifikasinya
  // untuk mencegah notifikasi ganda ke penerima.
  if (type === "chess_invite" && data.challenge_id) {
    console.log("Skipping onNewChatMessage for chess_invite because onNewChessChallenge handles it.");
    return null;
  }

  try {
    // Ambil token FCM penerima dari Firestore
    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcm_token;
    if (!fcmToken) {
      console.log(`No FCM token found for recipient: ${receiverId}`);
      return null;
    }

    const title = type === "chess_invite" ? "⚔️ Incoming Chess Challenge!" : `💬 ${senderName}`;
    const body = type === "chess_invite" ? `${senderName} challenged you to an online chess match!` : text;
    const payload = type === "chess_invite"
      ? `challenge:${data.challenge_id || ""}`
      : `chat:${data.sender_id || ""}:${senderName}:${data.sender_avatar || ""}`;

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
        sender_id: data.sender_id || "",
        sender_name: senderName,
        payload: payload,
        title: title,
        body: body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sentient_high_importance_channel",
          sound: "default",
          defaultSound: true,
          defaultVibrateTimings: true,
          priority: "max",
          visibility: "public",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            alert: {
              title: title,
              body: body,
            },
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log("FCM Chat Notification sent successfully:", response);
  } catch (error) {
    console.error("Error sending FCM Chat notification:", error);
  }
  return null;
});

/**
 * 2. Kirim Notifikasi Push saat ada Tantangan Catur Baru dari Lobby atau Chat
 */
exports.onNewChessChallenge = onDocumentCreated("chess_challenges/{challengeId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return null;

  const data = snapshot.data();
  const receiverId = data.receiver_id;
  const senderName = data.sender_name || "Pemain";

  if (!receiverId) return null;

  try {
    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data().fcm_token;
    if (!fcmToken) {
      console.log(`No FCM token found for challenge recipient: ${receiverId}`);
      return null;
    }

    const timeMinutes = Math.round((data.time_control || 600) / 60);
    const timeText = timeMinutes > 0 ? ` (${timeMinutes} Min)` : "";
    const title = "⚔️ Incoming Chess Challenge!";
    const body = `${senderName} invited you to play chess online${timeText}. Tap to accept!`;
    const payload = `challenge:${event.params.challengeId}`;

    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "challenge",
        challenge_id: event.params.challengeId,
        sender_id: data.sender_id || "",
        sender_name: senderName,
        payload: payload,
        title: title,
        body: body,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "sentient_high_importance_channel",
          sound: "default",
          defaultSound: true,
          defaultVibrateTimings: true,
          priority: "max",
          visibility: "public",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            alert: {
              title: title,
              body: body,
            },
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log("FCM Challenge Notification sent successfully:", response);
  } catch (error) {
    console.error("Error sending FCM Challenge notification:", error);
  }
  return null;
});

/**
 * 3. Kirim Notifikasi Push ke Penantang saat Tantangannya Diterima oleh Lawan
 */
exports.onChallengeAccepted = onDocumentUpdated("chess_challenges/{challengeId}", async (event) => {
  const beforeData = event.data.before ? event.data.before.data() : null;
  const afterData = event.data.after ? event.data.after.data() : null;

  if (!beforeData || !afterData) return null;

  // Hanya picu jika status berubah dari pending menjadi accepted
  if (beforeData.status !== "accepted" && afterData.status === "accepted") {
    const senderId = afterData.sender_id;
    const receiverName = afterData.receiver_name || "Lawan";
    const matchId = afterData.match_id;

    if (!senderId) return null;

    try {
      const userDoc = await admin.firestore().collection("users").doc(senderId).get();
      if (!userDoc.exists) return null;

      const fcmToken = userDoc.data().fcm_token;
      if (!fcmToken) {
        console.log(`No FCM token found for challenge sender: ${senderId}`);
        return null;
      }

      const title = "🎮 Opponent Entered Chess Game!";
      const body = `${receiverName} accepted your chess challenge. Join the match now!`;
      // Format payload yang diharapkan Flutter: match:<matchId>:<opponentName>:<playerColor>
      const payload = `match:${matchId || ""}:${receiverName}:white`;

      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "challenge_accepted",
          match_id: matchId || "",
          opponent_name: receiverName,
          payload: payload,
          title: title,
          body: body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "sentient_high_importance_channel",
            sound: "default",
            defaultSound: true,
            defaultVibrateTimings: true,
            priority: "max",
            visibility: "public",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              alert: {
                title: title,
                body: body,
              },
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log("FCM Challenge Accepted Notification sent successfully:", response);
    } catch (error) {
      console.error("Error sending FCM Challenge Accepted notification:", error);
    }
  }
  return null;
});
