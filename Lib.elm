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


type alias Routed msg model =
    Requested (Maybe (RouteAction msg model))


type Requested a
    = Requested RequestId a
    | Direct a


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
                Requested reqId action ->
                    case action of
                        Nothing ->
                            ( model
                            , respond
                                { reqId = reqId
                                , response =
                                    { status = 404, body = "not found" }
                                }
                            )

                        Just (Dispatch m) ->
                            update m model

                        Just (View f) ->
                            ( model, respond { reqId = reqId, response = (f model) } )

                Direct msg ->
                    update msg model

        routeRequest request =
            case parsePath opts.parseRoute (pathToLocation request.url) of
                Just route ->
                    Requested request.id (Just (opts.route request.id route))

                Nothing ->
                    Requested request.id Nothing

        subRequests =
            receiveRequest routeRequest

        subscriptions model =
            Sub.batch [ subRequests, Sub.map (Direct << Just << Dispatch) (opts.subscriptions model) ]
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
