port module Main exposing (..)

import Lib
import UrlParser exposing (..)


main : Program Never Int (Maybe Msg)
main =
    Lib.routedPersistentProgram
        { route = route
        , incomingRequest = IncomingRequest
        , init = init
        , subscriptions = subscriptions
        , update = update
        }


type Route
    = Hello
    | HelloPerson String


route : Parser (Route -> a) a
route =
    oneOf
        [ map HelloPerson (s "person" </> string)
        , map Hello top
        ]


type Msg
    = IncomingRequest Route Lib.Request


init : Int
init =
    0


subscriptions : Int -> Sub Msg
subscriptions _ =
    Sub.none


update : Msg -> Int -> ( Int, Cmd msg )
update msg n =
    case msg of
        IncomingRequest Hello req ->
            let
                str_ =
                    "re: " ++ req.id
            in
                ( Debug.log str_ (n + 1)
                , Lib.respond { id = req.id, status = 200, body = "hello " ++ toString n }
                )

        IncomingRequest (HelloPerson p) req ->
            ( n
            , Lib.respond { id = req.id, status = 200, body = "hello " ++ p }
            )
