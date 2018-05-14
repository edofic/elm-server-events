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


persistentProgram :
    { init : ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    }
    -> Program Never model msg
persistentProgram opts =
    Platform.program
        { init = Native.Persistent.wrapInit opts.init
        , subscriptions = opts.subscriptions
        , update = Native.Persistent.wrapUpdate opts.update
        }



-- Application part


main : Program Never Int Msg
main =
    persistentProgram
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
