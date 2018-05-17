port module Lib exposing (..)

import Platform
import Json.Decode
import Navigation
import UrlParser exposing (..)


type alias RequestId =
    String


type alias Request =
    { id : RequestId
    , method : String
    , url : String
    }


type alias Response =
    { status : Int
    , body : String
    }


type alias DirectedResponse =
    { reqId : RequestId, response : Response }


type Routed msg model
    = MsgForRoute msg
    | RouteView RequestId (model -> Response)
    | Route404 RequestId


type RouteAction msg model
    = Dispatch msg
    | View (model -> Response)


port respond : DirectedResponse -> Cmd msg


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
    { parseRoute : Parser (route -> route) route
    , route : RequestId -> route -> RouteAction msg model
    , init :
        model
        -- TODO figure out intial effects
    , subscriptions : model -> Sub msg
    , update : msg -> model -> ( model, Cmd msg )
    }
    -> Program Never model (Routed msg model)
routedPersistentProgram opts =
    let
        update =
            Native.Persistent.wrapUpdate opts.update

        update_ msg model =
            case msg of
                MsgForRoute m ->
                    update m model

                RouteView reqId f ->
                    ( model, respond { reqId = reqId, response = (f model) } )

                Route404 id ->
                    ( model
                    , respond
                        { reqId = id
                        , response =
                            { status = 404, body = "not found" }
                        }
                    )

        routeRequest request =
            case parsePath opts.parseRoute (pathToLocation request.url) of
                Just route ->
                    case opts.route request.id route of
                        Dispatch userMsg ->
                            MsgForRoute userMsg

                        View f ->
                            RouteView request.id f

                Nothing ->
                    Route404 request.id

        subRequests =
            receiveRequest routeRequest

        subscriptions model =
            Sub.batch [ subRequests, Sub.map MsgForRoute (opts.subscriptions model) ]
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
