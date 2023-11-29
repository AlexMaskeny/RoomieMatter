const functions = require("firebase-functions");

const { google } = require("googleapis");

// test function that returns hardcoded JSON for frontend testing
const testGetChores = functions.https.onCall(async (data, context) => {
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
    calendarId: "primary",
    timeMin: new Date().toISOString(),
    maxResults: 10,
    singleEvents: true,
    orderBy: "startTime",
  });
  functions.logger.log(res?.data?.items ?? "Failurreeee!");

  functions.logger.log("Entered testGetChores function");

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

module.exports = { testGetChores };
// module.exports = { addChore };
