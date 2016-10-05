module Game.Resources
    exposing
        ( Texture
        , TextureFilter
        , linear
        , nearest
        , textureSize
        , Msg
        , Resources
        , init
        , loadTextures
        , LoadTextureConfig
        , loadTexturesWithConfig
        , getTexture
        , update
        )

{-|
A module for managing resources needed for games.
This currently only manages textures, but a future version might add sounds, 3d-meshes etc..

# Resources
@docs Resources, init, update, Msg

## Textures
@docs Texture, loadTextures, getTexture

@docs loadTexturesWithConfig, LoadTextureConfig

@docs TextureFilter, linear, nearest

@docs textureSize
-}

import Dict exposing (Dict)
import Task
import WebGL


{-| -}
type alias Texture =
    WebGL.Texture


{-| -}
type alias TextureFilter =
    WebGL.TextureFilter


{-| -}
linear : TextureFilter
linear =
    WebGL.Linear


{-| -}
nearest : TextureFilter
nearest =
    WebGL.Nearest


{-| -}
type Msg
    = LoadTexture String Texture
    | FailedToLoad String


{-|
The main type of this library
-}
type Resources
    = R (Dict String Texture)


{-| -}
init : Resources
init =
    R Dict.empty



-- Loads a texture from the given url. PNG and JPEG are known to work, but other formats have not been as well-tested yet. Configurable filter.


{-|
Loads a list of textures from the given urls.
PNGs and JPEGs are known to work.
For WebGL make sure that your textures have a dimension with a power of two, e.g. 2^n x 2^m
-}
loadTextures : List String -> Cmd Msg
loadTextures urls =
    urls
        |> List.map
            (\url ->
                Task.perform (\_ -> FailedToLoad url)
                    (LoadTexture url)
                    (WebGL.loadTexture url)
            )
        |> Cmd.batch


{-| -}
type alias LoadTextureConfig msg =
    { success : Msg -> msg
    , failed : String -> msg
    }


{-|
Same as loadTextures, but gives you more controll
by being able to react to a texture loading error
and by specifying a texture filter.

    loadTexturesWithConfig
        { success = Resources
        , failed = LoadingTextureFailed
        }
        [ (linear, "images/blob.png"), (nearest, "images/box.jpeg") ]

-}
loadTexturesWithConfig : LoadTextureConfig msg -> List ( TextureFilter, String ) -> Cmd msg
loadTexturesWithConfig { success, failed } urls =
    urls
        |> List.map
            (\( filter, url ) ->
                Task.perform (\_ -> failed url)
                    (\t -> success (LoadTexture url t))
                    (WebGL.loadTextureWithFilter filter url)
            )
        |> Cmd.batch


{-|
-}
update : Msg -> Resources -> Resources
update msg (R res) =
    case msg of
        LoadTexture url t ->
            R (Dict.insert url t res)

        FailedToLoad url ->
            R res
                |> Debug.log ("failed to load texture: " ++ toString url)


{-|
Returns a maybe as the texture might not be loaded yet.
-}
getTexture : String -> Resources -> Maybe Texture
getTexture url (R res) =
    Dict.get url res


{-|
-}
textureSize : Texture -> ( Int, Int )
textureSize =
    WebGL.textureSize