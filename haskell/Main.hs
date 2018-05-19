{-# LANGUAGE OverloadedStrings #-}
import Web.Scotty

import Control.Monad.IO.Class (liftIO)
import Data.Monoid ((<>))
import Data.IORef (IORef, newIORef, readIORef, writeIORef, modifyIORef')
import Data.String (fromString)


main = do
  state <- newIORef (0 :: Int)
  scotty 3000 $
    get "/" $ do
      n <- liftIO $ do
        current <- readIORef state
        let new = current + 1
        writeIORef state new
        return new
      html $ "Hello " <> fromString (show n)
