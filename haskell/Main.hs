{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Concurrent (forkIO)
import Control.Concurrent.MVar (MVar, newEmptyMVar, putMVar, readMVar, takeMVar)
import Control.Monad (forM_, forever)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (FromJSON, ToJSON, decode, encode)
import qualified Data.ByteString.Lazy as LBS
import Data.Foldable (foldl')
import Data.IORef (IORef, modifyIORef', newIORef, readIORef, writeIORef)
import Data.List (sortOn)
import Data.Monoid ((<>))
import Data.String (fromString)
import GHC.Generics (Generic)
import System.Directory (doesFileExist)
import System.IO (IOMode(AppendMode), hFlush, openFile)

import Web.Scotty
import qualified Web.Scotty.Trans as T

type UserId = Int

data OrderType
  = Buy
  | Sell
  deriving (Eq, Show, Generic)

instance ToJSON OrderType

instance FromJSON OrderType

data Order = Order
  { userId :: UserId
  , price :: Int
  , orderType :: OrderType
  } deriving (Eq, Show, Generic)

instance ToJSON Order

instance FromJSON Order

data Orderbook = Orderbook
  { asks :: [Order]
  , bids :: [Order]
  } deriving (Eq, Show, Generic)

instance ToJSON Orderbook

instance FromJSON Orderbook

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
  deriving (Eq, Show, Generic)

instance FromJSON Msg

instance ToJSON Msg

update :: Msg -> Model -> (Model, ())
update (PlaceOrder order) model = (placeOrder order model, ())

main :: IO ()
main = do
  app <- eventSource initial update route
  scotty 3000 app
  where
    initial = Orderbook [] []
    route snapshot dispatch = do
      get "/" $ html "hello"
      get "/orderbook" $ do
        orderbook <- snapshot
        json orderbook
      get "/sell/:userId/:price" $ do
        userId <- param "userId"
        price <- param "price"
        let order = Order {userId = userId, price = price, orderType = Sell}
        dispatch $ PlaceOrder order
        html "ok"
      get "/buy/:userId/:price" $ do
        userId <- param "userId"
        price <- param "price"
        let order = Order {userId = userId, price = price, orderType = Buy}
        dispatch $ PlaceOrder order
        html "ok"

eventSource ::
     (MonadIO m, ToJSON model, FromJSON model, ToJSON msg, FromJSON msg)
  => model
  -> (msg -> model -> (model, done))
  -> (m model -> (msg -> m done) -> a)
  -> IO a
eventSource initial update setup = do
  state <- newIORef $ initial
  queue <- newEmptyMVar
  let snapshot = liftIO $ readIORef state
  let dispatch msg =
        liftIO $ do
          doneMVar <- newEmptyMVar
          putMVar queue (msg, doneMVar)
          readMVar doneMVar
  initExists <- doesFileExist "init.txt"
  logExists <- doesFileExist "log.txt"
  if initExists && logExists
    then do
      Just initial <- decode <$> LBS.readFile "init.txt"
      updates <- readJsonLines "log.txt"
      let final = foldl' (\model msg -> fst (update msg model)) initial updates
      final `seq` writeIORef state final
    else LBS.writeFile "init.txt" (encode initial)
  logFile <- openFile "log.txt" AppendMode
  let update' msg model = do
        LBS.hPut logFile $ encode msg
        LBS.hPut logFile "\n"
        hFlush logFile
        return $ update msg model
  forkIO $
    forever $ do
      (msg, doneMVar) <- takeMVar queue
      currentState <- readIORef state
      (nextState, response) <- update' msg currentState
      nextState `seq` writeIORef state nextState
      putMVar doneMVar response
  return $ setup snapshot dispatch

readJsonLines :: (FromJSON a) => FilePath -> IO [a]
readJsonLines path = processFile <$> LBS.readFile path
  where
    processFile bs =
      let (line, rest) = LBS.break (\w -> w == 10) bs
      in if LBS.length line > 0
           then let Just a = decode line
                in a : processFile (LBS.drop 1 rest)
           else LBS.length rest `seq` []
