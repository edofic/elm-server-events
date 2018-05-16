port module Lib
    exposing
        ( Request
        , Response
        , persistentProgram
        , receiveRequest
        , respond
        )

import Platform
import Json.Decode


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
    { init :
        model
        -- TODO figure out intial effects
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    }
    -> Program Never model msg
persistentProgram opts =
    Platform.program
        { init = ( Native.Persistent.wrapInit opts, Cmd.none )
        , subscriptions = opts.subscriptions
        , update = Native.Persistent.wrapUpdate opts.update
        }
