const functions = require("firebase-functions");

const sendChat = functions.https.onCall((data, context) => {
  // Your function logic here
  return { message: "New product function response" };
});

module.exports = { sendChat };
