module I18NextGen exposing (files, flagsDecoder, Flags)

{-| This module contains several functions useful in [elm-codegen](https://github.com/mdgriffith/elm-codegen) projects
that allow you to generate
type-safe code for use with [ChristophP/elm-18next](https://package.elm-lang.org/packages/ChristophP/elm-i18next/latest/).
The documentation in this project's [README](https://github.com/abradley2/elm-i18next-gen/blob/master/README.md)
is likely more useful for consuming this module, so start there.


# Utilities

@docs files, flagsDecoder, Flags

-}

import Dict exposing (Dict)
import Elm
import Elm.Annotation as Type
import Gen.I18Next
import Json.Decode as Decode exposing (Decoder)
import Maybe.Extra as Maybe
import Parser exposing ((|.), (|=), Parser)
import ReCase
import Set


varParser : Parser String
varParser =
    Parser.succeed identity
        |. Parser.token "{{"
        |= Parser.variable
            { start = Char.isAlpha
            , inner = Char.isAlphaNum
            , reserved = Set.empty
            }
        |. Parser.token "}}"


type TranslateFn
    = ReplaceNone
    | Replace1 String
    | Replace2 String String
    | Replace3 String String String


translateFnParser : Parser TranslateFn
translateFnParser =
    Parser.succeed
        (\a b c ->
            Nothing
                |> Maybe.or
                    (Maybe.map Replace1 a)
                |> Maybe.or
                    (Maybe.map2 Replace2 a b)
                |> Maybe.or
                    (Maybe.map3 Replace3 a b c)
                |> Maybe.withDefault ReplaceNone
        )
        |. Parser.chompUntilEndOr "{{"
        |= Parser.oneOf [ Parser.map Just varParser, Parser.succeed Nothing ]
        |. Parser.chompUntilEndOr "{{"
        |= Parser.oneOf [ Parser.map Just varParser, Parser.succeed Nothing ]
        |. Parser.chompUntilEndOr "{{"
        |= Parser.oneOf [ Parser.map Just varParser, Parser.succeed Nothing ]


popLast : List a -> List a
popLast =
    List.reverse >> List.drop 1 >> List.reverse


{-| The opaque type for parsed Flags from `flagsDecoder` that will be needed to generate the resulting code
-}
type Flags
    = Flags Flags_


type alias Flags_ =
    { node : Node
    , formatted : Dict String String
    }


{-| A decoder that consumes a JSON object that conforms to the [I18Next v2 specification](https://www.i18next.com/misc/json-format#i18next-json-v2).
This is just a simple object with string keys and string values, that may contain nested objects. The delimiter to replacement placeholders must be
the "double curly" format {{like so}}.
-}
flagsDecoder : Decoder Flags
flagsDecoder =
    Decode.map2
        Flags_
        nodeDecoder
        (Decode.map formatNode nodeDecoder)
        |> Decode.andThen (Flags >> Decode.succeed)


{-| Using the decoded flags (from `flagsDecoder`), this function will generate a list of `Elm.File`'s
to be used in your main `Generate.elm` function for [elm-codegen](https://github.com/mdgriffith/elm-codegen).
-}
files : Flags -> List Elm.File
files (Flags flags) =
    let
        helperFiles : List Elm.File
        helperFiles =
            flags.formatted
                |> Dict.toList
                |> List.foldr
                    (\( k, v ) fileDict ->
                        let
                            filePath =
                                String.split "." k
                                    |> popLast
                                    |> List.map (ReCase.recase ReCase.ToPascal)
                                    |> (::) "Translations"

                            methodName =
                                String.split "." k |> List.reverse |> List.head |> Maybe.withDefault k |> ReCase.recase ReCase.ToCamel

                            translationMethod =
                                Parser.run translateFnParser v |> Result.withDefault ReplaceNone

                            genMethod =
                                Elm.declaration methodName <|
                                    case translationMethod of
                                        ReplaceNone ->
                                            Elm.fn
                                                ( "translations", Nothing )
                                                (\translations ->
                                                    Gen.I18Next.call_.tf translations (Elm.string k)
                                                )

                                        Replace1 arg1 ->
                                            Elm.fn2
                                                ( "translations", Nothing )
                                                ( "replacements"
                                                , Just <|
                                                    Type.record
                                                        [ ( arg1, Type.string ) ]
                                                )
                                                (\translations replacements ->
                                                    Gen.I18Next.call_.trf
                                                        translations
                                                        Gen.I18Next.make_.curly
                                                        (Elm.string k)
                                                        (Elm.list [ Elm.tuple (Elm.string arg1) (Elm.get arg1 replacements) ])
                                                )

                                        Replace2 arg1 arg2 ->
                                            Elm.fn2
                                                ( "translations", Nothing )
                                                ( "replacements"
                                                , Just <|
                                                    Type.record
                                                        [ ( arg1, Type.string ), ( arg2, Type.string ) ]
                                                )
                                                (\translations replacements ->
                                                    Gen.I18Next.call_.trf
                                                        translations
                                                        Gen.I18Next.make_.curly
                                                        (Elm.string k)
                                                        (Elm.list [ Elm.tuple (Elm.string arg1) (Elm.get arg1 replacements), Elm.tuple (Elm.string arg2) (Elm.get arg2 replacements) ])
                                                )

                                        Replace3 arg1 arg2 arg3 ->
                                            Elm.fn2
                                                ( "translations", Nothing )
                                                ( "replacements"
                                                , Just <|
                                                    Type.record
                                                        [ ( arg1, Type.string ), ( arg2, Type.string ), ( arg3, Type.string ) ]
                                                )
                                                (\translations replacements ->
                                                    Gen.I18Next.call_.trf
                                                        translations
                                                        Gen.I18Next.make_.curly
                                                        (Elm.string k)
                                                        (Elm.list [ Elm.tuple (Elm.string arg1) (Elm.get arg1 replacements), Elm.tuple (Elm.string arg2) (Elm.get arg2 replacements), Elm.tuple (Elm.string arg3) (Elm.get arg3 replacements) ])
                                                )
                        in
                        Dict.update
                            filePath
                            (Maybe.map ((::) genMethod) >> Maybe.withDefault [ genMethod ] >> Just)
                            fileDict
                    )
                    Dict.empty
                |> Dict.toList
                |> List.map (\( file, declarations ) -> Elm.file file declarations)
    in
    (Elm.file
        [ "Language" ]
     <|
        [ Elm.declaration "defaultLanguage" <|
            Gen.I18Next.call_.fromTree <|
                Elm.list <|
                    List.singleton <|
                        Elm.tuple (Elm.string "") (nodeToTree flags.node)
        ]
    )
        :: helperFiles


type Node
    = Translation String
    | TranslationDict (Dict String Node)


nodeToTree : Node -> Elm.Expression
nodeToTree n =
    case n of
        Translation t ->
            Gen.I18Next.call_.string (Elm.string t)

        TranslationDict d ->
            Gen.I18Next.call_.object
                (Elm.list
                    (d
                        |> Dict.toList
                        |> List.map (\( k, v ) -> Elm.tuple (Elm.string k) (nodeToTree v))
                    )
                )


formatNode : Node -> Dict String String
formatNode node =
    let
        runNode : String -> Node -> Dict String String -> Dict String String
        runNode prefix n acc =
            case n of
                Translation str ->
                    Dict.insert prefix str acc

                TranslationDict dict ->
                    Dict.foldl
                        (\nextPrefix nextNode nextAcc ->
                            runNode
                                (if prefix == "" then
                                    nextPrefix

                                 else
                                    prefix ++ "." ++ nextPrefix
                                )
                                nextNode
                                nextAcc
                        )
                        Dict.empty
                        dict
                        |> Dict.union acc
    in
    runNode "" node Dict.empty


nodeDecoder : Decoder Node
nodeDecoder =
    Decode.oneOf
        [ Decode.map Translation Decode.string
        , Decode.map TranslationDict (Decode.dict (Decode.lazy <| \_ -> nodeDecoder))
        ]
