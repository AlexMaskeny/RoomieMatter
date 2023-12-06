const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");
const {
  getChoresBody,
  addChoreBody,
  editChoreBody,
  completeChoreBody,
  deleteChoreBody,
  getEventsBody,
  addEventBody,
  editEventBody,
  deleteEventBody,
} = require("./calendar");
const { capitalizeFirstLetter, americanDateFormatter } = require("./utils");

//We have to enforce that @Housekeeper cannot be sent in the chat
//while gpt is typing. Also, only display role type "user" or "assistant" or "roommate"
//in the chat. Functions should not be displayed.

/*
OPENAI ROLES:
- "user": The invoker of the GPT message
- "assistant": The response by GPT (can be a function call or a message)
- "function": A response by our servers giving the result of a function call

ROOMIEMATTER ROLES:
- "roommate": Just a regular chat message with no GPT innovation
- "user": The invoker of the GPT message
- "assistant": A regular message response from GPT
- "assistant-function": A function call from GPT
- "function": A response by our servers giving the result of a function call
*/

const settings = {
  model: "gpt-3.5-turbo-16k",
  temperature: 0.5,
  apiKey: /* Your ChatGPT API key here */,
  modelName: "Housekeeper",
  systemMessage:
    "You are The Housekeeper. You act as a Household assistant for RoomieMatter." +
    "You can perform a variety of functions which are specified by your functions " +
    "param. Ensure that you don't use special formatting because RoomieMatter doesn't " +
    "support that. Also, keep your responses short. Rarely go above 3 sentence responses." +
    "users will message you with a [timestamp] in front of each message. Use this only if needed. ",
};

const db = admin.firestore();
const openai = new OpenAI({
  apiKey: /* Your ChatGPT API key here */,
});

//Context here is defined by us. It is special and contains things like userId, roomId, chatId (of the sent chat), etc
//I'm making all of these async to make it easy to add them in the sendChat function
async function getFunctions(context) {
  const userRef = db.collection("users").doc(context.userId);
  const roomRef = db.collection("rooms").doc(context.roomId);

  //We will push each function to the array. This allows us to
  //execute any commands we require to form the function
  let apiFunctions = [];

  const userRooms = await db
    .collection("user_rooms")
    .where("room", "==", roomRef)
    .get();

  const plainUserRooms = userRooms.docs.map((doc) => doc.data());

  const now = new Date();

  //This just defines a map of user display names to some information
  //about them. The user sending this
  //chat is stored as "currentUser" because they might not refer
  //to themselves in 3rd person
  let displayNameToUser = {};
  for (let i = 0; i < plainUserRooms.length; i++) {
    const userRoom = plainUserRooms[i];
    const userSnapshot = await userRoom.user.get();
    const user = userSnapshot.data();
    const userAndStatus = {
      ...user,
      status: userRoom.status ?? "",
    };
    displayNameToUser[userAndStatus.displayName] = userAndStatus;
    if (userAndStatus.uuid === context.userId) {
      displayNameToUser.currentUser = { ...userAndStatus };
    }
  }

  //Get all the chores & event.
  const allChores = (
    await getChoresBody(
      { token: context.token, roomId: context.roomId },
      context.context
    )
  ).chores;
  const allEvents = (
    await getEventsBody(
      { token: context.token, roomId: context.roomId },
      context.context
    )
  ).events;

  /* ============== [ FUNC: CHANGE STATUS ] ============== */
  {
    apiFunctions.push({
      name: "changeStatus",
      description: "Change the current user's status in the RoomieMatter app",
      parameters: {
        type: "object",
        properties: {
          status: {
            type: "string",
            enum: ["sleeping", "studying", "not home", "home"],
          },
        },
        required: ["status"],
      },
      func: async ({ status }) => {
        const userRoomSnapshot = await db
          .collection("user_rooms")
          .where("room", "==", roomRef)
          .where("user", "==", userRef)
          .get();
        if (userRoomSnapshot.docs.length > 0) {
          const userRoomId = userRoomSnapshot.docs[0].id;
          db.collection("user_rooms").doc(userRoomId).update({
            status,
          });
          return `Successfully changed your status to ${status}`;
        } else {
          return "There was a problem changing your status...";
        }
      },
    });
  }

  /* ============== [ FUNC: GET STATUS(S) ] ============== */
  {
    apiFunctions.push({
      name: "getStatus",
      description:
        "Get's the current user's status or another member of the house's status. " +
        "If the current user wants their own status, use the property 'currentUser'. " +
        "If the current user wants all of statuses, use the property 'all'. " +
        "If you need to see who's in the house, use the 'all' property as well " +
        "and just ignore their statuses. You can do the same with 'currentUser'.",
      parameters: {
        type: "object",
        properties: {
          displayName: {
            type: "string",
            enum: [...Object.keys(displayNameToUser), "currentUser", "all"],
          },
        },
        required: ["displayName"],
      },
      func: async ({ displayName }) => {
        switch (displayName) {
          case "all":
            return Object.entries(displayNameToUser).reduce(
              (acc, [displayName, user]) => {
                if (displayName === "currentUser") {
                  return acc;
                } else {
                  return (
                    acc +
                    `${displayName}'s current status is ${
                      user.status ?? "No Status"
                    }. `
                  );
                }
              },
              ""
            );
          case "currentUser":
            return `Your current status is ${displayNameToUser.currentUser.status}.`;
          default:
            return `${displayName}'s current status is ${displayNameToUser[displayName].status}`;
        }
      },
    });
  }

  const CALENDAR_ITEM_TYPE = { event: "event", chore: "chore" };
  const currentDate = (type) => {
    if (type === CALENDAR_ITEM_TYPE.chore) {
      return americanDateFormatter(now);
    } else {
      return now.toISOString();
    }
  };
  const currentDateFormat = (type) => {
    if (type === CALENDAR_ITEM_TYPE.chore) {
      return "YYYY-MM-DD";
    } else {
      return "ISO";
    }
  };
  const getMemberField = (type) => {
    return type === CALENDAR_ITEM_TYPE.chore ? "assignedRoommates" : "guests";
    
  }

  /* ============== [ HELPER: CREATE GET CALENDAR ITEM(S) ] =============*/
  const createGetCalendarItems = (type) => {
    const allItems = type === CALENDAR_ITEM_TYPE.chore ? allChores : allEvents;

    apiFunctions.push({
      name: `get${capitalizeFirstLetter(type)}`,
      description:
        `The user will attempt to identify one or more ${type}s using plain text. The plain text contains at least 1 ` +
        `parameter that can be used to identify a list of ${type}s. For relative dates (like 'tomorrow') the current date is ${currentDate(
          type
        )}`,
      parameters: {
        type: "object",
        properties: {
          eventName: {
            type: "string",
            description: `The name of the ${type}`,
            enum: allItems.map((item) => item.eventName),
          },
          beginDate: {
            type: "string",
            description: `The start of a date range to look in. ${currentDateFormat(
              type
            )} format.`,
          },
          endDate: {
            type: "string",
            description: `The end of a date range to look in. ${currentDateFormat(
              type
            )} format.`,
          },
        },
      },
      func: async ({ eventName, beginDate, endDate }) => {
        const matchingItems = allItems.filter((item) => {
          const eventNameCondition = item.eventName === eventName;
         
          const begin = new Date(beginDate);
          const end = new Date(endDate);
          let dateCondition = false;
          if (type === CALENDAR_ITEM_TYPE.event) {
            const itemDateBegin = new Date(item.startDatetime);
            const itemDateEnd = new Date(item.endDatetime);
            dateCondition = itemDateBegin >= begin && itemDateEnd <= end
          } else {
            const itemDate = new Date(item.date);
            dateCondition = itemDate >= begin && itemDate <= end;
          }

          return eventNameCondition || dateCondition;
        });

        const formattedMatchingItems = matchingItems.map((item) => {
          const assignedRoommates = Object.entries(displayNameToUser).reduce(
            (acc, [displayName, userInfo]) => {
              if (item[getMemberField(type)]?.includes(userInfo.uuid)) {
                return [...acc, userInfo.displayName];
              } else {
                return acc;
              }
            },
            []
          );
          let itemSummary = "";
          if (type === CALENDAR_ITEM_TYPE.chore) {
            itemSummary = `On ${item.date} there is a ${type} called ${item.eventName}. `;
          } else {
            itemSummary = `The ${type} called ${item.eventName} is from ${item.startDatetime} to ${item.endDatetime} `;
          }
          
          if (item.frequency) {
            itemSummary += `This ${type} repeats ${item.frequency}. `;
          }
          if (assignedRoommates?.length > 0) {
            itemSummary += `The following roommates are assigned to this ${type}: `;
            assignedRoommates.forEach((roommate, index) => {
              if (index === assignedRoommates.length - 1) {
                itemSummary += `${roommate}.`;
              } else {
                itemSummary += `${roommate}, `;
              }
            });
          } else {
            itemSummary += `No one is assigned to this ${type} yet. `;
          }
          if (item.description) {
            itemSummary += `Description: ${item.description}.`;
          }

          return itemSummary;
        });

        return JSON.stringify(formattedMatchingItems);
      },
    });
  };
  createGetCalendarItems(CALENDAR_ITEM_TYPE.chore); //FUNC: GET CHORE(S)
  createGetCalendarItems(CALENDAR_ITEM_TYPE.event); //FUNC: GET EVENT(S)

  /* ============== [ HELPER: CREATE ADD CALENDAR ITEM ] =============== */
  const createAddCalendarItem = (type) => {
    apiFunctions.push({
      name: `add${capitalizeFirstLetter(type)}`,
      description: `Creates a new ${type}. the current date is ${currentDate(
        type
      )}`,
      parameters: {
        type: "object",
        properties: {
          eventName: {
            type: "string",
            description: `The name of the ${type}`,
          },
          date: {
            type: "string",
            description: `The date the ${type} beings in ${currentDateFormat(
              type
            )} format.`,
          },
          ...(type === CALENDAR_ITEM_TYPE.event
            ? {
                endDate: {
                  type: "string",
                  description: `The date the ${type} ends in ${currentDateFormat(
                    type
                  )} format.`,
                },
              }
            : {
                frequency: {
                  type: "string",
                  description: `How often the ${type} repeats`,
                  enum: ["Once", "Daily", "Biweekly", "Weekly", "Monthly"],
                },
                endRecurrenceDate: {
                  type: "string",
                  description: `Date stating when the recurrence specified by the frequency ends in ${currentDateFormat(
                    type
                  )} format`,
                },
              }),
          description: {
            type: "string",
            description: `Description of the ${type}`,
          },
          assignedRoommates: {
            type: "array",
            description: `A list of the display names of the users added to the ${type}`,
            items: {
              type: "string",
              description:
                "The display name of an assigned roommate. The user is 'currentUser'",
              enum: Object.keys(displayNameToUser),
            },
          },
        },
        required: ["eventName", "date", "frequency"],
      },
      func: async ({
        eventName,
        date,
        endDate,
        frequency,
        endRecurrenceDate,
        description,
        assignedRoommates,
      }) => {
        let addItemData =
          type === CALENDAR_ITEM_TYPE.event
            ? {
                eventName,
                startDatetime: date,
                endDatetime: endDate,
                token: context.token,
                roomId: context.roomId,
              }
            : {
                eventName,
                date,
                frequency,
                token: context.token,
                roomId: context.roomId,
              };

        if (endRecurrenceDate) {
          addItemData.endRecurrenceDate = endRecurrenceDate;
        }
        if (description) {
          addItemData.description = description;
        }
        if (assignedRoommates) {
          addItemData[
            getMemberField(type)
          ] = assignedRoommates.map((attendee) => {
            const userInfo = displayNameToUser[attendee];
            return userInfo.uuid;
          });
        }

        const addItemFunction =
          type === CALENDAR_ITEM_TYPE.event ? addEventBody : addChoreBody;
        const result = await addItemFunction(addItemData, context.context);
        if (result) {
          return `Successfully added a new ${type}!`;
        } else {
          return `Failed to add the ${type}`;
        }
      },
    });
  };
  createAddCalendarItem(CALENDAR_ITEM_TYPE.chore); //FUNC: ADD CHORE
  createAddCalendarItem(CALENDAR_ITEM_TYPE.event); //FUNC: ADD EVENT

  /* ============== [ HELPER: CREATE EDIT CALENDAR ITEM ] ============== */
  const createEditCalendarItem = (type) => {
    const allItems = type === CALENDAR_ITEM_TYPE.chore ? allChores : allEvents;

    apiFunctions.push({
      name: `edit${capitalizeFirstLetter(type)}`,
      description:
        `Edits an existing ${type} with at least 1 parameter. If one of newFrequency, newEndFrequency, or newDate are specified, they all must be. ` +
        `For relative dates (like 'tomorrow'), the current date is ${currentDate(
          type
        )}`,
      parameters: {
        type: "object",
        properties: {
          eventName: {
            type: "string",
            description: `The ${type} that the user is attempting to edit`,
            enum: allItems.map((item) => item.eventName),
          },
          newEventName: {
            type: "string",
            description: `Specifies an updated title for the ${type}`,
          },
          newDate: {
            type: "string",
            description: `A new start date of the ${type} in ${currentDateFormat(
              type
            )} format`,
          },
          ...(type === CALENDAR_ITEM_TYPE.event
            ? {
                newEndDate: {
                  type: "string",
                  description: `A new end date of the ${type} in ${currentDateFormat(
                    type
                  )} format. Must be used with newDate`,
                },
              }
            : {
                newFrequency: {
                  type: "string",
                  description: `A new frequency specifying how often the ${type} repeats`,
                  enum: ["Once", "Daily", "Biweekly", "Weekly", "Monthly"],
                },
                newEndFrequency: {
                  type: "string",
                  description: `Specifies when the repeating stops in ${currentDateFormat(
                    type
                  )} format.`,
                  enum: ["Once", "Daily", "Biweekly", "Weekly", "Monthly"],
                },
              }),
          description: {
            type: "string",
            description: `a new description of the ${type}`,
          },
          addedRoommates: {
            type: "array",
            description: `A list of the display names of the users added to the ${type}`,
            items: {
              type: "string",
              description:
                "The display name of an added roommate. The invoking user is 'currentUser'",
              enum: Object.keys(displayNameToUser),
            },
          },
          removedRoommates: {
            type: "array",
            description: `A list of the display names of the users removed from the ${type}`,
            items: {
              type: "string",
              description:
                "The display name of a removed roommate. The invoking user is 'currentUser'",
              enum: Object.keys(displayNameToUser),
            },
          },
        },
        required: ["eventName"],
      },
      func: async ({
        eventName,
        newEventName,
        newDate,
        newEndDate,
        newFrequency,
        description,
        addedRoommates,
        removedRoommates,
      }) => {
        const item = allItems.find((item) => item.eventName === eventName);
        const id = type === CALENDAR_ITEM_TYPE.chore ? "instanceId" : "eventId";
        let editItemData = {
          [id]: item[id],
          token: context.token,
          roomId: context.roomId,
        };

        if (newEventName) {
          editItemData.eventName = newEventName;
        }
        if (newDate) {
          editItemData[
            type === CALENDAR_ITEM_TYPE.event ? "startDatetime" : "date"
          ] = newDate;
        }
        if (newEndDate) {
          editItemData.endDatetime = newEndDate;
        }
        if (newFrequency) {
          editItemData.frequency = newFrequency;
        }
        if (description) {
          editItemData.description = newEventName;
        }

        if (addedRoommates) {
          editItemData[
            getMemberField(type)
          ] = [
            ...(item[
              getMemberField(type)
            ] ?? []),
            ...addedRoommates.reduce((acc, attendee) => {
              const userInfo = displayNameToUser[attendee];
              if (item[
                getMemberField(type)
              ]?.includes(userInfo.uuid)) {
                return acc;
              } else {
                return [...acc, userInfo.uuid];
              }
            }, []),
          ];
        }

        if (removedRoommates) {
          const removedRoommatesUuids = removedRoommates.map((attendee) => {
            const userInfo = displayNameToUser[attendee];
            return userInfo?.uuid ?? "";
          });
          editItemData[
            getMemberField(type)
          ] =
            item[getMemberField(type)]?.filter(
              (attendeeUuid) => !removedRoommatesUuids.includes(attendeeUuid)
            ) ?? [];
        }

        const editItemFunction =
          type === CALENDAR_ITEM_TYPE.event ? editEventBody : editChoreBody;
        const result = await editItemFunction(editItemData, context.context);
        if (result) {
          return `Successfully edited the ${eventName} ${type}!`;
        } else {
          return `Failed to edit the ${eventName} ${type}`;
        }
      },
    });
  };
  createEditCalendarItem(CALENDAR_ITEM_TYPE.chore); //FUNC: EDIT CHORE
  createEditCalendarItem(CALENDAR_ITEM_TYPE.event); //FUNC: EDIT EVENT

  /* ============== [ HELPER: CREATE DELETE CALENDAR ITEM ] ============== */
  const createDeleteCalendarItem = (type) => {
    const allItems = type === CALENDAR_ITEM_TYPE.chore ? allChores : allEvents;

    apiFunctions.push({
      name: `delete${capitalizeFirstLetter(type)}`,
      description: `Deletes an existing ${type}`,
      parameters: {
        type: "object",
        properties: {
          eventName: {
            type: "string",
            description: `The ${type} that the user is attempting to delete`,
            enum: allItems.map((item) => item.eventName),
          },
        },
        required: ["eventName"],
      },
      func: async ({ eventName }) => {
        const deleteItemFunction =
          type === CALENDAR_ITEM_TYPE.event ? deleteEventBody : deleteChoreBody;
        const item = allItems.find((item) => item.eventName === eventName);
        
        const id = type === CALENDAR_ITEM_TYPE.chore ? "instanceId" : "eventId";
        const deleteItemData = {
          [id]: item[id],
          token: context.token,
          roomId: context.roomId,
        };
        const result = await deleteItemFunction(
          deleteItemData,
          context.context
        );
        if (result) {
          return `Successfully deleted the ${eventName} ${type}`;
        } else {
          return `Failed to delete the ${eventName} ${type}`;
        }
      },
    });
  };
  createDeleteCalendarItem(CALENDAR_ITEM_TYPE.chore); //FUNC: DELETE CHORE
  createDeleteCalendarItem(CALENDAR_ITEM_TYPE.event); //FUNC: DELETE EVENT

  /* ============== [ FUNC: COMPLETE CHORE ] ============== */
  {
    apiFunctions.push({
      name: `completeChores`,
      description: `Marks an existing chore as completed`,
      parameters: {
        type: "object",
        properties: {
          eventName: {
            type: "string",
            description: `The chore that the user is attempting to mark as completed`,
            enum: allChores.map((chore) => chore.eventName),
          },
        },
        required: ["eventName"],
      },
      func: async ({ eventName }) => {
        const chore = allChores.find((chore) => chore.eventName === eventName);
        const completeChoreData = {
          instanceId: chore.instanceId,
          token: context.token,
          roomId: context.roomId,
        };
        const result = await completeChoreBody(
          completeChoreData,
          context.context
        );
        if (result) {
          return `Successfully marked the ${eventName} chore as completed`;
        } else {
          return `Failed to mark the ${eventName} chore as completed`;
        }
      },
    });
  }

  return apiFunctions;
}

function stopGPTTyping(roomId) {
  db.collection("rooms")
    .doc(roomId)
    .update({
      typing: admin.firestore.FieldValue.arrayRemove("gpt"),
    });
}

function formatHistoryForGPT(plainHistory) {
  return plainHistory.reduce((acc, historyMessage) => {
    let gptMessage = {};
    switch (historyMessage.role) {
      case "roommate": {
        return acc;
      }
      case "user":
        gptMessage = {
          role: "user",
          content: `[${
            historyMessage?.createdAt?.toDate()?.toISOString() ?? ""
          }] ${historyMessage.content}`,
        };
        break;
      case "assistant-function": {
        const function_call = historyMessage.function_call ?? {};
        gptMessage = {
          role: "assistant",
          content: "",
          function_call: {
            name: function_call.name,
            arguments: function_call.arguments,
          },
        };
        break;
      }
      case "assistant":
        gptMessage = {
          role: "assistant",
          content: historyMessage.content,
        };
        break;
      case "function":
        gptMessage = {
          role: "function",
          name: historyMessage.function.name,
          content: historyMessage.function.content,
        };
        break;
    }
    return [...acc, gptMessage];
  }, []);
}

const sendChat = functions.https.onCall(async (data, context) => {
  const token = data?.token;

  if (!context.auth || !token) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const userId = data.userId;
  const roomId = data.roomId;
  const content = data.content;

  if (!userId || !roomId || !content) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The sendChat function requires JSON requests to include userId, roomId, and content"
    );
  }

  try {
    const userRef = db.collection("users").doc(userId);
    const roomRef = db.collection("rooms").doc(roomId);

    //Detects if the message contains the @<the model's name>. Case insensitive
    const isForGpt = content
      .toLowerCase()
      .includes(`@${settings.modelName.toLowerCase()}`);

    //Insert the chat sent
    const chat = await db.collection("chats").add({
      room: roomRef,
      user: userRef,
      role: isForGpt ? "user" : "roommate",
      numTokens: 0,
      content: content,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    //If its not going to GPT then we're done
    if (!isForGpt) {
      return { success: true, message: "NO_GPT_CALL" };
    }

    //Make bot appear to be typing
    db.collection("rooms")
      .doc(roomId)
      .update({
        typing: admin.firestore.FieldValue.arrayUnion("gpt"),
      });
    functions.logger.log("Check 1");

    //Get the history and format it for GPT.
    //This history contains the message just sent because we await its insertion
    const history = await db
      .collection("chats")
      .where("room", "==", roomRef)
      .orderBy("createdAt", "asc")
      .get();
    const plainHistory = history.docs.map((doc) => doc.data());
    const formattedHistory = formatHistoryForGPT(plainHistory);
    functions.logger.log(formattedHistory);

    let gptAPIObject = {
      model: settings.model,
      temperature: settings.temperature,
      messages: [
        {
          role: "system",
          content: settings.systemMessage,
        },
        ...formattedHistory,
      ],
    };

    const apiFunctions = await getFunctions({
      userId,
      roomId,
      token,
      content,
      context,
      chatId: chat.id,
    });

    if (apiFunctions.length > 0) {
      //This map just formats the functions to be compatible with GPT's API
      gptAPIObject.functions = apiFunctions.map((func) => {
        const formattedFunc = { ...func };
        delete formattedFunc.func;
        return formattedFunc;
      });
    }
    functions.logger.log(gptAPIObject);

    const response = await openai.chat.completions.create(gptAPIObject);
    functions.logger.log(response);

    if (!response) {
      stopGPTTyping(roomId);
      throw "Error thrown by OpenAI";
    }

    const prompt_tokens = response.usage?.prompt_tokens;
    const completion_tokens = response.usage?.completion_tokens;

    const completion = response.choices?.[0]?.message;

    if (!completion) {
      throw ["Completion object was invalid", completion];
    }

    //If GPT called a function then we'll store it as an assistant-function
    const response_role = completion.function_call
      ? "assistant-function"
      : "assistant";

    //Store the TOTAL HISTORY TOKENS in the most recent message
    //(Yes this means the total history. GPT doesn't give message specific counts)
    //Every chat stored will store the tokens it uses & the whole history before it
    db.collection("chats").doc(chat.id).update({
      numTokens: prompt_tokens,
    });

    await db.collection("chats").add({
      room: roomRef,
      role: response_role,
      numTokens: prompt_tokens + completion_tokens,
      content: completion.content,
      function_call: completion.function_call ?? "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (!completion.function_call) {
      stopGPTTyping(roomId);
      return { success: true, message: "GPT_CALL_NO_FUNCTION" };
    }

    const apiFunction = apiFunctions.find(
      (apiFunc) => apiFunc.name === completion.function_call.name
    );

    //Parse the GPT-returned arguments and execute the appropriate function
    const rawFunctionResult = await apiFunction.func(
      JSON.parse(completion.function_call.arguments)
    );

    if (!rawFunctionResult) {
      throw "Failure executing GPT-called function locally";
    }

    //Store the function's response for future GPT calls
    const functionChat = await db.collection("chats").add({
      room: roomRef,
      role: "function",
      numTokens: 0,
      function: {
        name: apiFunction.name,
        content: rawFunctionResult,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    //Add GPT's response and the function response to the history
    gptAPIObject.messages.push(completion);
    gptAPIObject.messages.push({
      role: "function",
      name: apiFunction.name,
      content: rawFunctionResult,
    });

    const readableFunctionResult = await openai.chat.completions.create(
      gptAPIObject
    );

    if (!readableFunctionResult) {
      throw "Failure to convert the raw function response into a human readable format";
    }

    const functionPromptTokens = readableFunctionResult.usage?.prompt_tokens;
    const functionCompletionTokens =
      readableFunctionResult.usage?.completion_tokens;

    const functionCompletion = readableFunctionResult.choices?.[0]?.message;

    db.collection("chats").doc(functionChat.id).update({
      numTokens: functionPromptTokens,
    });
    db.collection("chats").add({
      room: roomRef,
      role: "assistant",
      numTokens: functionPromptTokens + functionCompletionTokens,
      content: functionCompletion.content,
      function_call: "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    stopGPTTyping(roomId);
    return { success: true, message: "GPT_CALL_FUNCTION" };
  } catch (error) {
    functions.logger.log(error);
    stopGPTTyping(roomId);
    throw new functions.https.HttpsError(
      "internal",
      "Error when calling OpenAI"
    );
  }
});

const getChats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }
  const roomId = data.roomId;
  const maxTimestamp = data.maxTimestamp;
  const minTimestamp = data.minTimestamp;
  if (!roomId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The getChats function requires JSON requests to include roomId"
    );
  }
  const room = db.collection("rooms").doc(roomId);
  const olderRawHistory = maxTimestamp
    ? await db
        .collection("chats")
        .where("room", "==", room)
        .where("role", "in", ["user", "assistant", "roommate"])
        .where("createdAt", "<", new Date(maxTimestamp))
        .orderBy("createdAt", "desc")
        .limit(20)
        .get()
    : { docs: [] };
  const olderPlainHistoryData = olderRawHistory.docs
    .map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }))
    .reverse();

  const newerRawHistory = minTimestamp
    ? await db
        .collection("chats")
        .where("room", "==", room)
        .where("role", "in", ["user", "assistant", "roommate"])
        .where("createdAt", ">", new Date(minTimestamp))
        .orderBy("createdAt", "asc")
        .get()
    : { docs: [] };
  const newerPlainHistoryData = newerRawHistory.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));

  const makeHistory = async (plainHistoryData) => {
    let userRefs = [];
    plainHistoryData.forEach((chat) => {
      if (["roommate", "user"].includes(chat.role)) {
        if (!userRefs.find((userRef) => userRef.id === chat.user?.id)) {
          userRefs.push(chat.user);
        }
      }
    });
    let users = new Map();
    for (let i = 0; i < userRefs.length; i++) {
      const userRef = userRefs[i];
      const userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        const userData = userSnapshot.data();
        users.set(userRef.id, userData);
      }
    }

    return plainHistoryData.reduce((acc, chat) => {
      const generalParams = {
        content: chat.content ?? "",
        createdAt: chat.createdAt?.toDate()?.toISOString() ?? "",
        role: chat.role ?? "",
        id: chat.id ?? "",
      };

      switch (chat.role) {
        case "assistant":
          return [
            ...acc,
            {
              ...generalParams,
              profilePicture:
                "https://umich.edu/includes/panels/gallery/images/block-m-maize.png",
            },
          ];
        case "roommate":
        case "user": {
          const userData = users.get(chat.user.id);
          if (userData) {
            return [
              ...acc,
              {
                ...generalParams,
                userId: userData.uuid,
                displayName: userData.displayName,
                profilePicture: userData.photoUrl,
              },
            ];
          }
          return acc;
        }
        default:
          return acc;
      }
    }, []);
  };
  return {
    olderHistory: await makeHistory(olderPlainHistoryData),
    newerHistory: await makeHistory(newerPlainHistoryData),
  };
});

module.exports = { sendChat, getChats };
