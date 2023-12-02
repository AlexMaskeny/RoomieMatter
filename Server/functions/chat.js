const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { OpenAI } = require("openai");

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
  model: "gpt-4",
  temperature: 0.5,
  apiKey: "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", //This should probably be an env var
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
  apiKey: "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",
});

//Context here is defined by us. It is special and contains things like userId, roomId, chatId (of the sent chat), etc
//I'm making all of these async to make it easy to add them in the sendChat function
const getFunctions = async (context) => {
  const userRef = db.collection("users").doc(context.userId);
  const roomRef = db.collection("rooms").doc(context.roomId);
  let apiFunctions = [];
  /* ============== [ CHANGE STATUS ] ============== */
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
      functions.logger.log(status);
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

  /* ============== [ GET STATUS ] ============== */
  const userRooms = await db
    .collection("user_rooms")
    .where("room", "==", roomRef)
    .get();
  const plainUserRooms = userRooms.docs.map((doc) => doc.data());
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

  return apiFunctions;
};

const stopGPTTyping = (roomId) => {
  db.collection("room")
    .doc(roomId)
    .update({
      typing: admin.firestore.FieldValue.arrayRemove("gpt"),
    });
};

const formatHistoryForGPT = (plainHistory) => {
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
};

const sendChat = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const token = data.token;

  if (!token) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The Google OAuth token is invalid or missing"
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

    //Get the history and format it for GPT.
    //This history contains the message just sent because we await its insertion
    const history = await db
      .collection("chats")
      .where("room", "==", roomRef)
      .orderBy("createdAt", "asc")
      .get();
    const plainHistory = history.docs.map((doc) => doc.data());
    const formattedHistory = formatHistoryForGPT(plainHistory);

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
      chatId: chat.id,
      content,
    });

    if (apiFunctions.length > 0) {
      //This map just formats the functions to be compatible with GPT's API
      gptAPIObject.functions = apiFunctions.map((func) => {
        const formattedFunc = { ...func };
        delete formattedFunc.func;
        return formattedFunc;
      });
    }

    const response = await openai.chat.completions.create(gptAPIObject);
    functions.logger.log(response);

    if (!response) {
      stopGPTTyping(roomId);
      throw new functions.https.HttpsError(
        "internal",
        "Error thrown by OpenAI"
      );
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
      function_call: completion.function_call,
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
    throw new functions.https.HttpsError("internal", "Error thrown by OpenAI");
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
        .where("createdAt", "<", new Date(maxTimestamp))
        .orderBy("createdAt", "desc")
        .limit(20)
        .get()
    : { docs: [] };
  const olderPlainHistoryData = olderRawHistory.docs
    .map((doc) => doc.data())
    .reverse();

  const newerRawHistory = minTimestamp
    ? await db
        .collection("chats")
        .where("room", "==", room)
        .where("createdAt", ">", new Date(minTimestamp))
        .orderBy("createdAt", "asc")
        .get()
    : { docs: [] };
  const newerPlainHistoryData = newerRawHistory.docs.map((doc) => doc.data());

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
