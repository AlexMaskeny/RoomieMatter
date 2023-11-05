// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const admin = require("firebase-admin");
const { onUserSignUp } = require("./user/user");
const { sendChat } = require("./Chat/Chat");

admin.initializeApp();

exports.onUserSignUp = onUserSignUp;
exports.sendChat = sendChat;
