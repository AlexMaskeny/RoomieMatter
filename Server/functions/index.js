// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/* CREATE USER TABLE ROW: 
    - This creates the user table entry for the user. 
    - The id of the row is the google uid
*/
exports.onUserSignUp = functions.auth.user().onCreate((user) => {
  const usersRef = admin.firestore().collection("users");

  const userData = {
    uuid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    provider: "google",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  return usersRef.doc(user.uid).set(userData);
});
