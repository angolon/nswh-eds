{-# LANGUAGE OverloadedStrings #-}
module Main where

import qualified Data.Bifunctor as BF
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as CL
import Data.Csv (FromField (..), FromNamedRecord (..), (.:))
import Data.Csv.Incremental (decodeByName, HeaderParser (..), Parser (..))
import qualified Data.List as L
import qualified Data.List.NonEmpty as NE
import Data.Time (Day)
import Data.Foldable (traverse_)
import qualified Data.Time.Format as FT
import Data.Maybe (fromMaybe)
import Data.Validation
import qualified Data.Vector as V
import System.IO (hPutStrLn, stderr)

data RawLab = RawLab
  { caseNum :: !String
  , first :: !String
  , surname :: !String
  , dob :: !Day
  , gender :: !String
  , mobile :: !String
  , street :: !String
  , suburb :: !String
  , postcode :: !String
  , state :: !String
  , collectionDate :: !Day
  , testDate :: !Day
  , testType :: !String
  , specimenType :: !String
  , countryOfBirth :: !String
  , dateOfArrival :: !String
  , countryOfDeparture :: !String
  , ctValues :: !String
  , covid19 :: !String
  , rsv :: !String
  , influenzaAB :: !String
  } deriving (Show, Eq)

instance FromNamedRecord RawLab where
  parseNamedRecord r =
    RawLab
      <$> r .: "Case #"
      <*> r .: "First"
      <*> r .: "Surname"
      <*> r .: "DOB"
      <*> r .: "Gender"
      <*> r .: "Mobile"
      <*> r .: "Street"
      <*> r .: "Suburb"
      <*> r .: "Postcode"
      <*> r .: "State"
      <*> r .: "Collection date"
      <*> r .: "Test date"
      <*> r .: "Test type"
      <*> r .: "Specimen type"
      <*> r .: "Country_of_Birth"
      <*> r .: "Date_Of_Arrival"
      <*> r .: "CountryOfDeparture"
      <*> r .: "Ct Values"
      <*> r .: "Covid-19"
      <*> r .: "RSV"
      <*> r .: "Influenza A/B"


instance FromField Day where
  parseField = (FT.parseTimeM True FT.defaultTimeLocale "%-d/%-m/%Y") . C.unpack

parseLines :: CL.ByteString -> Validation (NE.NonEmpty String) [RawLab]
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
           in (lineNum + 1, formatted)
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

-- parseDate :: Field -> Maybe T.Day
-- parseDate = (FT.parseTimeM True FT.defaultTimeLocale "%-d/%-m/%Y") . CL.unpack

main :: IO Int
main = do
  csvData <- BL.getContents -- read from stdin
  let parsed = parseLines csvData
  exitCode <-
    case parsed of
      Failure(errors) -> traverse_ (hPutStrLn stderr) errors >> pure 1
      Success(records) -> traverse_ (putStrLn . show) records >> pure 0
  return exitCode
