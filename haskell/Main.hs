{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

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
    asks' = sortOn price asks
    bids' = sortOn (negate . price) bids

placeOrder :: Order -> Orderbook -> Orderbook
placeOrder order orderbook@(Orderbook {asks, bids}) =
  let orderbook' =
        case orderType order of
          Buy -> orderbook {bids = order : bids}
          Sell -> orderbook {asks = order : asks}
  in matchOne $ normalizeOrderbook orderbook'

main :: IO ()
main = do
  state <- newIORef $ Orderbook [] []
  scotty 3000 $ do
    get "/" $ html "hello"
    get "/orderbook" $ do
      orderbook <- liftIO $ readIORef state
      json orderbook
    get "/sell/:userId/:price" $ do
      userId <- param "userId"
      price <- param "price"
      let order = Order { userId = userId, price=price, orderType = Sell }
      liftIO $ modifyIORef' state $ placeOrder order
      html "ok"
    get "/buy/:userId/:price" $ do
      userId <- param "userId"
      price <- param "price"
      let order = Order { userId = userId, price=price, orderType = Buy }
      liftIO $ modifyIORef' state $ placeOrder order
      html "ok"
