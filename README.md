# Elm I18Next Code Generation

An [elm-codegen](https://github.com/mdgriffith/elm-codegen) library for creating type-safe helper methods
for the excellent [ChristophP/elm-i18next](https://package.elm-lang.org/packages/ChristophP/elm-i18next/latest/)
package.

If you have a large Elm application in a business setting, you should strongly consider supporting internationalization
even if you aren't considering adding extra languages to your app. Your project manager who would much rather change a line
in a JSON file than put another 1-point ticket into your sprint will thank you for it.

## Usage

* Follow the ["Getting Started" guide from elm-codegen](https://github.com/mdgriffith/elm-codegen/blob/main/guide/GettingStarted.md)
* In your initialized codegen project, `elm install abradley2/elm-i18next-gen`

```Generate.elm
import I18Next.Gen
import Gen.CodeGen.Generate as Generate
import Json.Decode exposing (Value)

main : Platform Value () ()
main = 
    Generate.fromJson
        I18NextGen.flagsDecoder
        I18NextGen.files
```

Then just run `elm-codegen` with `npx`, supplying the translations file as flags.

`npx elm-codegen run --flags-from="path/to/translations/en.json" --output="path/to/myapp/src`

## Example

You should have a root directory that contains your Elm application. From this directory you've called
`npx elm-codegen init` and have something resembling the following:

```
my-project/
|--elm-app/
|  |--translations.en.json
|  |--src/
|     |--Main.elm
|
|--codegen/
   |--Generate.elm
```

When you have followed the steps in the **Usage** section, running-
```
npx elm-codegen run --flags-from="elm-app/translations.en.json --output="elm-app/src"
```
from the **my-project** root should produce:

```
my-project/
|--elm-app/
|  |--translations.en.json
|  |--src/
|     |--Main.elm
|     |--Language.elm
|     |--Translations.elm
|
|--codegen/
   |--Generate.elm
```

A file translations file such as
```translations.json
{
   "general greeting": "Hello there",
   "personal greeting": "Hello {{name}}"
}
```

will generate

```Translations.elm
generalGreeting : List I18Next.Translations -> String
generalGreeting translations =
    I18Next.tf translations "generalGreeting"


personalGreeting : List I18Next.Translations -> { name : String } -> String
personalGreeting translations replacements =
    I18Next.trf
        translations
        I18Next.Curly
        "personalGreeting"
        [ ( "name", replacements.name ) ]

```

and a default implementation of `I18Next.Translations` in the sibling `Language.elm` module.

```Language.elm
defaultLanguage : I18Next.Translations
defaultLanguage =
    I18Next.fromTree
         [ ( ""
           , I18Next.object
                [ ( "generalGreeting", I18Next.string "Hello there" ) 
                , ( "personalGreeting", I18Next.string "Hello {{name}}" )
                ]
           )
         ]
```

You can also nest translations by page
```
{
   "home": { ... },
   "login": { ... }
}
```

This will create sub-modules in a `Translations` directory.

## Recommended Pattern

It is recommended that you only run this codegen for a single default language. Part of the output
includes a `defaultTranslations` export of the `I18Next.Translations` type. For all your translations
that are not part of your default language, use `I18Next.translationsDecoder` as you normally would.

## Thanks

This library is largely based upon the work done by [Yoni Gibbs](https://github.com/yonigibbs) 
on [elm-i8next-gen](https://github.com/yonigibbs/elm-i18next-gen)
