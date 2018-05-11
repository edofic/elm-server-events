const elm = require('./elm.js');
const http = require('http');
const uuidv4 = require('uuid/v4');

const app = elm.Main.worker();

const activeResponses = {};

http.createServer(function (request, response) {
  const id = uuidv4();
  activeResponses[id] = response;
  app.ports.receiveRequest.send({
    id: id,
    method: request.method,
    url: request.url
  });

}).listen(8080);

app.ports.respond.subscribe(response => {
  const pending = activeResponses[response.id];
  delete activeResponses[response.id];
  pending.writeHead(response.status, {'Content-Type': 'text/plain'});
  pending.end(response.body);
});

console.log('Server running at http://127.0.0.1:8080/');
