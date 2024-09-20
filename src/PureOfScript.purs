module PureOfScript where

import Prelude

import Control.Monad.Error.Class (catchError, throwError)
import Data.Array ((!!))
import Data.Array as Array
import Data.Array.NonEmpty as NEA
import Data.DateTime.Instant (Instant, diff)
import Data.Either (Either(..))
import Data.Int as Int
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Tuple (fst)
import Data.Tuple.Nested (type (/\), (/\))
import Effect (Effect)
import Effect.Aff (Aff, Milliseconds(..), launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console as Console
import Effect.Exception (error)
import Effect.Now (now)
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.Path (FilePath)
import Node.Path as Path
import Node.Process as Process
import PureScript.CST (RecoveredParserResult(..), parseModule)
import PureScript.CST.Errors (printParseError)
import PureScript.CST.Lexer (lex, lexModule)
import PureScript.CST.Parser as CST
import PureScript.CST.Parser.Monad (Parser, runParser)
import PureScript.CST.Types (Module)

time :: forall v. String -> Aff v -> Aff v
time name act = do
  t0 <- liftEffect now
  r <- act
  t1 <- liftEffect now
  Console.log $ name <> " took " <> show (Int.round (unwrap (diff t1 t0 :: Milliseconds))) <> "ms"
  pure r

ensure :: forall v. Maybe v -> Aff v
ensure Nothing = throwError $ error "ASDF"
ensure (Just v) = pure v

pick :: forall k v. Eq k => k -> k /\ v -> Maybe v
pick k1 (k2 /\ v) | k1 == k2 = Just v
pick _ _ = Nothing

resolveAgainst :: forall r. Array (String /\ r) -> FilePath -> Aff r
resolveAgainst items path0 = go [] path0
  where
  go acc0 path = do
    let name = Path.basename path
    let acc = Array.snoc acc0 name
    case Array.findMap (pick name) items of
      Just r -> do
        Console.log $ "#!/usr/bin/env " <> name
        pure r
      Nothing ->
        catchError (FS.readlink path <#> Right) (pure <<< Left)
          >>= case _ of
            Left _ ->
              throwError $ error $ show acc <> " not in " <> show (fst <$> items)
            Right path' -> go acc path'

parseFileAs :: forall r. String -> Parser r -> Aff r
parseFileAs path p = time "parsing" do
  contents <- FS.readTextFile UTF8 path
  case runRecoveredParser contents of
    Right r -> pure r
    Left err -> throwError $ error $ renderError err
  where
  runRecoveredParser :: String -> Either _ r
  runRecoveredParser s = case flip runParser p (lexModule s) of
    Right (_ /\ errs) | Just err <- Array.head errs -> Left err
    Right (r /\ _) -> Right r
    Left err -> Left err

  renderError = printParseError <<< _.error

shebang :: Effect Unit
shebang = launchAff_ do
  argv <- liftEffect Process.argv
  -- Console.logShow argv
  root <- ensure $ map (Path.dirname <<< Path.dirname) $ argv !! 1
  shebangName <- ensure $ argv !! 2
  cmd <- resolveAgainst shebangs shebangName
  cmd { root, argv: Array.drop 3 argv }

trying act = catchError (Just <$> act) (const (pure Nothing))

shebangs :: Array (String /\ ({ root :: String, argv :: Array String } -> Aff (Unit)))
shebangs =
  [ "pure-of-script" /\ \{ root, argv } -> do
      let dest = Path.concat [ root, "src/Main.purs" ]
      Console.logShow argv
      script <- ensure $ argv !! 0
      Console.log $ script <> " -> " <> dest
      _ <- parseFileAs script CST.parseModule
      contents <- FS.readTextFile UTF8 script
      existing <- trying do FS.readTextFile UTF8 dest
      case eq contents <$> existing of
        Just true -> do
          Console.log "No update"
          pure unit
        _ -> do
          FS.rm' dest { force: true, maxRetries: 1, recursive: true, retryDelay: 1 }
          FS.copyFile script dest
      pure unit
  ]
