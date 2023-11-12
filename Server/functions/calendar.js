const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {google} = require('googleapis');

// chore calendar ID (should be same for all users)
calendarId = 'c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com';

// test function
const listEvents = functions.https.onCall(async (data, context) => {
    functions.logger.log("Entered listEvents function");

    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "RoomieMatter functions can only be called by Authenticated users."
        );
    }

    auth = context.auth;
    
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

// returns the first 5 chores of logged in user
const getChores = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "RoomieMatter functions can only be called by Authenticated users."
        );
    }

    auth = context.auth;
    const calendar = google.calendar({version: 'v3', auth});

    // request
    const request = {
    'calendarId': calendarId,
    'timeMin': (new Date()).toISOString(),
    'showDeleted': false,
    'singleEvents': true,
    'maxResults': 5,
    'orderBy': 'startTime',
    };

    // send get request
    let response;
    try {
        // response = await gapi.client.calendar.events.list(request);
        response = await calendar.events.list(request);
    } catch (err) {
        throw new functions.https.HttpsError(
            "internal",
            `Error thrown by Google Calendar: ${err.message}`
        );
    }

    const events = response.result.items;

    // no events found
    if (!events || events.length == 0) {
        functions.logger.log('No upcoming events found.');
        return {};
    }
    
    // parse events {event title, start date, frequency}
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
            assignee: ""
        });
        return jsonArray;
    }, []);

    // TODO: make sure return next day + next assignee

    functions.logger.log("Upcoming 5 events: ", output);

    return {"chores": output};
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


// module.exports = { listEvents };
module.exports = { getChores };
// module.exports = { addChore };

// one assignee repeating
// delete instance of event after completion
// functions: complete (delete instance), delete (delete all instances), edit

// problems: rotating assignees