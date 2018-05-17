port module Lib
    exposing
        ( Request
        , Response
        , persistentProgram
        , routedPersistentProgram
        , receiveRequest
        , respond
        )

import Platform
import Json.Decode
import Navigation
import UrlParser exposing (..)


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


routedPersistentProgram :
    { route : Parser (route -> route) route
    , incomingRequest : route -> Request -> msg
    , init :
        model
        -- TODO figure out intial effects
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    }
    -> Program Never model (Maybe msg)
routedPersistentProgram opts =
    let
        update =
            Native.Persistent.wrapUpdate opts.update

        update_ msg model =
            case msg of
                Just m ->
                    update m model

                Nothing ->
                    ( model, Cmd.none )

        routeRequest request =
            case parsePath opts.route (pathToLocation request.url) of
                Just route ->
                    Just (opts.incomingRequest route request)

                Nothing ->
                    Nothing

        subRequests =
            receiveRequest routeRequest

        subscriptions model =
            Sub.batch [ subRequests, Sub.map Just (opts.subscriptions model) ]
    in
        Platform.program
            { init = ( Native.Persistent.wrapInit opts, Cmd.none )
            , subscriptions = subscriptions
            , update = update_
            }


pathToLocation : String -> Navigation.Location
pathToLocation path =
    { href = path
    , host = ""
    , hostname = ""
    , protocol = ""
    , origin = ""
    , port_ = ""
    , pathname = path
    , search = ""
    , hash = ""
    , username = ""
    , password = ""
    }
