// TODO load this from elm runtime
function F2(fun)
{
  function wrapper(a) { return function(b) { return fun(a,b); }; }
  wrapper.arity = 2;
  wrapper.func = fun;
  return wrapper;
}

// inject globals for elm
global._user$project$Native_Persistent = {
  wrapInit(init) {
    console.log("init", init);
    return init;
  },
  wrapUpdate(f) {
    const g = (msg, model) => {
      console.log("updating", msg, model);
      return f(msg)(model)
    }
    return F2(g)
  }
}
