const fs = require('fs');

// TODO load this from elm runtime
function F2(fun)
{
  function wrapper(a) { return function(b) { return fun(a,b); }; }
  wrapper.arity = 2;
  wrapper.func = fun;
  return wrapper;
}

const base64encode = data => Buffer.from(data).toString('base64');
const base64decode = base64 => Buffer.from(base64, 'base64').toString('utf8');

const stream = fs.createWriteStream('log.txt', {flags: 'a'});
stream.once('open', () => null);
process.on('exit', () => stream.end());

// inject globals for elm
global._user$project$Native_Persistent = {
  wrapInit({init, update}) {
    if (fs.existsSync('init.txt')) {
      console.log('replaying')

      const raw = fs.readFileSync('init.txt', 'utf8');
      let model = JSON.parse(base64decode(raw));
      console.log('starting with', model)

      // TODO streaming
      const rawMsgs = fs.readFileSync('log.txt', 'utf8').split('\n')
      for (let rawMsg of rawMsgs) {
        if (!rawMsg.length) {
          continue
        }
        console.log('parsing', rawMsg, rawMsg.length)
        const msg = JSON.parse(base64decode(rawMsg));
        model = update(msg)(model)._0  // ignore effects when replaying
        console.log('applied', msg, 'to get', model)
      }
      return model
    } else {
      fs.writeFile('init.txt', base64encode(JSON.stringify(init)));
      return init;
    }
  },
  wrapUpdate(f) {
    const g = (msg, model) => {
      stream.write(base64encode(JSON.stringify(msg)));
      stream.write('\n');
      return f(msg)(model)
    }
    return F2(g)
  }
}
