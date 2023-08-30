const express = require('express');
var os = require("os");
const app = express();
const port = 8080;

app.get('/', (req, res) => {
  console.log('received request');
  const hostname = os.hostname();
  res.send(`host: ${hostname}`);
});

app.get('/health/liveness', (req, res) => {
  res.send('ok');
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
});
