const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {google} = require('googleapis');

// chore calendar ID (should be same for all users)
calendarId = 'c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com';
const SCOPES = ['https://www.googleapis.com/auth/calendar.readonly'];

// test function for google calendar
const listEvents = functions.https.onCall(async (data, context) => {
    functions.logger.log("Entered listEvents function");

    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "RoomieMatter functions can only be called by Authenticated users."
        );
    }

    // let auth = context.auth;
    let auth = context.auth.token.firebase.identities["google.com"][0];
    
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

});

function getCalendarService(oauthAccessToken) {
    const oAuth2Client = new google.auth.OAuth2();
    oAuth2Client.setCredentials({
      access_token: oauthAccessToken,
    });
  
    return google.calendar({ version: 'v3', auth: oAuth2Client });
}

// returns the first 5 chores of logged in user
const getChores = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "RoomieMatter functions can only be called by Authenticated users."
        );
    }

    const userIdToken = context.auth.token;

    admin.auth().verifyIdToken(userIdToken)
    .then((decodedToken) => {
        const uid = decodedToken.uid;
        // Now you have the user's Firebase UID
        // You can access other fields from the decoded token, such as oauth access token
        functions.logger.log(decodedToken);
    })
    .catch((error) => {
        // Handle error
        throw new functions.https.HttpsError(
            "unable to verify token",
            `Error thrown by Google Calendar: ${error.message}`
        );
    });

    const calendarService = getCalendarService(decodedToken.oauthAccessToken);

    calendarService.events.list({
        calendarId: calendarId,
        timeMin: (new Date()).toISOString(),
        maxResults: 10,
        singleEvents: true,
        orderBy: 'startTime',
    }, (err, res) => {
        if (err) return functions.logger.log('The API returned an error: ' + err);
        const events = res.data.items;
        if (events.length) {
            functions.logger.log('Upcoming 10 events:');
            events.map((event, i) => {
                const start = event.start.dateTime || event.start.date;
                functions.logger.log(`${start} - ${event.summary}`);
            });
        } else {
            functions.logger.log('No upcoming events found.');
        }
    });

    // auth = context.auth;
    // let auth = context.auth.token.firebase.identities["google.com"][0];
    // const calendar = google.calendar({version: 'v3', auth});

    // request
    // const request = {
    // 'calendarId': calendarId,
    // 'timeMin': (new Date()).toISOString(),
    // 'showDeleted': false,
    // 'singleEvents': true,
    // 'maxResults': 5,
    // 'orderBy': 'startTime',
    // };

    // // send get request
    // let response;
    // try {
    //     // response = await gapi.client.calendar.events.list(request);
    //     response = await calendar.events.list(request);
    // } catch (err) {
    //     throw new functions.https.HttpsError(
    //         "internal",
    //         `Error thrown by Google Calendar: ${err.message}`
    //     );
    // }

    // const events = response.result.items;

    // // no events found
    // if (!events || events.length == 0) {
    //     functions.logger.log('No upcoming events found.');
    //     return {};
    // }
    
    // // parse events {event title, start date, frequency}
    // const output = events.reduce((jsonArray, event) => {
    //     const startIndex = event.recurrence[0].indexOf("FREQ=") + 5;
    //     const endIndex = event.recurrence[0].indexOf(";");
    //     if (endIndex == -1) {
    //         endIndex = event.recurrence[0].length;
    //     }
    //     jsonArray.push({
    //         summary: event.summary,
    //         startDate: event.start.date, 
    //         frequency: event.recurrence[0].substring(startIndex, endIndex),
    //         assignee: ""
    //     });
    //     return jsonArray;
    // }, []);

    // TODO: make sure return next day + next assignee

    functions.logger.log("Upcoming 10 events: ", events);

    // return {"chores": output};
});

// add new chore
const addChore = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "RoomieMatter functions can only be called by Authenticated users."
        );
    }

    var event = {
        'summary': 'Clean Bathroom',
        'start': {
            'date': '2023-11-1',
        },
        'end': {
            'date': '2023-11-1',
        },
        'recurrence': [
            'RRULE:FREQ=DAILY'
        ],
        'attendees': [
            {'email': 'lteresa@umich.edu'},
        ]
    };

    // send get request
    let response;
    try {
        response = await gapi.client.calendar.events.insert({
            'calendarId': calendarId,
            'resource': event
        });
    } catch (err) {
        throw new functions.https.HttpsError(
            "internal",
            `Error thrown by Google Calendar: ${err.message}`
        );
    }

    return event.htmlLink;
});


// test function that returns hardcoded JSON for frontend testing
const testGetChores = functions.https.onCall(async (data, context) => {
    functions.logger.log("Entered testGetChores function");

    const result = [
        {
          summary: 'Vacuum',
          startDate: '2023-10-31',
          frequency: 'WEEKLY',
          assignee: 'lteresa@umich.edu'
        },
        {
          summary: 'Take Out Trash',
          startDate: '2023-11-02',
          frequency: 'WEEKLY',
          assignee: 'lteresa@umich.edu'
        },
        {
          summary: 'Mop the floor',
          startDate: '2023-11-08',
          frequency: 'MONTHLY',
          assignee: 'lteresa@umich.edu'
        },
        {
          summary: 'Dishes',
          startDate: '2023-11-09',
          frequency: 'DAILY',
          assignee: 'lteresa@umich.edu'
        },
        {
          summary: 'Clean Bathroom',
          startDate: '2023-11-11',
          frequency: 'DAILY',
          assignee: 'lteresa@umich.edu'
        }
      ];

    return result;
});


// module.exports = { listEvents };
module.exports = { getChores };
// module.exports = { addChore };
module.exports = { testGetChores };

// one assignee repeating
// delete instance of event after completion
// functions: complete (delete instance), delete (delete all instances), edit

// problems: rotating assignees