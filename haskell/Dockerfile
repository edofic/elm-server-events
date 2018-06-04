FROM haskell:8.2

RUN mkdir /app
WORKDIR /app
COPY ./hs.cabal /app/hs.cabal
RUN cabal update && cabal install --only-dependencies
