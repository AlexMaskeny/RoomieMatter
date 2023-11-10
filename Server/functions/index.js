// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const admin = require("firebase-admin");

admin.initializeApp();

const { onUserSignUp } = require("./user");
const { sendChat } = require("./chat");
const { get_chores } = require("./calendar");

exports.onUserSignUp = onUserSignUp;
exports.sendChat = sendChat;
exports.get_chores = get_chores;
