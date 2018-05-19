{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Concurrent (forkIO)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Monad (forever)
import Control.Monad.IO.Class (liftIO)
import Data.Aeson (ToJSON)
import Data.IORef (IORef, modifyIORef', newIORef, readIORef, writeIORef)
import Data.List (sortOn)
import Data.Monoid ((<>))
import Data.String (fromString)

import GHC.Generics (Generic)

import Web.Scotty

type UserId = Int

data OrderType
  = Buy
  | Sell
  deriving (Eq, Show, Generic)

instance ToJSON OrderType

data Order = Order
  { userId :: UserId
  , price :: Int
  , orderType :: OrderType
  } deriving (Eq, Show, Generic)

instance ToJSON Order

data Orderbook = Orderbook
  { asks :: [Order]
  , bids :: [Order]
  } deriving (Eq, Show, Generic)

instance ToJSON Orderbook

type Model = Orderbook

matchOne :: Orderbook -> Orderbook
matchOne Orderbook {asks = ask:asks, bids = bid:bids}
  | price ask <= price bid = Orderbook asks bids
matchOne orderbook = orderbook

normalizeOrderbook :: Orderbook -> Orderbook
normalizeOrderbook Orderbook {asks, bids} = Orderbook asks' bids'
  where
    asks' = take 100 $ sortOn price asks
    bids' = take 100 $ sortOn (negate . price) bids

placeOrder :: Order -> Orderbook -> Orderbook
placeOrder order orderbook@(Orderbook {asks, bids}) =
  let orderbook' =
        case orderType order of
          Buy -> orderbook {bids = order : bids}
          Sell -> orderbook {asks = order : asks}
  in matchOne $ normalizeOrderbook orderbook'

data Msg =
  PlaceOrder Order

update :: Msg -> Model -> Model
update (PlaceOrder order) model = placeOrder order model

main :: IO ()
main = do
  state <- newIORef $ Orderbook [] []
  queue <- newEmptyMVar
  let dispatch msg =
        liftIO $ do
          doneMVar <- newEmptyMVar
          putMVar queue (msg, doneMVar)
          return doneMVar
  forkIO $
    forever $ do
      (msg, doneMVar) <- takeMVar queue
      modifyIORef' state $ update msg
      putMVar doneMVar ()
  scotty 3000 $ do
    get "/" $ html "hello"
    get "/orderbook" $ do
      orderbook <- liftIO $ readIORef state
      json orderbook
    get "/sell/:userId/:price" $ do
      userId <- param "userId"
      price <- param "price"
      let order = Order {userId = userId, price = price, orderType = Sell}
      done <- dispatch $ PlaceOrder order
      liftIO $ takeMVar done  -- await for the order to be processed
      html "ok"
    get "/buy/:userId/:price" $ do
      userId <- param "userId"
      price <- param "price"
      let order = Order {userId = userId, price = price, orderType = Buy}
      done <- dispatch $ PlaceOrder order
      liftIO $ takeMVar done  -- await for the order to be processed
      html "ok"
