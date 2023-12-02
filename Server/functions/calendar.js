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

// returns details of a chore
async function getChore(calendar, id) {
  const res = await calendar.events.get({
    calendarId: choresCalendarId,
    eventId: id
  });

  functions.logger.log(res?.data ?? "Failurreeee! in getChore");
  const event = res.data;
  functions.logger.log(event);

  if (!event) {
    functions.logger.log('No event found.');
    return {};
  }

  let frequency = "";
  if (event.recurrence) {
    const startIndex = event.recurrence[0].indexOf("FREQ=") + 5;
    const endIndex = event.recurrence[0].indexOf(";");
    if (endIndex == -1) {
        endIndex = event.recurrence[0].length;
    }
    frequency = event.recurrence[0].substring(startIndex, endIndex);
  }

  let assignees = [];
  if (event.attendees) {
    functions.logger.log(event.attendees);
    for (const attendee of event.attendees) {
      assignees.push(attendee.email);
    }
  }

  const eventData = {
    summary: event.summary,
    frequency: frequency,
    assignees: assignees
  };
  functions.logger.log(eventData);

  return eventData;
}

/* REQUIRES: token
 * MODIFIES: nothing
 * EFFECTS: returns list of chores from RoomieMatter Chore calendar
 * 
 * sample return value: 
 * [{
    assignees = ('lteresa@umich.edu');
    frequency = WEEKLY;
    date = "2023-11-30";
    summary = "Take Out Trash";
    },...]
 */
const getChores = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const token = data.token;
  functions.logger.log(token);
  const oAuth2Client = new google.auth.OAuth2();
  oAuth2Client.setCredentials({ access_token: token });
  const calendar = google.calendar({ version: "v3", auth: oAuth2Client });
  const res = await calendar.events.list({
    calendarId: choresCalendarId,
    timeMin: new Date().toISOString(),
    maxResults: 5,
    singleEvents: true,
    orderBy: "startTime",
  });

  functions.logger.log(res?.data?.items ?? "Failurreeee!");
  functions.logger.log(res);

  const events = res.data.items;
  if (!events || events.length === 0) {
    functions.logger.log('No upcoming events found.');
    return {success: false};
  }
  functions.logger.log('Upcoming 5 events:');

  const eventsData = [];

  for (const event of events) {
    functions.logger.log(event.recurringEventId);

    try {
      // Call the asynchronous function using await
      const choreResult = await getChore(calendar, event.recurringEventId);
      choreResult.date = event.start.date;

      // Log the result
      functions.logger.log(choreResult);

      // Push the result to the eventsData array
      eventsData.push(choreResult);
    } catch (error) {
      // Handle errors if necessary
      functions.logger.error(`Error processing event ${event.id}: ${error.message}`);
    }
  }

  functions.logger.log("eventsData:");
  functions.logger.log(eventsData);

  return { eventsData };
});

/* REQUIRES: token, eventName, date, frequency
 * OPTIONAL: endRecurrenceDate, description, assignedRoommates
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: add a chore to RoomieMatter Chore calendar
 * 
 * frequency = {Once, Daily, Weekly, Biweekly, Monthly}
 * if frequency == Once, endRecurrenceDate is ignored
 * example date: "2023-12-01"
 * 
 * returns {success: true, eventId: "..."} on success
 * throws error on failure
*/
const addChore = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  if (!data.token) {
    functions.logger.log("Token not found");
    return {success: false};
  }
  const token = data.token;
  functions.logger.log(token);
  const oAuth2Client = new google.auth.OAuth2();
  oAuth2Client.setCredentials({ access_token: token });
  const calendar = google.calendar({ version: "v3", auth: oAuth2Client });

  // make sure eventName, date, frequency are not empty
  if (!data.eventName || !data.eventName.trim() || !data.date || !data.frequency) {
    throw new functions.https.HttpsError(
      "invalid input: eventName, date or frequency is empty"
    );
  }
  
  // add eventName
  const eventInput = {
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
  return {success: true, eventId: event.id};
});

/* REQUIRES: token, instanceId
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete one instance of a chore on RoomieMatter Chore calendar
 * 
 * returns {success: true} on success
 * throws error on failure
 */
const deleteChoreInstance = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const token = data.token;
  functions.logger.log(token);
  const oAuth2Client = new google.auth.OAuth2();
  oAuth2Client.setCredentials({ access_token: token });
  const calendar = google.calendar({ version: "v3", auth: oAuth2Client });

  if (!data.instanceId) {
    throw new functions.https.HttpsError(
      "invalid input: missing instanceId"
    );
  }

  try {
    const res = await calendar.events.delete({
      calendarId: choresCalendarId,
      eventId: data.instanceId,
    });
    
    functions.logger.log(res);
    functions.logger.log('Successfully deleted instance');
  } catch (error) {
    functions.logger.error('Error deleting instance:', error.message);
    throw new functions.https.HttpsError(
      "Error deleting instance:", error.message
    );
  }

  return {success: true};
});


/* REQUIRES: token, instanceId
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete all instances of a chore on RoomieMatter Chore calendar
 * 
 * success: returns {success: true}
 * failure: returns {success: false} or throws error
 */
const deleteChore = functions.https.onCall(async (data, context) => {
  const calendar = createOAuth(context.auth, data.token);

  if (!data.instanceId) {
    throw new functions.https.HttpsError(
      "invalid input: missing instanceId"
    );
  }

  let res = {}
  let eventId = data.instanceId;

  // if recurring event, get eventId using instanceId
  if (data.instanceId.includes("_")) {
    functions.logger.log("Recurring event");
    try {
      res = await calendar.events.get({
        calendarId: choresCalendarId,
        eventId: data.instanceId,
      });
    } catch (error) {
      functions.logger.error('Error deleting event:', error.message);
      throw new functions.https.HttpsError(
        "Error deleting event:", error.message
        );
    }

    functions.logger.log(res);
    if (!res.data || res.data.length === 0) {
      functions.logger.log('Invalid instanceId');
      return {success: false};
    }

    if (!res.data.recurringEventId) {
      functions.logger.log('recurringEventId not found');
      return {success: false};
    }

    eventId = res.data.recurringEventId;
    functions.logger.log("eventId = ", eventId);
  } else {
    functions.logger.log("Non-recurring event, eventId = instanceId = ", eventId);
  }

  // delete chore with eventId
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
  return {success: true};
});

module.exports = { getChores, addChore, deleteChoreInstance, deleteChore };
