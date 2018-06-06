# Golang with event sourcing

This is a small proof of concept implementation of using a event sourcing as a
persistence mechanism for an API server implemented in Go with Gorilla router.

The core concept is the `ManagedState` type and it's methods. Http handlers
then just use it as an opaque store.


## Running

You will need `docker` and `docker-compose`

```sh
docker-compose up -d
docker-compose exec app bash
go run main.go
```

## TODO

- clean up the code
- decouple the eent sourcing logic from business logic
