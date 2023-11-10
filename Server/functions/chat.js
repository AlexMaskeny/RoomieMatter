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
    "users will message you with a [timestamp] in front of each message. Use this only if needed",
  functions: [],
};

const db = admin.firestore();
const openai = new OpenAI({
  apiKey: "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",
});

const sendChat = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "RoomieMatter functions can only be called by Authenticated users."
    );
  }

  const userId = data.userId;
  const roomId = data.roomId;
  const content = data.content;

  if (userId && roomId && content) {
    try {
      const user = db.collection("users").doc(userId);
      const room = db.collection("rooms").doc(roomId);

      const forGpt = content
        .toLowerCase()
        .includes(`@${settings.modelName.toLowerCase()}`);

      const chat = await db.collection("chats").add({
        room: room,
        user: user,
        role: forGpt ? "user" : "roommate",
        numTokens: 0,
        content: content,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (!forGpt) {
        return { success: true, message: "NO_GPT_CALL" };
      }

      db.collection("rooms")
        .doc(roomId)
        .update({
          typing: admin.firestore.FieldValue.arrayUnion("gpt"),
        });
      const history = await db
        .collection("chats")
        .where("room", "==", room)
        .orderBy("createdAt", "desc")
        .get();

      let totalTokens = 0;
      const formattedHistory = history.reduce((acc, historyMessage) => {
        totalTokens += historyMessage.numTokens ?? 0;
        let gptMessage = {};
        switch (historyMessage.role) {
          case "roommate": {
            return acc;
          }
          case "user":
            gptMessage = {
              role: "user",
              content: `[${new Date(createdAt).toISOString()}] ${
                historyMessage.content
              }`,
            };
            break;
          case "assistant-function": {
            //Less than ideal solution here
            const function_call = JSON.parse(historyMessage.function_call);
            gptMessage = {
              role: "assistant",
              function_call: {
                ...function_call,
                arguments: JSON.stringify(function_call.arguments),
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

      if (totalTokens > 7000) {
        throw new functions.https.HttpsError(
          "internal",
          "History exceeds total limit. Time to add embeddings?"
        );
      }

      const response = await openai.chat.completions.create({
        model: settings.model,
        temperature: settings.temperature,
        functions: settings.functions,
        messages: [
          {
            role: "system",
            content: settings.systemMessage,
          },
          ...formattedHistory,
          {
            role: "user",
            content: `[${new Date().toISOString()}] ${message}`,
          },
        ],
      });

      if (response) {
        const prompt_tokens = response.usage?.prompt_tokens;
        const completion_tokens = response.usage?.completion_tokens;

        const completion = response.choices?.[0]?.message;

        if (completion) {
          const response_role = completion.function_call
            ? "assistant-function"
            : "assistant";

          db.collection("chat").doc(chat.id).update({
            numTokens: prompt_tokens,
          });

          await db.collection("chat").add({
            room: room,
            role: response_role,
            numTokens: completion_tokens,
            content: completion.content,
            function_call: completion.function_call
              ? JSON.stringify(completion.function_call)
              : "",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          let successMessage = "GPT_CALL_NO_FUNCTION";

          if (completion.function_call) {
            //Call some function and resend the result under the 'function' role
            //Also be sure to store it in our database under the function role as well
            successMessage = "GPT_CALL_FUNCTION";
          }

          db.collection("room")
            .doc(roomId)
            .update({
              typing: admin.firestore.FieldValue.arrayRemove("gpt"),
            });

          return { success: true, message: successMessage };
        }
      } else {
        throw new functions.https.HttpsError(
          "internal",
          `Error thrown by OpenAI`
        );
      }
    } catch (error) {
      throw new functions.https.HttpsError(
        "internal",
        `Error thrown by OpenAI`
      );
    }
  } else {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The sendChat function requires JSON requests to include userId, roomId, and content"
    );
  }
});

module.exports = { sendChat };
