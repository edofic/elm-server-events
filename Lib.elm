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
    = Requested RequestId (RouteAction msg model)
    | Route404 RequestId
    | Direct msg


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
        update : msg -> model -> ( model, Cmd msg )
        update =
            Native.Persistent.wrapUpdate opts.update

        update_ msg model =
            case msg of
                Requested reqId action ->
                    case action of
                        Dispatch m ->
                            let
                                ( model_, cmd ) =
                                    update m model
                            in
                                ( model_, Cmd.map Direct cmd )

                        View f ->
                            ( model, respond { reqId = reqId, response = (f model) } )

                Route404 reqId ->
                    ( model
                    , respond
                        { reqId = reqId
                        , response =
                            { status = 404, body = "not found" }
                        }
                    )

                Direct msg ->
                    let
                        ( model_, cmd ) =
                            update msg model
                    in
                        ( model_, Cmd.map Direct cmd )

        routeRequest request =
            case parsePath opts.parseRoute (pathToLocation request.url) of
                Just route ->
                    Requested request.id (opts.route request.id route)

                Nothing ->
                    Route404 request.id

        subRequests =
            receiveRequest routeRequest

        subscriptions model =
            Sub.batch [ subRequests, Sub.map Direct (opts.subscriptions model) ]
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
