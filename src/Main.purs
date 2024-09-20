#!/usr/bin/env pure-of-script
module Main where

import Prelude
import Effect
import Effect.Console
import Node.Process as Process

main :: Effect Unit
main = do
  log $ "Hi it worked!!!!"
  logShow =<< Process.argv
