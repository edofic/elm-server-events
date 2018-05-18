port module Main exposing (..)

import Lib
import List
import Dict
import UrlParser exposing (..)


main : Program Never Model (Lib.Routed Msg Model)
main =
    Lib.routedPersistentProgram
        { parseRoute = parseRoute
        , route = route
        , init = init
        , subscriptions = subscriptions
        , update = update
        }


type Route
    = Hello
    | HelloPerson String
    | ViewOrderbook
    | DoOrder OrderDirection UserId Int


parseRoute : Parser (Route -> a) a
parseRoute =
    oneOf
        [ map HelloPerson (s "person" </> string)
        , map ViewOrderbook (s "orderbook")
        , map (DoOrder Buy) (s "bid" </> int </> int)
        , map (DoOrder Sell) (s "ask" </> int </> int)
        , map Hello top
        ]


route : Lib.RequestId -> Route -> Lib.RouteAction Msg Model
route reqId r =
    case r of
        HelloPerson person ->
            Lib.View (viewGreeter person)

        Hello ->
            Lib.Dispatch (Bump reqId)

        ViewOrderbook ->
            Lib.View viewOrderbook

        DoOrder direction userId price ->
            Lib.Dispatch (PlaceOrder reqId direction userId price)


type Msg
    = Bump Lib.RequestId
    | PlaceOrder Lib.RequestId OrderDirection UserId Int


type alias Orderbook =
    { bids : List OrderEntry
    , asks : List OrderEntry
    }


normalizeOrderbook : Orderbook -> Orderbook
normalizeOrderbook { bids, asks } =
    { bids = List.sortBy (\o -> -o.price) bids
    , asks = List.sortBy (\o -> o.price) asks
    }


type alias OrderEntry =
    { userId : UserId
    , direction : OrderDirection
    , price : Int
    }


type OrderDirection
    = Buy
    | Sell


type alias UserId =
    Int


type alias Model =
    { orderbook : Orderbook
    , balances : Dict.Dict UserId Int
    }


placeOrder : OrderEntry -> Model -> Model
placeOrder order model =
    let
        orderbook =
            model.orderbook

        orderbookWithEntry =
            case order.direction of
                Buy ->
                    normalizeOrderbook { orderbook | bids = order :: model.orderbook.bids }

                Sell ->
                    normalizeOrderbook { orderbook | asks = order :: model.orderbook.asks }
    in
        matchOne { model | orderbook = orderbookWithEntry }


matchOne : Model -> Model
matchOne model =
    case ( model.orderbook.asks, model.orderbook.bids ) of
        ( ask :: asks, bid :: bids ) ->
            if ask.price <= bid.price then
                { model | orderbook = { asks = asks, bids = bids } }
            else
                model

        _ ->
            model


init : Model
init =
    { orderbook = { bids = [], asks = [] }
    , balances = Dict.fromList [ ( 1, 1000 ), ( 2, 1000 ) ]
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        Bump reqId ->
            ( model
            , Lib.respond { reqId = reqId, response = { status = 200, body = "todo" } }
            )

        PlaceOrder reqId direction userId price ->
            let
                order =
                    { userId = userId, direction = direction, price = price }

                model_ =
                    placeOrder order model
            in
                ( model_, Lib.respond { reqId = reqId, response = { status = 200, body = "ok" } } )


viewGreeter : String -> Model -> Lib.Response
viewGreeter name _ =
    { status = 200, body = "hello " ++ name }


viewOrderbook : Model -> Lib.Response
viewOrderbook model =
    { status = 200, body = toString model.orderbook }
