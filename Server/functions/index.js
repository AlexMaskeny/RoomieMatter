// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const admin = require("firebase-admin");

admin.initializeApp();

const { onUserSignUp } = require("./user");
const { sendChat, getChats } = require("./chat");
const {
  getChore,
  getChores,
  addChore,
  editChore,
  completeChore,
  deleteChore,
  getEvents,
  addEvent,
  editEvent,
  deleteEvent,
  addUsersToCalendars,
} = require("./calendar");
const { changeStatus } = require("./status");
const { createRoom, deleteRoom, quitRoom, joinRoom } = require("./rooms");

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
exports.changeStatus = changeStatus;
exports.createRoom = createRoom;
exports.deleteRoom = deleteRoom;
exports.quitRoom = quitRoom;
exports.joinRoom = joinRoom;
exports.addUsersToCalendars = addUsersToCalendars;
