const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { google } = require("googleapis");
const { UserDimensions } = require("firebase-functions/v1/analytics");

const db = admin.firestore();

/* NEW ROOM FUNCTIONS */

/* REQUIRES: token
 * EFFECTS: creates new chores calendar and events calendar
 * RETURNS: status, choresCalendarId, eventsCalendarId
 */
async function createNewCalendars(tokenInput) {
  const token = tokenInput;
  functions.logger.log(token);
  const oAuth2Client = new google.auth.OAuth2();
  oAuth2Client.setCredentials({ access_token: token });
  const calendar = google.calendar({ version: "v3", auth: oAuth2Client });

  // create choresCalendarId
  let choreRes = {};
  try {
    choreRes = await calendar.calendars.insert({
      resource: {
        summary: "RoomieMatter Chores"
      }
    });
  } catch (error) {
    throw new functions.https.HttpsError("Error creating new event calendar:", error.message);
  }

  functions.logger.log(choreRes?.data ?? "Failurreeee!");
  functions.logger.log(choreRes);

  if (!choreRes?.data || choreRes?.data.length == 0) {
    throw new functions.https.HttpsError("Error creating new chore calendar:", error.message);
  }

  // create choresCalendarId
  const eventRes = await calendar.calendars.insert({
    resource: {
      summary: "RoomieMatter Events"
    }
  });

  functions.logger.log(eventRes?.data ?? "Failurreeee!");
  functions.logger.log(eventRes);

  if (!eventRes?.data || eventRes?.data.length == 0) {
    throw new functions.https.HttpsError("Error creating new event calendar:", error.message);
  }
  
  return { status: true, choresCalendarId: choreRes.data.id,  eventsCalendarId: eventRes.data.id};
}

/* REQUIRES: token, roomId
 * EFFECTS: add all new users to existing chores and events calendar
 * RETURNS: status
 */
const addUsersToCalendars = functions.https.onCall(async (data, context) => {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.roomId || data.roomId.length == 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing roomId"
    );
  }
  
  // get calendar IDs
  const choresCalendarId = await getCalendarId(data.roomId, "chore");
  const eventsCalendarId = await getCalendarId(data.roomId, "event");
  const calendarIds = [choresCalendarId, eventsCalendarId];

  // get user emails
  const roomRef = db.collection("rooms").doc(data.roomId);
  const users = await db.collection("user_rooms").where("room", "==", roomRef).get();
  functions.logger.log(users.docs);

  // for each user
  for (const userDoc of users.docs) {
    const userSnapshot = await userDoc.get("user").get();
    if (!userSnapshot) {
      continue;
    }
    const email = userSnapshot.get("email");
    functions.logger.log(email);
    
    for (const calendarId of calendarIds) {
      // Get the current ACL (Access Control List) of the calendar
      const acl = await calendar.acl.list({ calendarId });
  
      // Check if the user is already in the ACL
      const existingRule = acl.data.items.find((rule) => rule.scope.value === email);
  
      if (!existingRule) {
        // If the user is not in the ACL, add a new rule
        const res = await calendar.acl.insert({
          calendarId,
          requestBody: {
            role: 'writer',
            scope: {
              type: 'user',
              value: email,
            },
          },
        });
  
        if (!res?.data || res?.data.length == 0) {
          throw new functions.https.HttpsError(
            "Error adding user to calendar:",
            error.message
          );
        }
        functions.logger.log(`User ${email} added to calendar`);
      } else {
        functions.logger.log(`User ${email} already added to calendar`)
      }
    }
  }

  return { status: true };
});

/* HELPER FUNCTIONS */

function createOAuth(auth, tokenInput) {
  if (!auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const token = tokenInput;
  functions.logger.log(token);
  const oAuth2Client = new google.auth.OAuth2();
  oAuth2Client.setCredentials({ access_token: token });
  return google.calendar({ version: "v3", auth: oAuth2Client });
}

/*
  REQUIRES: a string 'email'
  RETURNS: a string 'uuid'
*/
async function getUuidFromEmail(email) {
  const user = await db.collection("users").where("email", "==", email).get();

  //This is an array because email isn't the primary key (duplicates are allowed)
  const plainUser = user.docs.map((doc) => doc.data());

  return plainUser[0].uuid;
}

/*
  REQUIRES: a string 'uuid'
  RETURNS: a string 'email'
*/
async function getEmailFromUuid(uuid) {
  //Uuid is a seperate param, but we also make the primary key the uuid
  const user = await db.collection("users").doc(uuid).get();

  return await user.data().email;
}

// REQUIRES: roomId, calendarType = {"chore", "event"}
// RETURNS: calendarId
async function getCalendarId(roomId, calendarType) {
  if (!roomId || roomId.length == 0) {
    throw new functions.https.HttpsError(
      "invalid input: missing roomId"
    );
  }

  const room = await db.collection("rooms").doc(roomId).get();

  if (calendarType == "chore") {
    return await room.data().choresCalendarId;
  } else {
    return await room.data().eventsCalendarId;
  }
}

/* REQUIRES: instanceId, calendar, roomId
 * RETURNS: eventId
 */
async function getEventId(instanceId, calendar, roomId) {
  // if non-recurring event, eventId = instanceId
  if (!instanceId.includes("_")) {
    functions.logger.log("Non-recurring event");
    return instanceId;
  }

  // recurring event, find eventId
  functions.logger.log("Recurring event");
  let res = {};
  const choresCalendarId = await getCalendarId(roomId, "chore");
  try {
    res = await calendar.events.get({
      calendarId: choresCalendarId,
      eventId: instanceId,
    });
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  functions.logger.log(res);
  if (!res.data || res.data.length === 0) {
    functions.logger.log("Invalid instanceId");
    return { status: false };
  }

  if (!res.data.recurringEventId) {
    functions.logger.log("recurringEventId not found");
    return { status: false };
  }

  functions.logger.log("eventId = ", res.data.recurringEventId);
  return res.data.recurringEventId;
}

/* REQUIRES: eventId, calendar, roomId
 *           only recurring event
 * RETURNS: instanceId
 */
async function getInstanceId(eventId, calendar, roomId) {
  // if instanceID, throws error
  if (eventId.includes("_")) {
    throw new functions.https.HttpsError("Expects eventId only");
  }

  // find instanceId
  let res = {};
  const choresCalendarId = await getCalendarId(roomId, "chore");
  try {
    res = await calendar.events.instances({
      calendarId: choresCalendarId,
      eventId: eventId,
    });
  } catch (error) {
    functions.logger.error("Error getting instances:", error.message);
    throw new functions.https.HttpsError(
      "Error getting instances:",
      error.message
    );
  }

  if (!res.data.items || res.data.items.length === 0) {
    functions.logger.log("No next instances found");
    return "";
  }

  functions.logger.log(res);

  return res.data.items[0].id;
}

// takes in Google's raw event and returns a chore object with fields we need
// instanceId, eventName, date, author, (frequency, description, assignedRoommates)
async function parseChore(instanceId, event) {
  if (!event || event.length == 0) {
    return {};
  }

  functions.logger.log(event.creator.email);
  const creator = await getUuidFromEmail(event.creator.email);

  let eventData = {
    instanceId: instanceId,
    eventName: event.summary,
    date: event.start.date,
    author: creator,
  };

  functions.logger.log(event.recurrence);

  if (event.recurrence && event.recurrence.length != 0) {
    const startIndex = event.recurrence[0].indexOf("FREQ=") + 5;
    let endIndex = event.recurrence[0].indexOf(";");
    if (endIndex == -1) {
      endIndex = event.recurrence[0].length;
    }
    const freq = event.recurrence[0].substring(startIndex, endIndex);
    functions.logger.log(freq);

    switch (freq) {
      case "DAILY":
        eventData.frequency = "Daily";
        break;
      case "WEEKLY":
        if (freq.includes("INTERVAL=2")) {
          eventData.frequency = "Biweekly";
        } else {
          eventData.frequency = "Weekly";
        }
        break;
      case "MONTHLY":
        eventData.frequency = "Monthly";
        break;
      default:
        throw new functions.https.HttpsError("error converting frequency");
    }
  } else {
    eventData.frequency = "Once";
  }

  if (event.description) {
    eventData.description = event.description;
  }

  if (event.attendees) {
    let assignees = [];
    functions.logger.log(event.attendees);
    for (const attendee of event.attendees) {
      if (attendee.responseStatus == 'declined') {
        continue;
      }
      const uuid = await getUuidFromEmail(attendee.email);
      assignees.push(uuid);
    }
    eventData.assignedRoommates = assignees;
  }

  functions.logger.log(eventData);

  return eventData;
}

async function parseEvent(event) {
  functions.logger.log(event.creator.email);
  const creator = await getUuidFromEmail(event.creator.email);

  let eventData = {
    eventId: event.id,
    eventName: event.summary,
    startDatetime: event.start.dateTime,
    endDatetime: event.end.dateTime,
    author: creator,
  };

  if (event.description) {
    eventData.description = event.description;
  }

  if (event.attendees) {
    let guests = [];
    functions.logger.log(event.attendees);
    for (const attendee of event.attendees) {
      const uuid = await getUuidFromEmail(attendee.email);
      functions.logger.log(uuid);
      guests.push(uuid);
    }
    eventData.guests = guests;
  }

  functions.logger.log(eventData);
  return eventData;
}

// returns the day of week of an inputDate
function findDayOfWeek(inputDate) {
  const date = new Date(inputDate);
  const dayOfWeek = date.getDay();
  const daysOfWeek = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
  return daysOfWeek[dayOfWeek];
}

// format endRecurrenceDate if not null
function formatEndRecurrenceDate(endRecurrenceDate) {
  if (!endRecurrenceDate) {
    return "";
  }

  return ";UNTIL=" + endRecurrenceDate.replace(/-/g, "");
}

// format recurrence string for Gcal event object
function formatRecurrence(frequency, date, endRecurrenceDate) {
  switch (frequency) {
    case "Once":
      return;
    case "Daily": {
      return "RRULE:FREQ=DAILY" + formatEndRecurrenceDate(endRecurrenceDate);
    }
    case "Weekly": {
      return "RRULE:FREQ=WEEKLY" + formatEndRecurrenceDate(endRecurrenceDate) +
              ";BYDAY=" + findDayOfWeek(date);
    }
    case "Biweekly": {
      return "RRULE:FREQ=WEEKLY;WKST=MO" + formatEndRecurrenceDate(endRecurrenceDate) +
              ";INTERVAL=2;BYDAY=" + findDayOfWeek(date);
    }
    case "Monthly": {
      return "RRULE:FREQ=MONTHLY" + formatEndRecurrenceDate(endRecurrenceDate);
    }
    default:
      throw new functions.https.HttpsError(
        "invalid input: frequency can only be strings in {Once, Daily, Weekly, Biweekly, Monthly}"
      );
  }
}

/* REQUIRES: token, roomId, instanceId
 * RETURNS: chore = {instanceId, eventName, date, frequency, (description), (assignedRoommates)}
 * assignedRoommates = [uuid]
 */
/* sample return value: 
* [{
    instanceId = "12345";
    date = "2023-12-02";
    description = gibberish;
    eventName = Trash;
    frequency = Once;
    assignedRoommates = [
      "lteresa@umich.edu"
    ]
  },...]
*/
// returns details of a chore: instanceId, eventName, date, author, frequency, (description), (assignedRoommates)
async function getChoreHelper(instanceId, calendar, roomId) {
  const choresCalendarId = await getCalendarId(roomId, "chore");
  const res = await calendar.events.get({
    calendarId: choresCalendarId,
    eventId: instanceId,
  });

  functions.logger.log(res?.data ?? "Failurreeee! in getChore");
  const event = res.data;

  functions.logger.log("event from get() using instanceId");
  functions.logger.log(event);

  if (!event) {
    functions.logger.log("No event found.");
    return {};
  }
  const output = await parseChore(instanceId, event);
  return output;
}

/* REQUIRES: calendarId, eventInput, calendar
 * RETURNS: event
 */
async function addHelper(calendarId, eventInput, calendar) {
  functions.logger.log(eventInput);

  let res = {};
  try {
    res = await calendar.events.insert({
      calendarId: calendarId,
      resource: eventInput,
    });
  } catch (error) {
    functions.logger.error("Error adding event:", error.message);
    throw new functions.https.HttpsError("Error adding event:", error.message);
  }

  functions.logger.log(res?.data ?? "Failurreeee!");
  functions.logger.log(res);
  const event = res.data;
  if (!event || event.length === 0) {
    throw new functions.https.HttpsError("Failed to add event");
  }
  functions.logger.log("Added event:");
  functions.logger.log(event);

  return event;
}

/* REQUIRES: calendarId, eventId, calendar
 * MODIFIES: Google calendar specified by calendarId
 * RETURNS: status
 */
async function deleteHelper(calendarId, eventId, calendar) {
  if (!eventId) {
    throw new functions.https.HttpsError("invalid input: missing eventId");
  }

  // delete event with eventId
  let res = {};
  try {
    res = await calendar.events.delete({
      calendarId: calendarId,
      eventId: eventId,
    });
  } catch (error) {
    functions.logger.error("Error deleting event:", error.message);
    throw new functions.https.HttpsError(
      "Error deleting event:",
      error.message
    );
  }

  functions.logger.log(res);
  functions.logger.log("Successfully deleted event");

  return;
}

/* CHORES FUNCTIONS */

/* REQUIRES: token, instanceId
 * MODIFIES: nothing
 * EFFECTS: returns details of a chore instance on RoomieMatter Chore calendar
 * RETURNS: status, chore
 *          chore = {instanceId, eventName, date, frequency, (description), (assignedRoommates)}
 *          assignedRoommates = [uuid]
 */
async function getChoreBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId || data.instanceId.length == 0) {
    throw new functions.https.HttpsError("invalid input: instanceId is empty");
  }

  let res = {};
  try {
    res = await getChoreHelper(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error("Error getting event:", error.message);
    throw new functions.https.HttpsError("Error getting event:", error.message);
  }

  functions.logger.log(res);
  functions.logger.log("Successfully deleted event");
  return { status: true, chore: res };
}
const getChore = functions.https.onCall(async (data, context) => {
  return await getChoreBody(data, context);
});


/* REQUIRES: token, roomId
 * MODIFIES: nothing
 * EFFECTS: returns list of chores from RoomieMatter Chore calendar
 * RETURNS: status, [chore]
 *          chore = {instanceId, eventName, date, author, frequency, (description), (assignedRoommates)}
 *          assignedRoommates = [uuid]
 */
async function getChoresBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  functions.logger.log(data);

  const choresCalendarId = await getCalendarId(data.roomId, "chore");
  const res = await calendar.events.list({
    calendarId: choresCalendarId,
    timeMin: new Date().toISOString(),
    singleEvents: false,
  });

  functions.logger.log(res?.data?.items ?? "Failurreeee!");
  functions.logger.log(res);

  const events = res.data.items;
  if (!events || events.length === 0) {
    functions.logger.log("No upcoming events found.");
    return { status: false };
  }

  let eventsOutput = [];

  functions.logger.log("events using list()");
  functions.logger.log(events);
  for (const event of events) {
    
    // make sure it's a confirmed event
    if (event.status != "confirmed") {
      continue;
    }

    // parse chore
    functions.logger.log("event.recurrence:")
    functions.logger.log(event.recurrence);
    // if non-recurring event, use eventId as instanceId
    if (!event.recurrence || event.recurrence.length == 0) {
    // if (!event.id.includes('_')){
      functions.logger.log("Non-recurring event");
      const output = await parseChore(event.id, event);
      eventsOutput.push(output);
    }

    // recurring event, find instanceId
    else {
      functions.logger.log("Recurring event");
      let instanceId = "";
      try {
        instanceId = await getInstanceId(event.id, calendar, data.roomId);
      } catch (error) {
        functions.logger.error("Error getting instance ID:", error.message);
        throw new functions.https.HttpsError(
          "Error getting instance ID:",
          error.message
        );
      }

      if (instanceId == "") {
        functions.logger.error("Error getting instance ID");
        throw new functions.https.HttpsError(
          "Error getting instance ID", instanceId
        );
      }

      const output = await parseChore(instanceId, event);
      eventsOutput.push(output);
    }
  }

  return { status: true, chores: eventsOutput };
}
const getChores = functions.https.onCall(async (data, context) => {
  return await getChoresBody(data, context);
});

/* REQUIRES: token, roomId, eventName, date, frequency
 * OPTIONAL: endRecurrenceDate, description, assignedRoommates
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: add a chore to RoomieMatter Chore calendar
 * RETURNS: status, instanceId
 *
 * frequency = {Once, Daily, Weekly, Biweekly, Monthly}
 * if frequency == Once, endRecurrenceDate is ignored
 * example date: "2023-12-01"
 */

async function addChoreBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  // make sure eventName, date, frequency are not empty
  if (
    !data.eventName ||
    !data.eventName.trim() ||
    !data.date ||
    !data.frequency
  ) {
    throw new functions.https.HttpsError(
      "invalid input: eventName, date or frequency is empty"
    );
  }

  // add eventName
  let eventInput = {
    summary: data.eventName,
  };

  // add date
  eventInput.start = {};
  eventInput.end = {};
  eventInput.start.date = data.date;
  eventInput.end.date = data.date;

  eventInput.recurrence = [formatRecurrence(data.frequency, data.date, data.endRecurrenceDate)];

  // add description
  if (data.description) {
    eventInput.description = data.description;
  }

  // add attendees
  if (data.assignedRoommates) {
    let attendees = [];
    for (const attendee of data.assignedRoommates) {
      functions.logger.log(attendee);
      const email = await getEmailFromUuid(attendee);
      functions.logger.log(email);
      attendees.push({ email: email });
    }
    eventInput.attendees = attendees;
  }

  let event = {};
  const choresCalendarId = await getCalendarId(data.roomId, "chore");
  try {
    event = await addHelper(choresCalendarId, eventInput, calendar);
  } catch (error) {
    functions.logger.error("Error adding chore:", error.message);
    throw new functions.https.HttpsError("Error adding chore:", error.message);
  }

  // if non-recurring, return eventId
  if (data.frequency == "Once") {
    return { status: true, instanceId: event.id };
  }

  // recurring event, return instanceId of first instance
  let instanceId = "";
  try {
    instanceId = await getInstanceId(event.id, calendar, data.roomId);
  } catch (error) {
    functions.logger.error("Error getting instance ID:", error.message);
    throw new functions.https.HttpsError(
      "Error getting instance ID:",
      error.message
    );
  }

  if (instanceId == "") {
    functions.logger.error("Error getting instance ID");
    throw new functions.https.HttpsError("Error getting instance ID:");
  }

  return { status: true, instanceId: instanceId };
}
const addChore = functions.https.onCall(async (data, context) => {
  return await addChoreBody(data, context);
});

/* REQUIRES: token, roomId, instanceId
 * OPTIONAL: eventName, date, frequency, endRecurrenceDate, description, assignedRoommates
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: modifies all instances of a chore on RoomieMatter Chore calendar
 * RETURNS: status, chore
 * 
 * requirement: change date and frequency together
 */

async function editChoreBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId) {
    throw new functions.https.HttpsError("invalid input: missing instanceId");
  }

  // get eventId with instanceId
  let eventId = "";
  try {
    eventId = await getEventId(data.instanceId, calendar, data.roomId);
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  // patch event
  const choresCalendarId = await getCalendarId(data.roomId, "chore");
  let input = {
    calendarId: choresCalendarId,
    eventId: eventId,
    resource: {},
  };

  if (data.eventName) {
    input.resource.summary = data.eventName;
  }

  // requirement: change date and frequency together
  if ((data.date && !data.frequency) || (!data.date && data.frequency)) {
    functions.logger.log("Expects both date and frequency if any changes");
  }

  if (data.date && data.frequency) {
    input.resource.start = {};
    input.resource.end = {};
    input.resource.start.date = data.date;
    input.resource.end.date = data.date;
    input.resource.recurrence = formatRecurrence(data.frequency, data.date, data.endRecurrenceDate);
  }

  if (data.description) {
    input.resource.description = data.description;
  }
  if (data.assignedRoommates) {
    let attendees = [];
    for (const attendee of data.assignedRoommates) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    input.resource.attendees = attendees;
  }

  functions.logger.log(input);

  // call API to patch event
  let res = {};
  try {
    res = await calendar.events.patch(input);
  } catch (error) {
    functions.logger.error("Error editing event:", error.message);
    throw new functions.https.HttpsError("Error editing event:", error.message);
  }

  functions.logger.log(res);
  functions.logger.log("Successfully edited event");

  if (!res.data || res.data.length == 0) {
    return { status: false };
  }

  const output = await parseChore(data.instanceId, res.data);
  return { status: true, chore: output };
}
const editChore = functions.https.onCall(async (data, context) => {
  return await editChoreBody(data, context);
});

/* REQUIRES: token, roomId, instanceId
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete one instance of a chore on RoomieMatter Chore calendar
 * RETURNS: status, (nextInstanceId)
 *
 * (if chore is non-recurring, entire chore is deleted)
 */
async function completeChoreBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId) {
    throw new functions.https.HttpsError("invalid input: missing instanceId");
  }

  // get eventId with instanceId
  let eventId = "";
  try {
    eventId = await getEventId(data.instanceId, calendar, data.roomId);
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  // delete instance of event with instanceId
  let res = {};
  const choresCalendarId = await getCalendarId(data.roomId, "chore");
  try {
    res = await calendar.events.delete({
      calendarId: choresCalendarId,
      eventId: data.instanceId,
    });
  } catch (error) {
    functions.logger.error("Error deleting instance:", error.message);
    throw new functions.https.HttpsError(
      "Error deleting instance:",
      error.message
    );
  }

  functions.logger.log(res);
  functions.logger.log("Successfully deleted instance");

  // if non-recurring event, return
  if (!data.instanceId.includes("_")) {
    return { status: true };
  }

  try {
    const instanceId = await getInstanceId(eventId, calendar, data.roomId);
    if (instanceId == "") {
      return { status: true };
    } else {
      return { status: true, nextInstanceId: instanceId };
    }
  } catch (error) {
    functions.logger.error("Error getting instances:", error.message);
    throw new functions.https.HttpsError(
      "Error getting instances:",
      error.message
    );
  }
}
const completeChore = functions.https.onCall(async (data, context) => {
  return await completeChoreBody(data, context);
});

/* REQUIRES: token, roomId, instanceId
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete all instances of a chore on RoomieMatter Chore calendar
 * RETURNS: status
 */
async function deleteChoreBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId) {
    throw new functions.https.HttpsError("invalid input: missing instanceId");
  }

  // get eventId with instanceId
  let eventId = "";
  try {
    eventId = await getEventId(data.instanceId, calendar, data.roomId);
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  // delete event with eventId
  const choresCalendarId = await getCalendarId(data.roomId, "chore");
  try {
    deleteHelper(choresCalendarId, eventId, calendar);
  } catch (error) {
    functions.logger.error("Error deleting eventId:", eventId, error.message);
    throw new functions.https.HttpsError(
      "Error deleting eventId:",
      eventId,
      error.message
    );
  }
  return { status: true };
}
const deleteChore = functions.https.onCall(async (data, context) => {
  return await deleteChoreBody(data, context);
});

/* EVENTS FUNCTIONS */

/* REQUIRES: token, roomId
 * MODIFIES: nothing
 * EFFECTS: returns list of events from RoomieMatter Events calendar
 * RETURNS: status, [event]
 *          event = {eventId, eventName, date, author, (description), (guests)}
 */
async function getEventsBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  const eventsCalendarId = await getCalendarId(data.roomId, "event");
  const res = await calendar.events.list({
    calendarId: eventsCalendarId,
    timeMin: new Date().toISOString(),
    singleEvents: false,
  });

  functions.logger.log(res?.data?.items ?? "Failurreeee!");
  functions.logger.log(res);

  const events = res.data.items;
  if (!events || events.length === 0) {
    functions.logger.log("No upcoming events found.");
    return { status: true, events: {} };
  }

  let eventsOutput = [];

  for (const event of events) {
    functions.logger.log(event.id);

    // make sure it's a confirmed event
    if (event.status != "confirmed") {
      continue;
    }

    const eventOutput = await parseEvent(event);
    eventsOutput.push(eventOutput);
  }

  functions.logger.log(eventsOutput);

  return { status: true, events: eventsOutput };
}
const getEvents = functions.https.onCall(async (data, context) => {
  return await getEventsBody(data, context);
});

/* REQUIRES: token, roomId, eventName, startDatetime, endDatetime
 * OPTIONAL: description, guests
 * MODIFIES: RoomieMatter Event calendar
 * EFFECTS: add an event to RoomieMatter Events calendar
 * RETURNS: status, eventId
 *
 * datetime object example: "2023-12-03T10:00:00-05:00"
 */
async function addEventBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  // make sure eventName, startDatetime, endDatetime are not empty
  if (!data.eventName || !data.eventName.trim() || !data.startDatetime || !data.endDatetime) {
    throw new functions.https.HttpsError(
      "invalid input: eventName or date is empty"
    );
  }

  // add eventName
  let eventInput = {
    summary: data.eventName,
  };

  // add datetime
  eventInput.start = {};
  eventInput.end = {};
  // check if valid start and end datetime
  if (new Date(data.startDatetime) >= new Date(data.endDatetime)) {
    throw new functions.https.HttpsError(
      "invalid input: startDateTime not less than endDateTime"
    );
  }

  eventInput.start.dateTime = data.startDatetime;
  eventInput.start.timeZone = "America/New_York";
  eventInput.end.dateTime = data.endDatetime;
  eventInput.end.timeZone = "America/New_York";

  // add description
  if (data.description) {
    eventInput.description = data.description;
  }

  // add guests
  if (data.guests) {
    let attendees = [];
    for (const attendee of data.guests) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    eventInput.attendees = attendees;
  }

  let event = {};
  const eventsCalendarId = await getCalendarId(data.roomId, "event");
  try {
    event = await addHelper(eventsCalendarId, eventInput, calendar);
  } catch (error) {
    functions.logger.error("Error adding event:", error.message);
    throw new functions.https.HttpsError("Error adding event:", error.message);
  }

  return { status: true, eventId: event.id };
}
const addEvent = functions.https.onCall(async (data, context) => {
  return await addEventBody(data, context);
});

/* REQUIRES: token, roomId, eventId
 * OPTIONAL: eventName, startDatetime, endDatetime, description, guests
 * MODIFIES: RoomieMatter Event calendar
 * EFFECTS: modifies an event on RoomieMatter Event calendar
 * RETURNS: status, event
 * 
 * requirement: both startDatetime and endDatetime has to be present if changing one of the fields
 */
async function editEventBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

  functions.logger.log(data);

  if (!data.eventId) {
    throw new functions.https.HttpsError("invalid input: missing eventId");
  }

  // patch event
  const eventsCalendarId = await getCalendarId(data.roomId, "event");
  let input = {
    calendarId: eventsCalendarId,
    eventId: data.eventId,
    resource: {},
  };

  if (data.eventName) {
    input.resource.summary = data.eventName;
  }

  // requirement: change startDatetime and endDatetime together
  if ((data.startDatetime && !data.endDatetime) || (!data.startDatetime && data.endDatetime)) {
    functions.logger.log("Expects both startDatetime and endDatetime if any changes");
  }

  if (data.startDatetime && data.endDatetime) {
    // check if valid start and end datetime
    if (new Date(data.startDatetime) >= new Date(data.endDatetime)) {
      throw new functions.https.HttpsError(
        "invalid input: startDateTime not less than endDateTime"
      );
    }
    input.resource.start = {};
    input.resource.end = {};
    input.resource.start.dateTime = data.startDatetime;
    input.resource.start.timeZone = "America/New_York";
    input.resource.end.dateTime = data.endDatetime;
    input.resource.end.timeZone = "America/New_York";
  }

  if (data.description) {
    input.resource.description = data.description;
  }
  if (data.guests) {
    let attendees = [];
    for (const attendee of data.guests) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    input.resource.attendees = attendees;
  }

  functions.logger.log(input);

  // call API to patch event
  let res = {};
  try {
    res = await calendar.events.patch(input);
  } catch (error) {
    functions.logger.error("Error editing event:", error.message);
    throw new functions.https.HttpsError("Error editing event:", error.message);
  }

  functions.logger.log(res);
  functions.logger.log("Successfully edited event");

  if (!res.data || res.data.length == 0) {
    return { status: false };
  }

  const output = await parseEvent(res.data);
  return { status: true, event: output };
}
const editEvent = functions.https.onCall(async (data, context) => {
  return await editEventBody(data, context);
});

/* REQUIRES: token, roomId, eventId
 * MODIFIES: RoomieMatter Event calendar
 * EFFECTS: delete event on RoomieMatter Event calendar
 * RETURNS: status
 */
async function deleteEventBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);
  const eventsCalendarId = await getCalendarId(data.roomId, "event");
  try {
    deleteHelper(eventsCalendarId, data.eventId, calendar);
  } catch (error) {
    functions.logger.error(
      "Error deleting eventId:",
      data.eventId,
      error.message
    );
    throw new functions.https.HttpsError(
      "Error deleting eventId:",
      data.eventId,
      error.message
    );
  }
  return { status: true };
}
const deleteEvent = functions.https.onCall(async (data, context) => {
  return await deleteEventBody(data, context);
});

module.exports = {
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
  createNewCalendars, 
  getChoreBody,
  getChoresBody,
  addChoreBody,
  editChoreBody,
  completeChoreBody,
  deleteChoreBody,
  getEventsBody,
  addEventBody,
  editEventBody,
  deleteEventBody,
};
