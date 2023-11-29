const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fs = require('fs').promises;
const path = require('path');
const process = require('process');
const {authenticate} = require('@google-cloud/local-auth');
const {google} = require('googleapis');

// If modifying these scopes, delete token.json.
const SCOPES = ['https://www.googleapis.com/auth/calendar.readonly'];
// The file token.json stores the user's access and refresh tokens, and is
// created automatically when the authorization flow completes for the first
// time.
const TOKEN_PATH = path.join(process.cwd(), 'token.json');
const CREDENTIALS_PATH = path.join(process.cwd(), 'credentialsDesktop.json');

/**
 * Reads previously authorized credentials from the save file.
 *
 * @return {Promise<OAuth2Client|null>}
 */
async function loadSavedCredentialsIfExist() {
  try {
    const content = await fs.readFile(TOKEN_PATH);
    const credentials = JSON.parse(content);
    return google.auth.fromJSON(credentials);
  } catch (err) {
    return null;
  }
}

/**
 * Serializes credentials to a file compatible with GoogleAUth.fromJSON.
 *
 * @param {OAuth2Client} client
 * @return {Promise<void>}
 */
async function saveCredentials(client) {
  const content = await fs.readFile(CREDENTIALS_PATH);
  const keys = JSON.parse(content);
  const key = keys.installed || keys.web;
  const payload = JSON.stringify({
    type: 'authorized_user',
    client_id: key.client_id,
    client_secret: key.client_secret,
    refresh_token: client.credentials.refresh_token,
  });
  await fs.writeFile(TOKEN_PATH, payload);
}

/**
 * Load or request or authorization to call APIs.
 *
 */
async function authorize() {
  let client = await loadSavedCredentialsIfExist();
  if (client) {
    return client;
  }
  functions.logger.log("before authenticate")
  client = await authenticate({
    scopes: SCOPES,
    keyfilePath: CREDENTIALS_PATH,
  });
  functions.logger.log("after authenticate")
  if (client.credentials) {
    await saveCredentials(client);
  }
  return client;
}

/**
 * Lists the next 10 events on the user's primary calendar.
 * @param {google.auth.OAuth2} auth An authorized OAuth2 client.
 */
async function listEvents(auth) {
  const calendar = google.calendar({version: 'v3', auth});
  const res = await calendar.events.list({
    calendarId: 'primary',
    timeMin: new Date().toISOString(),
    maxResults: 10,
    singleEvents: true,
    orderBy: 'startTime',
  });
  const events = res.data.items;
  if (!events || events.length === 0) {
    functions.logger.log('No upcoming events found.');
    return;
  }
  functions.logger.log('Upcoming 10 events:');
  events.map((event, i) => {
    const start = event.start.dateTime || event.start.date;
    functions.logger.log(`${start} - ${event.summary}`);
  });
}

// authorize().then(listEvents).catch(console.error);

// const functions = require("firebase-functions");
// const admin = require("firebase-admin");
// const { google } = require("googleapis");

// chore calendar ID (same for all users)
calendarId =
  "c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com";
// const SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"];

// returns the first 5 chores of logged in user
const getChores = functions.https.onCall(async (data, context) => {
  functions.logger.log("Entered getChores function");

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  // const user = await admin.auth().getUser(context.auth.uid);
  // functions.logger.log('Refresh token:', user.tokensValidAfterTime);  

  // const oauth2Client = new google.auth.OAuth2(
  //   "710199503493-96nefndmgukcakadatjm1ff5au3733p3.apps.googleusercontent.com", 
  //   "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", 
  //   "https://roomiematter.firebaseapp.com/__/auth/handler",
  // );

  // const idToken = "ya29.a0AfB_byBzbl9-DpVORkxh1JUZ3cjIyoASQzG7czJZEz3zwiwt7RUVRSkgw7E7OyTMYf0a6fYrhg9iplIrnB3sjjM2cPXek-AAAlYtHOx27xiPpdfdSYQyNakBYnMyZ5XM0tAF6cAdQkudTySNe7nDZ1BHECzM7xyt0zBMaCgYKAeoSARESFQHGX2Mi-zimEsvaXZmF85EtVY9kLA0171";

  // oauth2Client.setCredentials({
  //   access_token: idToken,
  //   refresh_token: user.tokensValidAfterTime,
  // });

  const calendar = google.calendar({ version: "v3", oauth2Client });
  functions.logger.log(calendar);

  const res = await calendar.events.list({
    calendarId: calendarId,
    timeMin: new Date().toISOString(),
    maxResults: 5,
    singleEvents: true,
    orderBy: "startTime",
  });
  const events = res.data.items;
  if (!events || events.length === 0) {
    functions.logger.log("No upcoming events found.");
    return {};
  }
  const output = events.reduce((jsonArray, event) => {
    const startIndex = event.recurrence[0].indexOf("FREQ=") + 5;
    const endIndex = event.recurrence[0].indexOf(";");
    if (endIndex == -1) {
        endIndex = event.recurrence[0].length;
    }
    jsonArray.push({
        summary: event.summary,
        startDate: event.start.date,
        frequency: event.recurrence[0].substring(startIndex, endIndex),
        assignee: event.attendees
    });
    return jsonArray;
  }, []);

  // functions.logger.log("Upcoming 5 events: ", events);

  return { output };
});

// test function that returns hardcoded JSON for frontend testing
const testGetChores = functions.https.onCall(async (data, context) => {
  functions.logger.log("Entered testGetChores function");

  authorize().then(listEvents).catch(console.error);

  // /*
  const result = [
    {
      summary: "Vacuum",
      startDate: "2023-10-31",
      frequency: "WEEKLY",
      assignee: "lteresa@umich.edu",
    },
    {
      summary: "Take Out Trash",
      startDate: "2023-11-02",
      frequency: "WEEKLY",
      assignee: "lteresa@umich.edu",
    },
    {
      summary: "Mop the floor",
      startDate: "2023-11-08",
      frequency: "MONTHLY",
      assignee: "lteresa@umich.edu",
    },
    {
      summary: "Dishes",
      startDate: "2023-11-09",
      frequency: "DAILY",
      assignee: "lteresa@umich.edu",
    },
    {
      summary: "Clean Bathroom",
      startDate: "2023-11-11",
      frequency: "DAILY",
      assignee: "lteresa@umich.edu",
    },
  ];

  return { result };
  // */
});

module.exports = { getChores, testGetChores };
// module.exports = { addChore };