import I18Next.Gen
import Gen.CodeGen.Generate as Generate
import Json.Decode exposing (Value)

main : Platform Value () ()
main = 
    Generate.fromJson
        I18NextGen.flagsDecoder
        I18NextGen.files