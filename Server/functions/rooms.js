const functions = require("firebase-functions");
const admin = require("firebase-admin");
const db = admin.firestore();
const {
  createNewCalendars,
} = require("./calendar");

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
    const res = await createNewCalendars(data.token);

    const userRef = db.collection("users").doc(userId);

    const roomRef = await db.collection("rooms").add({
      name: roomName,
      owner: userRef,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      typing: [],
      choresCalendarId: res.choresCalendarId, 
      eventsCalendarId: res.eventsCalendarId,
    });

    await db.collection("user_rooms").add({
      room: roomRef,
      user: userRef,
      activity: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      membership_status: "member",
      status: "home",
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

const quitRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const roomId = data.roomId;
  const userId = data.userId;

  if (!roomId || !userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Quit room requires roomId and userId"
    );
  }

  try {
    const roomRef = db.collection("rooms").doc(roomId);
    const userRef = db.collection("users").doc(userId);

    await db.collection("user_rooms")
      .where("room", "==", roomRef)
      .where("user", "==", userRef)
      .get()
      .then((querySnapshot) => {
        querySnapshot.forEach((doc) => {
          doc.ref.delete();
        });
      });

    return { success: true };
  } catch (error) {
    functions.logger.log(error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occured when quitting room"
    );
  }
});

const joinRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const roomId = data.roomId;
  const userId = data.userId;

  if (!roomId || !userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Join room requires roomId and userId"
    );
  }

  try {
    const roomRef = db.collection("rooms").doc(roomId);
    const userRef = db.collection("users").doc(userId);

    const room = await roomRef.get();
    if (!room.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Room does not exist"
      );
    }

    await db.collection("user_rooms").add({
      room: roomRef,
      user: userRef,
      activity: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      membership_status: "member",
      status: "home",
    });

    return { success: true };
  } catch (error) {
    functions.logger.log(error);
    throw new functions.https.HttpsError(
      "internal",
      "An error occured when joining room"
    );
  }
});

module.exports = { createRoom, deleteRoom, quitRoom, joinRoom };
