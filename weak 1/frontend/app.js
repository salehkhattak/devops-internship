const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send("Frontend service is running");
});

app.get("/health", (req, res) => {
  res.json({
    status: "healthy",
    service: "frontend"
  });
});

app.get("/info", (req, res) => {
  res.json({
    service: "frontend",
    language: "Node.js",
    version: "1.0.0"
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Frontend service listening on port ${PORT}`);
});