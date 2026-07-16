const express = require("express");

const app = express();

app.get("/", (req, res) => {
    res.send("Frontend Service");
});

app.get("/health", (req, res) => {
    res.json({
        status: "healthy"
    });
});

app.get("/info", (req, res) => {
    res.json({
        service: "frontend",
        language: "Node.js",
        version: "1.0"
    });
});

app.listen(3000, () => {
    console.log("Frontend running");
});