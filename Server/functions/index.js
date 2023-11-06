// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const admin = require("firebase-admin");
const { onUserSignUp } = require("./user/user");
const { sendChat } = require("./chat/chat");

admin.initializeApp();

exports.onUserSignUp = onUserSignUp;
exports.sendChat = sendChat;
