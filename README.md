# `pure-of-script`

A shebang runner for PureScript programs, only for the pure of heart 🏳️‍⚧️💜🏳️‍🌈

Will be able to: Parse the scripts to add niceties like automatic qualified imports, and cache the compiled programs so re-evaluation is faster.

¡WIP / DRAFT!

## Requirements

- `make`
- `bash`
- `node`
- `purs`
- `spago` (new spago)
- `esbuild` (??)
- `watchexec` (optional?)
- `trypurescript` (optional)

## Installation, configuration, and customization

- Add `pure-of-script/bin` to `$PATH`, or symlink the programs you want from it into a folder that is in your `$PATH`.

TODO: deps and npm env and .envrc and whatnot and maybe nix env or just direnv but i don't use direnv

## Usage

```purescript
#!/usr/bin/env pure-of-script
module Main where

import Prelude
import Effect
import Effect.Console
import Node.Process as Process

main :: Effect Unit
main = do
  log "Hi it worked!!!!"
  logShow =<< Process.argv
```

## Layout

- `bin/`: the main output of this project, a set of scripts that you can use as shebangs in your custom files
- `scripts/`: the main scripts that get stuff done
- `src/`: the PureScript source
- `stage/`: the default stage, where your user scripts are compiled
  - `timings/`: files recording the timestamp of each stage of compilation
    - `timings/fmt.txt`: the format string used for these files (the test is not important – the fileʼs `mtime` is used for actual timing information)
  - `running/`: where daemons are run
    - `trypurescript/`
      - `pid.txt`
      - `port.txt`
      - `stdin`
      - `stdout` (includes stderr)
- `test/`: ?
- `Makefile`: the Makefile that ensures that everything is up-to-date
- `spago.yaml`: the dependencies for the project itself
- `watch.txt`: for use with `watchexec`

## Development

```sh
# From the root of this git repo
watchexec -w . --filter-file watch.txt --shell none -- ./example.purescript 1 3 "4 5"
```
