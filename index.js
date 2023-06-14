// Create WebSocket connection.
const socket = new WebSocket("ws://localhost:3001");

const sleep = () => new Promise((resolve) => setTimeout(resolve, 1000));

// Connection opened
socket.addEventListener("open", async (event) => {
  console.log("Connected to server");
  socket.send("hello");
  await sleep();
  socket.send("how are you");
  await sleep();
  socket.send("give me a file");
  await sleep();
  socket.send("blabla");
  // await sleep();
  // socket.close();
});

// Listen for messages
socket.addEventListener("message", (event) => {
  const data = event.data;
  console.log(data);
  if (data.constructor === Blob) {
    const image = new Image();
    image.width = 50;
    image.src = URL.createObjectURL(data);
    document.body.appendChild(image);
  }
});

socket.addEventListener("close", (event) => {
  console.log("Connection closed");
});
