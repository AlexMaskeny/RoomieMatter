const functions = require("firebase-functions");
const { google } = require("googleapis");

choresCalendarId = "c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com"

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
// TODO: add description to return value
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
    return;
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

/* REQUIRES: token, eventName, startDate, endDate, description, frequency, assignedRoommates
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: add a chore to RoomieMatter Chore calendar
 * 
 * frequency = {Once, Daily, Weekly, Biweekly, Monthly}
 * if frequency == Once, endDate is ignored
 * 
 * sample return value: {success: true}
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

  // make sure eventName, startDate, frequency are not empty
  if (!data.eventName || !data.eventName.trim() || !data.startDate || !data.frequency) {
    throw new functions.https.HttpsError(
      "invalid input: eventName, startDate or frequency is empty"
    );
  }
  
  // add eventName
  const eventInput = {
    'summary': data.eventName,
  };

  // add startDate, endDate, frequency
  eventInput.start = {};
  eventInput.end = {};
  const date = new Date(data.startDate);
  const dayOfWeek = date.getDay();
  const daysOfWeek = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
  if (data.frequency != "Once") {
    eventInput.start.date = data.startDate;
    eventInput.end.date = data.startDate;
  } else {
    eventInput.start.date = data.startDate;
    eventInput.end.date = data.endDate;
    if (data.frequency == "Daily") {
      eventInput.recurrence = [
        'RRULE:FREQ=DAILY'
      ];
    } else if (data.frequency == "Weekly") {
      const recurrenceInput = 'RRULE:FREQ=WEEKLY;UNTIL=' + endDate.replace(/-/g, '') + 'BYDAY=' + daysOfWeek[dayOfWeek];
      eventInput.recurrence = [recurrenceInput];
    } else if (data.frequency = "Biweekly") {
      const recurrenceInput = 'RRULE:FREQ=WEEKLY;WKST=MO;UNTIL=' + endDate.replace(/-/g, '') + ';INTERVAL=2;BYDAY=' + daysOfWeek[dayOfWeek];
      eventInput.recurrence = [recurrenceInput];
    } else if (data.frequency = "Monthly") {
      const recurrenceInput = 'RRULE:FREQ=MONTHLY;UNTIL=' + endDate.replace(/-/g, '');
      eventInput.recurrence = [recurrenceInput];
    } else {
      throw new functions.https.HttpsError(
        "invalid input: frequency can only be strings in {Once, Daily, Weekly, Biweekly, Monthly}"
      );
    }
  }
  
  // description, assignedRoommates could be null
  if (data.description) {
    eventInput.description = data.description;
  }
  if (data.attendees) {
    let attendees = [];
    for (const attendee of data.attendees) {
      // double check that these are valid emails
      attendees.push({'email': attendee});
    }
    eventInput.attendees = attendees;
  }

  const res = await calendar.events.insert({
    calendarId: choresCalendarId,
    resource: eventInput,
  });

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

  return {success: true};
});

// this function is not done yet
/* REQUIRES: token, eventName, startDate, endDate, description, frequency, assignedRoommates
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete one instance of a chore on RoomieMatter Chore calendar
 * 
 * sample return value: 
 * [{
    assignees = ('lteresa@umich.edu');
    frequency = WEEKLY;
    startDate = "2023-11-30";
    summary = "Take Out Trash";
    },...]
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

  // TODO: figure out how to have date for start and end
  const eventInput = {
    'summary': 'Dishes',
    'description': 'An event that recurrs daily',
    'start': {
      'date': "2023-12-1",
    },
    'end': {
      'date': "2023-12-7",
    },
    'recurrence': [
      'RRULE:FREQ=DAILY'
    ],
    'attendees': [
      {'email': 'lteresa@umich.edu'},
      // {'email': 'sbrin@example.com'},
    ],
    // 'reminders': {
    //   'useDefault': False,
    //   'overrides': [
    //     {'method': 'email', 'minutes': 24 * 60},
    //     {'method': 'popup', 'minutes': 10},
    //   ],
    // },
  };

  const res = await calendar.events.insert({
    calendarId: choresCalendarId,
    resource: eventInput,
  });

  functions.logger.log(res?.data ?? "Failurreeee!");
  functions.logger.log(res);
  const event = res.data;
  if (!event || event.length === 0) {
    functions.logger.log('Failed to add event');
    return;
  }
  functions.logger.log('Added event:');
  functions.logger.log(event);

  return {success: true};
});

// this function is not done yet
/* REQUIRES: token, eventName, startDate, endDate, description, frequency, assignedRoommates
 * MODIFIES: RoomieMatter Chore calendar
 * EFFECTS: delete all instances of a chore on RoomieMatter Chore calendar
 * 
 * sample return value: 
 * [{
    assignees = ('lteresa@umich.edu');
    frequency = WEEKLY;
    startDate = "2023-11-30";
    summary = "Take Out Trash";
    },...]
*/
const deleteChore = functions.https.onCall(async (data, context) => {
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

  // TODO: figure out how to have date for start and end
  const eventInput = {
    'summary': 'Dishes',
    'description': 'An event that recurrs daily',
    'start': {
      'date': "2023-12-1",
    },
    'end': {
      'date': "2023-12-7",
    },
    'recurrence': [
      'RRULE:FREQ=DAILY'
    ],
    'attendees': [
      {'email': 'lteresa@umich.edu'},
      // {'email': 'sbrin@example.com'},
    ],
    // 'reminders': {
    //   'useDefault': False,
    //   'overrides': [
    //     {'method': 'email', 'minutes': 24 * 60},
    //     {'method': 'popup', 'minutes': 10},
    //   ],
    // },
  };

  const res = await calendar.events.insert({
    calendarId: choresCalendarId,
    resource: eventInput,
  });

  functions.logger.log(res?.data ?? "Failurreeee!");
  functions.logger.log(res);
  const event = res.data;
  if (!event || event.length === 0) {
    functions.logger.log('Failed to add event');
    return;
  }
  functions.logger.log('Added event:');
  functions.logger.log(event);

  return {success: true};
});

module.exports = { getChores, addChore, deleteChoreInstance, deleteChore };
