//Install java and do firebase emulators:start
//go to this directory and do node chatTest.js

// const { OpenAI } = require("openai");
// const openai = new OpenAI({
//   apiKey: "",
// });

// async function askGPT4() {
//   try {
//     const response = await openai.chat.completions.create({
//       messages: [
//         {
//           role: "system",
//           content: "You are an assistant called 'The Housekeeper'",
//         },
//         {
//           role: "user",
//           content: "HI! Who are you?",
//         },
//       ],
//       model: "gpt-4",
//     });
//     console.log(response.choices);
//   } catch (error) {
//     console.log(error);
//   }
// }

// askGPT4();

// const functionURL = "http://127.0.0.1:5001/roomiematter/us-central1/sendChat";

// fetch(functionURL, {
//   method: "POST",
//   headers: {
//     // Mimic the header that Firebase SDK would send
//     "Content-Type": "application/json",
//   },
//   body: JSON.stringify({
//     data: {
//       test: "Test",
//     },
//   }),
// })
//   .then((response) => response.json()) // Parse the JSON response
//   .then((data) => {
//     console.log("Callable function response:", data.result);
//   })
//   .catch((error) => {
//     console.error("Error calling function:", error);
//   });
