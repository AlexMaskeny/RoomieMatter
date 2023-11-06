//Install java and do firebase emulators:start
//go to this directory and do node chatTest.js

const functionURL = "http://127.0.0.1:5001/roomiematter/us-central1/sendChat";

fetch(functionURL, {
  method: "POST",
  headers: {
    // Mimic the header that Firebase SDK would send
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    data: {
      test: "Test",
    },
  }),
})
  .then((response) => response.json()) // Parse the JSON response
  .then((data) => {
    console.log("Callable function response:", data.result);
  })
  .catch((error) => {
    console.error("Error calling function:", error);
  });
