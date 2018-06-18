var express = require('express');
var bodyParser = require('body-parser);
var path = require('path')
var app = express();
var port = process.PORT.env || 3000;

app.listen(port, () => {
    console.log("connect to server on port " + port);
})
