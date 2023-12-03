const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { google } = require("googleapis");
const { UserDimensions } = require("firebase-functions/v1/analytics");

const db = admin.firestore();

const choresCalendarId =
  "c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com";
const eventsCalendarId =
  "c_13e412c22da53bac13e80008fedb53d172b8ac55ab3d4c838bf5a1b739a66d26@group.calendar.google.com";

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

/* REQUIRES: instanceId
 * RETURNS: eventId
 */
async function getEventId(instanceId, calendar) {
  // if non-recurring event, eventId = instanceId
  if (!instanceId.includes("_")) {
    functions.logger.log("Non-recurring event");
    return instanceId;
  }

  // recurring event, find eventId
  functions.logger.log("Recurring event");
  let res = {};
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

/* REQUIRES: eventId, calendar
 *           only recurring event
 * RETURNS: instanceId
 */
async function getInstanceId(eventId, calendar) {
  // if instanceID, throws error
  if (eventId.includes("_")) {
    throw new functions.https.HttpsError("Expects eventId only");
  }

  // find instanceId
  let res = {};
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

  return res.data.items[0].id;
}

// takes in Google's raw event and returns a chore object with fields we need
async function parseChore(instanceId, event) {
  if (!event || event.length == 0) {
    return {};
  }

  let eventData = {
    instanceId: instanceId,
    eventName: event.summary,
    date: event.start.date,
  };

  if (event.recurrence) {
    const startIndex = event.recurrence[0].indexOf("FREQ=") + 5;
    let endIndex = event.recurrence[0].indexOf(";");
    if (endIndex == -1) {
      endIndex = event.recurrence[0].length;
    }
    const freq = event.recurrence[0].substring(startIndex, endIndex);

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
      const uuid = await getUuidFromEmail(attendee.email);
      assignees.push(uuid);
    }
    eventData.assignedRoommates = assignees;
  }

  functions.logger.log(eventData);

  return eventData;
}

function parseEvent(event) {
  let eventData = {
    eventId: event.id,
    eventName: event.summary,
    startDatetime: event.start.dateTime,
    endDatetime: event.end.dateTime,
  };

  if (event.description) {
    eventData.description = event.description;
  }

  if (event.attendees) {
    let assignees = [];
    functions.logger.log(event.attendees);
    for (const attendee of event.attendees) {
      const uuid = getUuidFromEmail(attendee.email);
      assignees.push(uuid);
    }
    eventData.guests = assignees;
  }

  // functions.logger.log(eventData);
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

/* REQUIRES: token, instanceId
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
    assignees = [
      "lteresa@umich.edu"
    ]
  },...]
*/
// returns details of a chore: instanceId, eventName, date, frequency, (description), (assignedRoommates)
async function getChoreHelper(instanceId, calendar) {
  const res = await calendar.events.get({
    calendarId: choresCalendarId,
    eventId: instanceId,
  });

  functions.logger.log(res?.data ?? "Failurreeee! in getChore");
  const event = res.data;
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

/* REQUIRES: token
 * MODIFIES: nothing
 * EFFECTS: returns list of chores from RoomieMatter Chore calendar
 * RETURNS: status, [chore]
 *          chore = {instanceId, eventName, date, frequency, (description), (assignedRoommates)}
 *          assignedRoommates = [uuid]
 */
async function getChoresBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

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

  const eventsIds = [];

  for (const event of events) {
    functions.logger.log(event.id);

    // make sure it's a confirmed event
    if (event.status != "confirmed") {
      continue;
    }

    // if non-recurring event, use eventId as instanceId
    if (!event.recurrence || event.recurrence.length === 0) {
      functions.logger.log("Non-recurring event");
      eventsIds.push({ instanceId: event.id });
    }

    // recurring event, find instanceId
    else {
      functions.logger.log("Recurring event");
      let instanceId = "";
      try {
        instanceId = await getInstanceId(event.id, calendar);
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
          "Error getting instance ID"
          // TODO: more descriptive error message with eventId
        );
      }

      eventsIds.push({ instanceId: instanceId });
    }
  }

  functions.logger.log("eventsIds:");
  functions.logger.log(eventsIds);

  // return chores using getChore with eventsIds
  let eventsOutput = [];
  for (const eventId of eventsIds) {
    let eventOutput;
    try {
      eventOutput = await getChoreHelper(eventId.instanceId, calendar);
    } catch (error) {
      functions.logger.error("Error getting chore:", error.message);
      throw new functions.https.HttpsError(
        "Error getting chore:",
        error.message
      );
    }

    if (!eventOutput || eventOutput.length == 0) {
      functions.logger.error("No chore found with eventId");
      throw new functions.https.HttpsError(
        "No chore found with eventId:",
        eventId
      );
    }

    eventsOutput.push(eventOutput);
  }

  return { status: true, chores: eventsOutput };
}
const getChores = functions.https.onCall(async (data, context) => {
  return await getChoresBody(data, context);
});

/* REQUIRES: token, eventName, date, frequency
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

  eventInput.recurrence = formatRecurrence(data.frequency, data.date, data.endRecurrenceDate);

  // add description
  if (data.description) {
    eventInput.description = data.description;
  }

  // add attendees
  if (data.attendees) {
    let attendees = [];
    for (const attendee of data.attendees) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    eventInput.attendees = attendees;
  }

  let event = {};
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
    instanceId = await getInstanceId(event.id, calendar);
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

/* REQUIRES: token, instanceId
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
    eventId = await getEventId(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  // patch event
  let input = {
    calendarId: choresCalendarId,
    eventId: eventId,
  };

  if (data.eventName) {
    input.summary = data.eventName;
  }

  // requirement: change date and frequency together
  if ((data.date && !data.frequency) || (!data.date && data.frequency)) {
    functions.logger.log("Expects both date and frequency if any changes");
  }

  if (data.date && data.frequency) {
    input.start = {};
    input.end = {};
    input.start.date = data.date;
    input.end.date = data.date;
    input.recurrence = formatRecurrence(data.frequency, data.date, data.endRecurrenceDate);
  }

  if (data.description) {
    input.summary = data.description;
  }
  if (data.assignedRoommates) {
    let attendees = [];
    for (const attendee of data.assignedRoommates) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    input.attendees = attendees;
  }

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

/* REQUIRES: token, instanceId
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
    eventId = await getEventId(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  // delete instance of event with instanceId
  let res = {};
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
    const instanceId = await getInstanceId(eventId, calendar);
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

/* REQUIRES: token, instanceId
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
    eventId = await getEventId(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error("Error getting eventId:", error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:",
      error.message
    );
  }

  // delete event with eventId
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

/* REQUIRES: token
 * MODIFIES: nothing
 * EFFECTS: returns list of events from RoomieMatter Events calendar
 * RETURNS: status, [event]
 *          event = {eventId, eventName, date, (description), (guests)}
 */
async function getEventsBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);

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
    return { status: false };
  }

  let eventsOutput = [];

  for (const event of events) {
    functions.logger.log(event.id);

    // make sure it's a confirmed event
    if (event.status != "confirmed") {
      continue;
    }

    eventsOutput.push(parseEvent(event));
  }

  functions.logger.log(eventsOutput);

  return { status: true, events: eventsOutput };
}
const getEvents = functions.https.onCall(async (data, context) => {
  return await getEventsBody(data, context);
});

/* REQUIRES: token, eventName, startDatetime, endDatetime
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

  // add attendees
  if (data.attendees) {
    let attendees = [];
    for (const attendee of data.attendees) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    eventInput.attendees = attendees;
  }

  let event = {};
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

/* REQUIRES: token, eventId
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
  let input = {
    calendarId: eventsCalendarId,
    eventId: data.eventId,
  };

  if (data.eventName) {
    input.summary = data.eventName;
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
    input.start = {};
    input.end = {};
    input.start.dateTime = data.startDatetime;
    input.start.timeZone = "America/New_York";
    input.end.dateTime = data.endDatetime;
    input.end.timeZone = "America/New_York";
  }

  if (data.description) {
    input.description = data.description;
  }
  if (data.guests) {
    let attendees = [];
    for (const attendee of data.guests) {
      const email = await getEmailFromUuid(attendee);
      attendees.push({ email: email });
    }
    input.attendees = attendees;
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

/* REQUIRES: token, eventId
 * MODIFIES: RoomieMatter Event calendar
 * EFFECTS: delete event on RoomieMatter Event calendar
 * RETURNS: status
 */
async function deleteEventBody(data, context) {
  const calendar = createOAuth(context.auth, data.token);
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
