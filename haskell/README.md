# Scotty with event sourcing

This is a small proof of concept implementation of using event sourcing as a
persistence mechanism for Scotty. The core is the `eventSource` combinator which
takes initial state and update and provides a managed state via message
persistence. From here on it's usual scotty.

## Usage

Currently the "library" is just a few functions in the main module. For usage
see how `main` is implemented in `Main.hs`.


## Running

You will need `docker` and `docker-compose`.

```sh
docker-compose up -d
docker-compose exec app bash
cabal run
```


## TODO

- separate out the library
- buffered disk writes
