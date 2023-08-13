const express = require('express');
var os = require("os");
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  console.log('received request');
  const hostname = os.hostname();
  res.send(`host: ${hostname}`);
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
});
