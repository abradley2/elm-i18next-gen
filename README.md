# Elm I18Next Code Generation

An [elm-codegen](https://github.com/mdgriffith/elm-codegen) library for creating type-safe helper methods
for the excellent [ChristophP/elm-i18next](https://package.elm-lang.org/packages/ChristophP/elm-i18next/latest/)
package.

If you have a large Elm application in a business setting, you should strongly consider supporting internationalization
even if you aren't considering adding extra languages to your app. Your project manager who would much rather change a line
in a JSON file than put another 1-point ticket into your sprint will thank you for it.

## Elm Codegen Usage


In your project that consumes the generated code, you should `elm install ChristophP/elm-i18next`. 
This library generates code for usage with `ChristophP/elm-i18next`.

```
npx @abradley2/elm-i18next-gen --output=generated --translations=relative/path/to/translations.json
```

This will create a directory "generated" containing a `Language.elm` file and a `Translations.elm`
file, along with `Translations` sub modules based on the structure of your translations file.

A translations file like should look something like this, 
conforming to the [I18Next V2 specification](https://www.i18next.com/misc/json-format#i18next-json-v2):
```json
{
   "general greeting": "Hello there",
   "personal greeting": "Hello {{name}}"
}
```

This will generate the following:

```elm
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

-and a default implementation of `I18Next.Translations` in the sibling `Language.elm` module.

```elm
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

You can also nest translations by page as the [I18Next V2 specification](https://www.i18next.com/misc/json-format#i18next-json-v2) allows.
```
{
   "home": { ... },
   "login": { ... }
}
```

This will create the sub-modules in the `Translations` directory.

## Recommended Pattern

It is recommended that you only run this codegen for a single default language. Part of the output
includes a `defaultLanguage` export of the `I18Next.Translations` type. For all your translations
that are not part of your default language, use `I18Next.translationsDecoder` as you normally would.

## Thanks

This library is largely based upon the work done by [Yoni Gibbs](https://github.com/yonigibbs) 
on [elm-i8next-gen](https://github.com/yonigibbs/elm-i18next-gen)
