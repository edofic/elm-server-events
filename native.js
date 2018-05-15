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

const stream = fs.createWriteStream("log.txt");
stream.once('open', () => null);

process.on('exit', () => stream.end());

// inject globals for elm
global._user$project$Native_Persistent = {
  wrapInit(init) {
    console.log("init", init);
    return init;
  },
  wrapUpdate(f) {
    const g = (msg, model) => {
      console.log("updating", msg, model);
      stream.write(base64encode(JSON.stringify(msg)));
      stream.write('\n');
      return f(msg)(model)
    }
    return F2(g)
  }
}
