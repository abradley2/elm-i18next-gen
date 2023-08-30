const CodeGen = require('elm-codegen')
const path = require('path')
const fs = require('fs')
const minimist = require('minimist')

const args = minimist(process.argv.slice(2))

if (!args.output) {
    console.error("Missing output path, specify with --output")
    process.exit(1)
}

if (!args.translations) {
    console.error("Missing translations path, specify with --translations")
    process.exit(1)
}

const cwd = process.cwd()

let flagsJson 

try {
    const rawJson = fs.readFileSync(path.join(cwd, args.translations), 'utf8')
    flagsJson = JSON.parse(rawJson)
} catch (err) {
    console.error(`Error reading translations file, make sure it is a valid path to a valid json file: ${err}`)
    process.exit(1)
}

CodeGen.run("Generate.elm", {
  debug: !!args.debug,
  output: path.join(cwd, args.output),
  flags: flagsJson,
  cwd: path.join(__dirname, "./codegen"),
})