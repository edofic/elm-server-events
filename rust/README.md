# Actix with event sourcing

This is a small proof of concept implementation of using event sourcing as a
persistence mechanism for actix. It's implemented as the `ManagedState` type
which is then used as application state in actix. As a user you need to provide
initial state and update function - managed state will do persistence to disk
(via storing messages) and replay.

## Variants

There are two variants of this implemented right now: `rust-mutable` and
`rust-immutable`. The difference is that the mutable one allows you to mutate
your state in your update method while the immutable one does not. This brings
better performance for snapshots at the cost of slightly more cmoplexity on
updates.

## Usage

See `src/main.rs` for an example.
Library implemetation is in `src/lib.rs`.


## Running

You will need `docker` and `docker-compose`.

```sh
docker-compose up -d
docker-compose exec app bash
cargo run
```


## TODO

- separate out the library in cargo.toml
- reduced locking for writes in the immutable version
