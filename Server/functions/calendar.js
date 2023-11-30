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

// returns list of chores
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
      choreResult.startDate = event.start.date;

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

module.exports = { getChores };
