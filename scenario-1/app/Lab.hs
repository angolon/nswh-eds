{-# LANGUAGE OverloadedStrings #-}
module Lab where

import Data.Validation
import qualified Data.Bifunctor as BF
import qualified Data.List.NonEmpty as NE
import Data.Time (Day)
import Data.Csv (FromField (..), FromNamedRecord (..), (.:))
import qualified Data.Time.Format as FT
import qualified Data.ByteString.Char8 as C
import qualified RawLab as Raw
import Text.Parsec
import Text.Parsec.Char
import Text.Read (readEither)

data CtParseState = CtParseState
  { hasReadCovid :: Bool
  , hasReadRSV :: Bool
  , hasReadFlu :: Bool
  , covidVal :: Maybe Int
  , rsvVal :: Maybe Int
  , fluVal :: Maybe Int
  } 

type CtValuesParser = Parsec String CtParseState

parseNumber :: CtValuesParser (Maybe Int)
parseNumber =
  fmap (\_ -> Nothing) (string "N/A")
  <|> (fmap (Just . (read @Int)) $ (many1 digit))

parseCovid :: CtValuesParser ()
parseCovid =
  do
    n <- string "COVID-19:" *> skipMany space *> parseNumber
    st <- getState
    let hasRead = hasReadCovid st
    if hasRead then
      fail "duplicate COVID-19 values"
    else 
      putState $ st { hasReadCovid = True, covidVal = n }

parseRSV :: CtValuesParser ()
parseRSV =
  do
    n <- string "RSV:" *> skipMany space *> parseNumber
    st <- getState
    let hasRead = hasReadRSV st
    if hasRead then
      fail "duplicate RSV values"
    else 
      putState $ st { hasReadRSV = True, rsvVal = n }

parseFlu :: CtValuesParser ()
parseFlu =
  do
    n <- string "Flu A:" *> skipMany space *> parseNumber
    st <- getState
    let hasRead = hasReadFlu st
    if hasRead then
      fail "duplicate Flu values"
    else 
      putState $ st { hasReadFlu = True, fluVal = n }

parseCtValues :: CtValuesParser CtParseState
parseCtValues = (parseElem `sepBy` parseDelim) *> eof *> getState
  where parseElem = parseCovid <|> parseRSV <|> parseFlu
        parseDelim = char ';' *> skipMany space

data Lab = Lab
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
  , covid19 :: Maybe Int
  , rsv :: Maybe Int
  , influenzaAB :: Maybe Int
  } deriving (Show, Eq, Ord)

fromRaw :: Raw.Lab -> Validation (NE.NonEmpty String) Lab
fromRaw raw =
  let initialState = CtParseState False False False Nothing Nothing Nothing
      parsedState = runParser parseCtValues initialState "ctValues field" $ Raw.ctValues raw
      validatedState = validationNel $ BF.first show parsedState
      toLab state = Lab {
        caseNum = Raw.caseNum raw,
        first = Raw.first raw,
        surname = Raw.surname raw,
        dob = Raw.dob raw,
        gender = Raw.gender raw,
        mobile = Raw.mobile raw,
        street = Raw.street raw,
        suburb = Raw.suburb raw,
        postcode = Raw.postcode raw,
        state = Raw.state raw,
        collectionDate = Raw.collectionDate raw,
        testDate = Raw.testDate raw,
        testType = Raw.testType raw,
        specimenType = Raw.specimenType raw,
        covid19 = covidVal state,
        rsv = rsvVal state,
        influenzaAB = fluVal state
      }
   in fmap toLab validatedState
