const elm = require('./elm.js')

const app = elm.Main.worker()

app.ports.toJs.subscribe(re => console.log('received response:', re))

app.ports.fromJs.send('foo')
