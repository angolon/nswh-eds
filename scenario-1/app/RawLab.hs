{-# LANGUAGE OverloadedStrings #-}
module RawLab where

import Data.Time (Day)
import Data.Csv (FromField (..), FromNamedRecord (..), (.:))
import qualified Data.Time.Format as FT
import qualified Data.ByteString.Char8 as C

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
  , countryOfBirth :: !String
  , dateOfArrival :: !String
  , countryOfDeparture :: !String
  , ctValues :: !String
  , covid19 :: !String
  , rsv :: !String
  , influenzaAB :: !String
  } deriving (Show, Eq)

instance FromField Day where
  parseField = (FT.parseTimeM True FT.defaultTimeLocale "%-d/%-m/%Y") . C.unpack

instance FromNamedRecord Lab where
  parseNamedRecord r =
    Lab
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
