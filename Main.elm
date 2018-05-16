port module Main exposing (..)

import Lib


main : Program Never Int Msg
main =
    Lib.persistentProgram
        { init = init
        , subscriptions = subscriptions
        , update = update
        }


type Msg
    = IncomingRequest Lib.Request


init : Int
init =
    0


subscriptions : Int -> Sub Msg
subscriptions _ =
    Lib.receiveRequest IncomingRequest


update : Msg -> Int -> ( Int, Cmd msg )
update (IncomingRequest req) n =
    let
        str_ =
            "re: " ++ req.id
    in
        ( Debug.log str_ (n + 1)
        , Lib.respond { id = req.id, status = 200, body = "hello " ++ toString n }
        )
