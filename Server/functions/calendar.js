const functions = require("firebase-functions");
const admin = require("firebase-admin");

// returns the first 5 chores of logged in user
const get_chores = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "RoomieMatter functions can only be called by Authenticated users."
        );
    }

    // chore calendar ID (should be same for all users)
    calendarId = 'c_5df0bf9c096fe8c9bf0a70fc19f1cf28dae8901ff0fcab98989a0445fb052625@group.calendar.google.com';

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
        response = await gapi.client.calendar.events.list(request);
    } catch (err) {
        throw new functions.https.HttpsError(
            "internal",
            `Error thrown by Google Calendar: ${err.message}`
        );
    }

    const events = response.result.items;

    // no events found
    if (!events || events.length == 0) {
        return {};
    }
    
    // parse events {event title, start date}
    const output = events.reduce((jsonArray, event) => {
        jsonArray.push({
            summary: event.summary,
            startDate: event.start.date
        });
        return jsonArray;
    }, []);

    return output;
});

module.exports = { get_chores };
