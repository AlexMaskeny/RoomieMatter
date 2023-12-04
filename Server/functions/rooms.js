const functions = require("firebase-functions");
const admin = require("firebase-admin");

const db = admin.firestore();

const createRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const roomName = data.roomName;
  const userId = data.userId;

  if (!roomName || !userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Create room requires roomName and userId"
    );
  }

  try {
    const userRef = db.collection("users").doc(userId);

    const roomRef = await db.collection("rooms").add({
      name: roomName,
      createdBy: userRef,
    });

    await db.collection("user_rooms").add({
      room: roomRef,
      user: userRef,
    });

    return { success: true };
  } catch (error) {
    functions.logger.log(error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occured when creating room"
    );
  }
});

const changeRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const roomId = data.roomId;
  const roomName = data.roomName;
  const userIds = data.userIds;

  if (!roomId || !roomName || !userIds) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Change room requires roomId, roomName, and userIds"
    );
  }

  try {
    const roomRef = db.collection("rooms").doc(roomId);

    await roomRef.update({
      name: roomName,
    });

    const userRefs = userIds.map((id) => db.collection("users").doc(id));

    userRefs.forEach(async (userRef) => {
      await db.collection("user_rooms").add({
        room: roomRef,
        user: userRef,
      });
    });

    return { success: true };
  } catch (error) {
    functions.logger.log(error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occured when changing room"
    );
  }
});

const deleteRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const roomId = data.roomId;

  if (!roomId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Delete room requires roomId"
    );
  }

  try {
    const roomRef = db.collection("rooms").doc(roomId);

    await db.collection("user_rooms")
      .where("room", "==", roomRef)
      .get()
      .then((querySnapshot) => {
        querySnapshot.forEach((doc) => {
          doc.ref.delete();
        });
      });

    await roomRef.delete();

    return { success: true };
  } catch (error) {
    functions.logger.log(error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occured when deleting room"
    );
  }
});

module.exports = { createRoom, changeRoom, deleteRoom };
