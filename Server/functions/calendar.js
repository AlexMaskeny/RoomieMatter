const functions = require("firebase-functions");
const { google } = require("googleapis");

choresCalendarId = "c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com"

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
    functions.logger.error('Error getting eventId:', error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:", error.message
      );
  }

  functions.logger.log(res);
  if (!res.data || res.data.length === 0) {
    functions.logger.log('Invalid instanceId');
    return {status: false};
  }

  if (!res.data.recurringEventId) {
    functions.logger.log('recurringEventId not found');
    return {status: false};
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
    throw new functions.https.HttpsError(
      "Expects eventId only:", error.message
    );
  }

  // find instanceId
  let res = {};
  try {
    res = await calendar.events.instances({
      calendarId: choresCalendarId,
      eventId: eventId,
    });
  } catch (error) {
    functions.logger.error('Error getting instances:', error.message);
    throw new functions.https.HttpsError(
      "Error getting instances:", error.message
    );
  }

  if (!res.data.items || res.data.items.length === 0) {
    functions.logger.log('No next instances found');
    return "";
  }

  return res.data.items[0].id;
}

/* REQUIRES: token, instanceId 
 * RETURNS: chore = {instanceId, eventName, date, frequency, (description), (assignedRoommates)}
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
    eventId: instanceId
  });

  functions.logger.log(res?.data ?? "Failurreeee! in getChore");
  const event = res.data;
  functions.logger.log(event);

  if (!event) {
    functions.logger.log('No event found.');
    return {};
  }
  
  let eventData = {
    instanceId: instanceId, 
    eventName: event.summary,
    date: event.start.date,
  };

  if (event.recurrence) {
    const startIndex = event.recurrence[0].indexOf("FREQ=") + 5;
    const endIndex = event.recurrence[0].indexOf(";");
    if (endIndex == -1) {
        endIndex = event.recurrence[0].length;
    }
    const freq = event.recurrence[0].substring(startIndex, endIndex)

    switch (freq) {
      case 'DAILY':
        eventData.frequency = "Daily";
        break;
      case 'WEEKLY':
        if (eventData.frequency.includes("INTERVAL=2")) {
          eventData.frequency = "Biweekly";
        } else {
          eventData.frequency = "Weekly";
        }
        break;
      case 'MONTHLY':
        eventData.frequency = "Monthly";
        break;
      default:
        throw new functions.https.HttpsError(
          "error converting frequency"
        );
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
      assignees.push(attendee.email);
    }
    eventData.assignedRoommates = assignees;
  }

  functions.logger.log(eventData);

  return eventData;
}

/* REQUIRES: token, instanceId
 * MODIFIES: nothing
 * EFFECTS: returns details of a chore instance on RoomieMatter Chore calendar
 * RETURNS: status, chore
 *          chore = {instanceId, eventName, date, frequency, (description), (assignedRoommates)}
 */
const getChore = functions.https.onCall(async (data, context) => {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId || data.instanceId.length == 0) {
    throw new functions.https.HttpsError(
      "invalid input: instanceId is empty"
    );
  }

  let res = {};
  try{
    res = await getChoreHelper(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error('Error getting event:', error.message);
    throw new functions.https.HttpsError(
      "Error getting event:", error.message
    );
  }

  functions.logger.log(res);
  functions.logger.log('Successfully deleted event');
  return {status: true, chore: res};
});

/* REQUIRES: token
 * MODIFIES: nothing
 * EFFECTS: returns list of chores from RoomieMatter Chore calendar
 * RETURNS: status, [chore]
 *          chore = {instanceId, eventName, date, frequency, (description), (assignedRoommates)}
 */
const getChores = functions.https.onCall(async (data, context) => {
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
    functions.logger.log('No upcoming events found.');
    return {status: false};
  }

  const eventsIds = [];

  for (const event of events) {
    functions.logger.log(event.id);

    // make sure it's a confirmed event
    if (event.status != 'confirmed') {
      continue;
    }

    // if non-recurring event, use eventId as instanceId 
    if (!event.recurrence || event.recurrence.length === 0) {
      functions.logger.log('Non-recurring event');
      eventsIds.push({instanceId: event.id});
    } 
    
    // recurring event, find instanceId
    else {
      functions.logger.log('Recurring event');
      let instanceId = "";
      try {
        instanceId = await getInstanceId(event.id, calendar);
      } catch (error) {
        functions.logger.error('Error getting instance ID:', error.message);
        throw new functions.https.HttpsError(
          "Error getting instance ID:", error.message
        );
      }

      if (instanceId == "") {
        functions.logger.error("Error getting instance ID");
        throw new functions.https.HttpsError(
          "Error getting instance ID:", error.message
          // TODO: more descriptive error message with eventId
        );
      }

      eventsIds.push({instanceId: instanceId});
    }
  }

  functions.logger.log("eventsIds:");
  functions.logger.log(eventsIds);

  // return chores using getChore with eventsIds
  let eventsOutput = [];
  for (eventId of eventsIds) {
    let eventOutput;
    try {
      eventOutput =  await getChoreHelper(eventId.instanceId, calendar);
    } catch (error) {
      functions.logger.error('Error getting chore:', error.message);
      throw new functions.https.HttpsError(
        "Error getting chore:", error.message
      );
    }

    if (!eventOutput || eventOutput.length == 0) {
      functions.logger.error("No chore found with eventId");
        throw new functions.https.HttpsError(
          "No chore found with eventId:", error.message
          // TODO: more descriptive error message with eventId
        );
    }

    eventsOutput.push(eventOutput);
  }

  return { status: true, chores: eventsOutput };
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
const addChore = functions.https.onCall(async (data, context) => {
  const calendar = createOAuth(context.auth, data.token);

  // make sure eventName, date, frequency are not empty
  if (!data.eventName || !data.eventName.trim() || !data.date || !data.frequency) {
    throw new functions.https.HttpsError(
      "invalid input: eventName, date or frequency is empty"
    );
  }
  
  // add eventName
  let eventInput = {
    'summary': data.eventName,
  };

  // add date
  eventInput.start = {};
  eventInput.end = {};
  eventInput.start.date = data.date;
  eventInput.end.date = data.date;

  // returns the day of week of an inputDate
  function findDayOfWeek(inputDate) {
    const date = new Date(inputDate);
    const dayOfWeek = date.getDay();
    const daysOfWeek = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    return daysOfWeek[dayOfWeek];
  }
  
  // format endRecurrenceDate if not null
  function formatEndRecurrenceDate(endRecurrenceDate) {
    if (!endRecurrenceDate) {
      return "";
    }

    return ';UNTIL=' + data.endRecurrenceDate.replace(/-/g, '');
  }

  // add recurrence if necessary
  switch (data.frequency) {
    case 'Once': 
      break;
    case 'Daily':
      const dailyInput = 'RRULE:FREQ=DAILY' + formatEndRecurrenceDate(data.endRecurrenceDate);
      eventInput.recurrence = [dailyInput];
      break;
    case 'Weekly':
      const weeklyInput = 'RRULE:FREQ=WEEKLY' + formatEndRecurrenceDate(data.endRecurrenceDate) + ';BYDAY=' + findDayOfWeek(data.date);
      eventInput.recurrence = [weeklyInput];
      break;
    case 'Biweekly':
      const biweeklyInput = 'RRULE:FREQ=WEEKLY;WKST=MO' + formatEndRecurrenceDate(data.endRecurrenceDate) + ';INTERVAL=2;BYDAY=' + findDayOfWeek(data.date);
      eventInput.recurrence = [biweeklyInput];
      break;
    case 'Monthly':
      const monthlyInput = 'RRULE:FREQ=MONTHLY' + formatEndRecurrenceDate(data.endRecurrenceDate);
      eventInput.recurrence = [monthlyInput];
      break;
    default:
      throw new functions.https.HttpsError(
        "invalid input: frequency can only be strings in {Once, Daily, Weekly, Biweekly, Monthly}"
      );
  }
  
  // add description
  if (data.description) {
    eventInput.description = data.description;
  }

  // add attendees
  if (data.attendees) {
    let attendees = [];
    for (const attendee of data.attendees) {
      // double check that these are valid emails
      attendees.push({'email': attendee});
    }
    eventInput.attendees = attendees;
  }

  let res = {}
  try{
    res = await calendar.events.insert({
      calendarId: choresCalendarId,
      resource: eventInput,
    });
  } catch (error) {
    functions.logger.error('Error adding event:', error.message);
    throw new functions.https.HttpsError(
      "Error adding event:", error.message
    );
  }
  
  functions.logger.log(res?.data ?? "Failurreeee!");
  functions.logger.log(res);
  const event = res.data;
  if (!event || event.length === 0) {
    throw new functions.https.HttpsError(
      "Failed to add event"
    );
  }
  functions.logger.log('Added event:');
  functions.logger.log(event);

  // if non-recurring, return eventId
  if (data.frequency == 'Once') {
    return {status: true, instanceId: event.id};
  }

  // recurring event, return instanceId of first instance
  let instanceId = "";
  try {
    instanceId = await getInstanceId(event.id, calendar);
  } catch (error) {
    functions.logger.error('Error getting instance ID:', error.message);
    throw new functions.https.HttpsError(
      "Error getting instance ID:", error.message
    );
  }

  if (instanceId == "") {
    functions.logger.error("Error getting instance ID");
    throw new functions.https.HttpsError(
      "Error getting instance ID:", error.message
    );
  }
  
  return {status: true, instanceId: instanceId};
});

/* REQUIRES: token, instanceId
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete one instance of a chore on RoomieMatter Chore calendar
 * RETURNS: status, (nextInstanceId)
 * 
 * (if chore is non-recurring, entire chore is deleted)
 */
const completeChore = functions.https.onCall(async (data, context) => {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId) {
    throw new functions.https.HttpsError(
      "invalid input: missing instanceId"
    );
  }
  
  // get eventId with instanceId
  let eventId = "";
  try {
    eventId = await getEventId(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error('Error getting eventId:', error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:", error.message
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
    functions.logger.error('Error deleting instance:', error.message);
    throw new functions.https.HttpsError(
      "Error deleting instance:", error.message
    );
  }
  
  functions.logger.log(res);
  functions.logger.log('Successfully deleted instance');

  // if non-recurring event, return
  if (!data.instanceId.includes("_")) {
    return {status: true};
  }

  try {
    const instanceId = await getInstanceId(eventId, calendar);
    if (instanceId == "") {
      return {status: true};
    } else {
      return {status: true, nextInstanceId: instanceId};
    }
  } catch (error) {
    functions.logger.error('Error getting instances:', error.message);
    throw new functions.https.HttpsError(
      "Error getting instances:", error.message
    );
  }

});

/* REQUIRES: token, instanceId
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete all instances of a chore on RoomieMatter Chore calendar
 * RETURNS: status
 */
const deleteChore = functions.https.onCall(async (data, context) => {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId) {
    throw new functions.https.HttpsError(
      "invalid input: missing instanceId"
    );
  }

  // get eventId with instanceId
  let eventId = "";
  try {
    eventId = await getEventId(data.instanceId, calendar);
  } catch (error) {
    functions.logger.error('Error getting eventId:', error.message);
    throw new functions.https.HttpsError(
      "Error getting eventId:", error.message
      );
  }
  
  // delete event with eventId
  let res = {};
  try {
    res = await calendar.events.delete({
      calendarId: choresCalendarId,
      eventId: eventId,
    });
  } catch (error) {
    functions.logger.error('Error deleting event:', error.message);
    throw new functions.https.HttpsError(
      "Error deleting event:", error.message
      );
  }
    
  functions.logger.log(res);
  functions.logger.log('Successfully deleted event');
  return {status: true};
});

module.exports = { getChore, getChores, addChore, completeChore, deleteChore };
