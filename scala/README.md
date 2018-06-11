# Play with event sourcing

This is a small proof of concept implementation of using event sourcing as a
persistence mechanism for PlayFramework 2. The core is the `ManagedState` class
which takes initial state and update and provides a managed state via message
persistence. It's used as a base class for the `State` class which provides the
logic and gets injected (as as singleton) into controllers.

## Usage

Currently the "library" is just `services.ManagedState`. For usage see how
`services.State` and `controllers.HomeController` are implemented.


## Running

If you have `sbt` installed you can use it: `sbt runProd` (or `sbt ~compile` or
`sbt run` for development).

Otherwise you will need `docker` and `docker-compose`.

```sh
docker-compose up -d
docker-compose exec app bash
sbt runProd
```


## TODO

- buffered disk writes
