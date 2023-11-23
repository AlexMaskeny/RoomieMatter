// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const admin = require("firebase-admin");

admin.initializeApp();

const { onUserSignUp } = require("./user");
const { sendChat, getChats } = require("./chat");
const { getChores, testGetChores } = require("./calendar");

exports.onUserSignUp = onUserSignUp;
exports.sendChat = sendChat;
exports.getChats = getChats;
exports.getChores = getChores;
exports.testGetChores = testGetChores;
