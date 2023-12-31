{-# LANGUAGE OverloadedStrings #-}
module Main where

import qualified Data.Bifunctor as BF
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as CL
import Data.Csv (encodeByName, FromField (..), FromNamedRecord (..), (.:))
import Data.Csv.Incremental (decodeByName, HeaderParser (..), Parser (..))
import qualified Data.List as L
import qualified Data.List.NonEmpty as NE
import Data.Time (Day)
import Data.Foldable (traverse_)
import Data.Maybe (fromMaybe)
import Data.Validation
import qualified Data.Vector as V
import System.IO (hPutStrLn, stderr)
import qualified RawLab as Raw
import qualified Lab as Lab
import System.Exit (exitFailure, exitSuccess)

-- Parses the records, and returns them tupled with their line numbers
-- on success
parseLines :: CL.ByteString -> Validation (NE.NonEmpty String) [(Int, Raw.Lab)]
parseLines ls =
  sequenceA . readCsv decodeByName . CL.toChunks . CL.unlines . fmap clean $ CL.lines ls
          -- Provided input has CRLF terminators, and wraps each whole line in quotes
          -- quotes need to be nixed for the CSV parser to work. CRLF won't play nicely
          -- with `lines` and `unlines`, so get rid of it too.
  where clean = CL.dropWhile (== '"') . CL.dropWhileEnd (\c -> c == '\r' || c == '"')
        readCsv decoder lines@(l:ls) =
          case decoder of
            FailH _ err -> [validationNel $ Left err]
            PartialH continue -> readCsv (continue l) ls
            -- start line count at 2 on account of skipping the header row
            DoneH _ parser -> readRecord lines 2 [] parser
        readCsv _ [] = undefined
        -- Format error message with line number.
        formatError lineNum err =
          "Format error on line " ++ show lineNum ++ ": " ++ err
        -- Format any existing error messages and increment the tracked line number
        -- for each record - regardless of success or failure.
        incrementAndFormat lineNum record =
          let formatted = validationNel . BF.first (formatError lineNum) $ record
              tupled = BF.second (lineNum,) formatted
           in (lineNum + 1, tupled)
        countAndFormat = L.mapAccumL incrementAndFormat
        readRecord _ lineNum records (Fail _ err) = malformed:records
          where malformed = validationNel . Left . formatError lineNum $ err
        readRecord chunks lineNum records (Many parsed continue) =
          let (nextLineNum, nextRecords) = countAndFormat lineNum parsed
           in case chunks of
                c:cs -> readRecord cs nextLineNum (nextRecords ++ records) $ continue c
                [] -> nextRecords ++ records
        readRecord [] lineNum records (Done parsed) =
          let (_, nextRecords) = countAndFormat lineNum parsed
           in nextRecords ++ records

main :: IO ()
main = do
  csvData <- BL.getContents -- read from stdin
  let parsed = parseLines csvData
  let transformed = 
        case parsed of
          Success(records) -> traverse Lab.fromRaw records
          Failure(errors) -> Failure(errors)
  let deduped = fmap L.nub transformed
  exitCode <-
    case deduped of
      Failure(errors) -> traverse_ (hPutStrLn stderr) errors >> exitFailure
      Success(records) -> 
        CL.putStr $ encodeByName Lab.labHeader records
  return exitCode
