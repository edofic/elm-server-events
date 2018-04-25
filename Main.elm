port module Main exposing (..)

import Platform
import Json.Decode


port toJs : String -> Cmd msg


port fromJs : (String -> msg) -> Sub msg


main : Program Never Int Msg
main =
    Platform.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        }


type Msg
    = Incoming String


init : ( Int, Cmd msg )
init =
    ( 0, Cmd.none )


subscriptions : Int -> Sub Msg
subscriptions _ =
    fromJs Incoming


update : Msg -> Int -> ( Int, Cmd msg )
update (Incoming str) n =
    let
        str_ =
            "re: " ++ str
    in
        ( Debug.log str_ n, toJs str_ )
