// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const admin = require("firebase-admin");

admin.initializeApp();

const { onUserSignUp } = require("./user");
const { sendChat, getChats } = require("./chat");
const { getChore, getChores, addChore, editChore, completeChore, deleteChore, getEvents, addEvent, deleteEvent } = require("./calendar");

exports.onUserSignUp = onUserSignUp;
exports.sendChat = sendChat;
exports.getChats = getChats;
exports.getChore = getChore;
exports.getChores = getChores;
exports.addChore = addChore;
exports.editChore = editChore;
exports.completeChore = completeChore;
exports.deleteChore = deleteChore;
exports.getEvents = getEvents;
exports.addEvent = addEvent;
exports.editEvent = editEvent;
exports.deleteEvent = deleteEvent;