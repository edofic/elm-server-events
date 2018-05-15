# Server-side Elm with event sourcing

This is a small proof-of-concept implementation of an event sourcing
architecture for Elm on the server.

Incoming requests (handled by node.js) are converted into messages and passed to
your `update` function. You can respond to them by issuing `Cmd`s. The magic
happens behind the curtain: all messages sent to your program also get persisted
to disk (as well as the initial state) you can replay them. Think "time
travelling debugger but for the server". But there is more because you persisted
them this means you effectively persisted the internal state of your server.
This in turn means you can use the internal model as a database and get replay
features for your "database".

Surprisingly many applications will fit in memory so this is not an issue. But
this approach is still limited to applications which don't need to synchronously
talk to other services in order to respond to a request. While you can do it, it
would require a lot of manual book keeping and you won't get any help from the
elm compiler.

## Usage

Currently the "library" is very intertwined with the "application" using it. See
the application part of `Main.elm`. `main.js` and `native.js` contain the
library part.

### Running

You will need `node.js` and `elm` installed. Then to stand the application up

```sh
npm install
elm-make Main.elm --output elm.js
node main.js
```

## TODO

- separate out the library
- router
- cheaper handling of safe HTTTP request
- consider a more robust storage format
