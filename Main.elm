port module Main exposing (..)

import Platform
import Json.Decode

-- LIBRARY part

type alias Request =
    { id : String
    , method : String
    , url : String
    }


type alias Response =
    { id : String
    , status : Int
    , body : String
    }


port respond : Response -> Cmd msg


port receiveRequest : (Request -> msg) -> Sub msg


-- Application part

main : Program Never Int Msg
main =
    Platform.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        }


type Msg
    = IncomingRequest Request


init : ( Int, Cmd msg )
init =
    ( 0, Cmd.none )


subscriptions : Int -> Sub Msg
subscriptions _ =
    receiveRequest IncomingRequest


update : Msg -> Int -> ( Int, Cmd msg )
update (IncomingRequest req) n =
    let
        str_ =
            "re: " ++ req.id
    in
        ( Debug.log str_ (n + 1), respond { id = req.id, status = 200, body = "hello " ++ toString n } )
