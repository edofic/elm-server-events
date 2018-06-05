# flask with event sourcing

This is a small proof of concept implementation of using event sourcing as a
persistence mechanism for flask. The core is the `State` class which takes
initial state and update and provides a managed state via message persistence.
It exposes `snapshot` and `dispatch` and it's available as `.state` on the
current app. From here on it's flask as usual.

## Usage

Currently the "library" is just the `State` class in main module. For usage
see how the rest of `main.py` is implemented.


## Running

You will need `docker` and `docker-compose`.

```sh
docker-compose up -d
docker-compose exec app bash
python main.py
```


## TODO

- buffered disk writes
- production grade app server
