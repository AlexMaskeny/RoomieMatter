const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

const changeStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const userId = data.userId;
  const roomId = data.roomId;
  const status = data.status;

  if (!userId || !roomId || !status) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Change status requires userId, roomId, and status"
    );
  }

  functions.logger.log(status);

  try {
    const userRef = db.collection("users").doc(userId);
    const roomRef = db.collection("rooms").doc(roomId);

    const userRoomSnapshot = await db
      .collection("user_rooms")
      .where("room", "==", roomRef)
      .where("user", "==", userRef)
      .get();

    const userRoomId = userRoomSnapshot.docs[0].id;
    functions.logger.log(userRoomId)
    db.collection("user_rooms").doc(userRoomId).update({
      status,
    });

    return { success: true };
  } catch (error) {
    functions.logger.log(error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occured when changing status"
    );
  }
});

module.exports = { changeStatus };
