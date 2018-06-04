# Event sourcing examples

Event sourcing is an architectural style where represent all changes as events
and you can reconstruct the state of the world from _just_ the events. For
further explanation I recommend [this post by Martin
Fowler](https://martinfowler.com/eaaDev/EventSourcing.html).

## Why

Event sourcing is usually presented as a way to scale. Commonly micro services.
But I was wondering if I can also use it at small scale. For a small web
application. Because I was wondering if small web applications really need to
have a database and all the complexity that comes from running a distributed
system. Can I get away with storing everything just in memory and use a form of
event sourcing to gain persistence? Currently it looks like the answer is
overwhelmingly positive. Moreover I also great performance due to all data being
readily available.

## What

This repository contains examples of doing "event sourcing at small scale" in
different languages.

All the examples implement the same application: toy-sized trading api

- web server listening on :8080
- `/orderbook` returns current orders
- `/buy/<user-id>/<price>` places a buy order for given user at given price
- `/sell/<user-id>/<price>` places a sell order for given user at given price
- initial state is stored in `init.txt` and events in `log.txt`

## How

All state is only kept in memory and it's (effectively) persisted by storing all
events that affect it to disk. When starting the server these events are then
"replayed" to reproduce the state.

Two primitives are provided to manage state: `snapshot` and `dispatch`.

Snapshot gives you access to current state but does not let you modify it. This
allows efficient lookups without any boilerplate because it doesn't need any
events.

Dispatch takes an event and ships it off to the event loop to be persisted and
processed. This is the only way of getting state changes in.

The "user" also need to provide an update function which applies the event to
the current state. This is where the actual change happens. It is of paramount
importance that this function does not have any side effects - any emails that
you send or API that would call would also get sent or called during the replay.

All implementations are mostly following basic tutorials and strive to be
idiomatic for the platform they're using. They are all packaged with docker so
running any example should be as simple as `docker-compose up` and a specific
run command.

For specifics see README files in respective subdirectories.

## Performance

All implementations can do state updates and reads within 50% (some even 90) of
speed of a hello world on the respective platform.

*TODO* details


