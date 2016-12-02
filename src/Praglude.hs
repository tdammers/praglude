{-#LANGUAGE TypeSynonymInstances #-}
{-#LANGUAGE FlexibleInstances #-}
{-#LANGUAGE MultiParamTypeClasses #-}
{-#LANGUAGE DeriveGeneric #-}
{-#LANGUAGE DeriveFunctor #-}
{-#LANGUAGE DeriveTraversable #-}
{-#LANGUAGE AutoDeriveTypeable #-}
{-#LANGUAGE GeneralizedNewtypeDeriving #-}
{-#LANGUAGE FunctionalDependencies #-}
module Praglude
(
-- * The Original Prelude
  module Prelude

-- * Monoids
, module Data.Monoid
, concat
, append
, empty

-- * Maybe
, module Data.Maybe

-- * Monads
, module Control.Monad

-- * Arrows
, module Control.Arrow

-- * Mutable Variables In IO
, module Data.IORef
, module Control.Concurrent.MVar
, module Control.Concurrent.Chan

-- * Default
, module Data.Default

-- * Lens
, module Control.Lens

-- * State monads
, module Control.Monad.State

-- * Painless String Types
, s
, ToString (..)
, FromString
, IsString (..)

, Text
, LText
, ByteString
, LByteString

-- * Generalized String Operations

, trim
, ltrim
, rtrim
, words
, lines

, module Data.Char

-- * String Case Conversions
, kebab, snake, pascal

-- * I/O
, stderr
, stdout
, stdin
, Handle

-- * Environment
, module System.Environment

-- * Generalized I/O
, StringIO (..)

-- * Printf
, module Text.Printf

-- * Filename And File System Manipulation
, module System.FilePath
, module System.Directory

-- * Type Forcers
--
-- Useful for disambiguation
, asString
, asText
, asLText
, asByteString
, asLByteString
, asHashMap

-- * Container Types With Unified Interfaces

, module Data.Foldable

, AList (..)
, HashMap
, LHashMap
, HashSet
, Map
, Set
, Vector

, Hashable (..)
, Lookup (..)
, ListLike (..)
, DictLike (..)
, SetLike (..)
, Filterable (..)
, cull
, startsWith

-- * JSON
, ToJSON (..)
, FromJSON (..)
, Value
, object
, prettyJsonOptions
, derivePrettyJSON
, deriveJSON

, encodeJSON
, decodeJSON
, encodeJSONStrict
, decodeJSONStrict
, (~>)

-- * Base-64
, encodeBase64
, decodeBase64

-- * Concurrency And Exception Handling
, threadDelay
, forkIO
, bracket
, bracket_
, throw
, catch
, catches

-- * Generics
, Generic

-- * Functions
, chain
, module Data.Function

-- * Date and Time
, Day (..)
, TimeOfDay (..)
, UTCTime (..)
, LocalTime (..)
, TimeZone (..)
, ZonedTime (..)
, TimeLocale (..)
, DiffTime (..)
, NominalDiffTime (..)
, secondsToDiffTime
, picosecondsToDiffTime
, addUTCTime
, diffUTCTime
, getCurrentTime

, defaultTimeLocale

, toGregorian
, fromGregorian

, formatTime
)
where

import Prelude hiding ( putStr
                      , putStrLn
                      , readFile
                      , writeFile
                      , lookup
                      , getContents
                      , null
                      , elem
                      , concat
                      , filter
                      , take
                      , drop
                      , lines
                      , words
                      , length
                      )
import qualified Prelude
import System.FilePath hiding ( (<.>), isValid )
import System.Directory
import qualified System.IO as IO
import System.IO (stderr, stdout, stdin, Handle)
import Data.Maybe
import Control.Monad
import Text.Printf
import Data.Monoid
import Data.Char
import Control.Arrow (left, right, (+++), (|||))
import Data.Foldable hiding (null, elem, concat, length)
import System.Environment
import Control.Concurrent.MVar
import Control.Concurrent.Chan
import Data.IORef
import Control.Monad.State

import Text.Casing
import qualified Data.Text as Text
import qualified Data.Text.IO as Text
import qualified Data.Text.Lazy
import qualified Data.Text.Lazy as LText
import qualified Data.Text.Lazy.IO as LText
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import qualified Data.HashMap.Strict as HashMap
import qualified Data.HashMap.Lazy as LHashMap
import qualified Data.HashSet as HashSet
import qualified Data.ByteString.Base64 as Base64
import qualified Data.Vector as Vector
import Data.Vector (Vector)
import qualified Data.Set as Set
import Data.Set (Set)
import qualified Data.Map as Map
import Data.Map (Map)
import Data.Hashable (Hashable (..))
import Text.StringConvert
import Data.Typeable
import GHC.Generics
import GHC.Exts
import Data.Data
import Data.Semigroup
import Control.DeepSeq
import qualified Data.List as List
import Control.Lens
import Control.Lens.TH (makeLenses)
import Data.Aeson (ToJSON (..), FromJSON (..), Value, object)
import Data.Aeson.TH (deriveJSON)
import qualified Data.Aeson as JSON
import qualified Data.Aeson.TH as JSON
import Data.Default
import Data.List (foldl')
import Control.Concurrent
import Control.Exception
import Data.Function

import Data.Time

import Language.Haskell.TH.Syntax (Name, Q, Dec)

type Text = Text.Text
type LText = LText.Text
type ByteString = BS.ByteString
type LByteString = LBS.ByteString

empty :: Monoid a => a
empty = mempty

append :: Monoid a => a -> a -> a
append = mappend

concat :: Monoid a => [a] -> a
concat = mconcat

lines :: (FromString a, ToString a) => a -> [a]
lines = map s . Prelude.lines . s

words :: (FromString a, ToString a) => a -> [a]
words = map s . Prelude.words . s

trim :: (FromString a, ToString a) => a -> a
trim = ltrim . rtrim

ltrim :: (FromString a, ToString a) => a -> a
ltrim = s . dropWhile isSpace . s

rtrim :: (FromString a, ToString a) => a -> a
rtrim = s . List.dropWhileEnd isSpace . s

{-#RULES "Text.trim" trim = Text.strip #-}
{-#RULES "LText.trim" trim = Data.Text.Lazy.strip #-}
{-#RULES "Text.ltrim" trim = Text.dropWhile isSpace #-}
{-#RULES "Text.rtrim" trim = Text.dropWhileEnd isSpace #-}
{-#RULES "LText.ltrim" trim = Data.Text.Lazy.dropWhile isSpace #-}
{-#RULES "LText.rtrim" trim = Data.Text.Lazy.dropWhileEnd isSpace #-}

type HashMap = HashMap.HashMap

-- | A lazy hash map. Because 'LHashMap.HashMap' is actually the exact
-- same type as 'HashMap.HashMap', we wrap it in a newtype so that
-- we can tie laziness into the type itself (similar to how it works
-- for 'Text' and 'ByteString').
newtype LHashMap k v = LHashMap { unLHashMap :: LHashMap.HashMap k v }
    deriving (Read, Show, Typeable, Generic, Functor, Foldable, Traversable, Eq, Data, Semigroup, Monoid, NFData, Hashable)

type HashSet = HashSet.HashSet

-- | Types that can be written to / read from file descriptors.
class StringIO a where
    putStr :: a -> IO ()
    putStrLn :: a -> IO ()
    hPutStr :: Handle -> a -> IO ()
    hPutStrLn :: Handle -> a -> IO ()
    readFile :: FilePath -> IO a
    writeFile :: FilePath -> a -> IO ()
    getContents :: IO a
    hGetContents :: Handle -> IO a
    putStrLn str = putStr str >> putStr "\n"
    hPutStrLn h str = hPutStr h str >> hPutStr h "\n"

instance StringIO String where
    putStr = IO.putStr
    putStrLn = IO.putStrLn
    hPutStr = IO.hPutStr
    hPutStrLn = IO.hPutStrLn
    readFile = IO.readFile
    writeFile = IO.writeFile
    getContents = IO.getContents
    hGetContents = IO.hGetContents

instance StringIO Text where
    putStr = Text.putStr
    putStrLn = Text.putStrLn
    hPutStr = Text.hPutStr
    hPutStrLn = Text.hPutStrLn
    readFile = Text.readFile
    writeFile = Text.writeFile
    getContents = Text.getContents
    hGetContents = Text.hGetContents

instance StringIO LText where
    putStr = LText.putStr
    putStrLn = LText.putStrLn
    hPutStr = LText.hPutStr
    hPutStrLn = LText.hPutStrLn
    readFile = LText.readFile
    writeFile = LText.writeFile
    getContents = LText.getContents
    hGetContents = LText.hGetContents

instance StringIO ByteString where
    putStr = BS.putStr
    hPutStr = BS.hPutStr
    readFile = BS.readFile
    writeFile = BS.writeFile
    getContents = BS.getContents
    hGetContents = BS.hGetContents

instance StringIO LByteString where
    putStr = LBS.putStr
    hPutStr = LBS.hPutStr
    readFile = LBS.readFile
    writeFile = LBS.writeFile
    getContents = LBS.getContents
    hGetContents = LBS.hGetContents

-- | Things that support keyed element lookup.
class Lookup m k | m -> k where
    lookup :: k -> m v -> Maybe v
    lookupDef :: v -> k -> m v -> v
    lookupDef d k = fromMaybe d . lookup k

newtype AList k v = AList { unAList :: [(k, v)] }
    deriving (Show, Read, Eq, Ord, Generic, Functor)

instance Eq k => Lookup (AList k) k where
    lookup k = Prelude.lookup k . unAList

class ListLike m a | m -> a where
    intersperse :: a -> m -> m
    take :: Int -> m -> m
    takeEnd :: Int -> m -> m
    drop :: Int -> m -> m
    dropEnd :: Int -> m -> m
    slice :: Int -> Int -> m -> m
    slice offset len = take len . drop offset
    length :: m -> Int
    takeEnd n x = drop (length x - n) x
    dropEnd n x = take (length x - n) x

instance ListLike [a] a where
    intersperse = List.intersperse
    take = List.take
    drop = List.drop
    length = List.length

instance ListLike (Vector a) a where
    intersperse e = Vector.fromList . List.intersperse e . Vector.toList
    take = Vector.take
    drop = Vector.drop
    slice = Vector.slice
    length = Vector.length

instance ListLike Text Char where
    intersperse = Text.intersperse
    take = Text.take . fromIntegral
    drop = Text.drop . fromIntegral
    length = fromIntegral . Text.length

instance ListLike LText Char where
    intersperse = LText.intersperse
    take = LText.take . fromIntegral
    drop = LText.drop . fromIntegral
    length = fromIntegral . LText.length

startsWith :: (Eq a, ListLike a e) => a -> a -> Bool
startsWith haystack needle =
    take (length needle) haystack == needle

endsWith :: (Eq a, ListLike a e) => a -> a -> Bool
endsWith haystack needle =
    takeEnd (length needle) haystack == needle

-- | Things that behave like sets.
class SetLike m v | m -> v where
    -- | Conjoin: add an element to a set. For ordered sets, the
    -- end at which the new element is inserted is unspecified.
    conj :: v -> m -> m

    -- | Remove all occurrences of the element from the set.
    remove :: v -> m -> m

    -- | Test if the element is in the set.
    elem :: v -> m -> Bool

    -- | Test if the set is empty.
    null :: m -> Bool

    -- | Convert the set to a list of elements. The ordering is unspecified.
    items :: m -> [v]

    -- | Create a set from a list of elements. Duplicate list elements
    -- may be skipped at the implementation's discretion.
    fromItems :: [v] -> m

    -- | Create a singleton (one-element) set.
    singleton :: v -> m

    -- | Get the number of elements in the set.
    size :: m -> Int

    size = List.length . items
    null = List.null . items

-- | Things that can be filtered
class Filterable m where
    -- | Filter the set to retain only the elements that match the predicate.
    filter :: (v -> Bool) -> m v -> m v

cull :: Filterable m => (v -> Bool) -> m v -> m v
cull = filter . (not .)

-- | Things that behave like key-value dictionaries.
class DictLike m k where
    -- | Add or overwrite an element at a key.
    insert :: k -> v -> m k v -> m k v
    -- | Delete by key
    delete :: k -> m k v -> m k v
    -- | Modify an element at a key
    update :: k -> (v -> Maybe v) -> m k v -> m k v
    -- | Convert to an association list (list of key/value pairs)
    pairs :: m k v -> [(k, v)]
    -- | Convert from an association list (list of key/value pairs)
    fromPairs :: [(k, v)] -> m k v
    -- | Get the keys, discard the values
    keys :: m k v -> [k]
    -- | Get the values, discard the keys
    elems :: m k v -> [v]
    -- | Create a singleton dictionary (just one key-value pair)
    singletonMap :: k -> v -> m k v
    -- | Test whether the dictionary contains a given key
    member :: k -> m k v -> Bool

    keys = map fst . pairs
    elems = map snd . pairs

instance Eq k => DictLike AList k where
    insert k v (AList xs) = AList $ (k,v):xs
    delete k (AList xs) = AList $ filter ((/= k) . fst) xs
    update k f (AList xs) = AList [ (k, fromMaybe v $ f v) | (k, v) <- xs ]
    pairs = unAList
    fromPairs = AList
    singletonMap k v = AList [(k, v)]
    member k = not . null . filter (== k) . keys

instance Lookup [] Int where
    lookup i xs = case drop i xs of
        [] -> Nothing
        (x:_) -> Just x

instance Lookup Vector Int where
    lookup = flip (Vector.!?)

instance (Eq a) => SetLike (Vector a) a where
    conj = Vector.cons
    remove x = Vector.filter (/= x)
    elem = Vector.elem
    null = Vector.null
    items = Vector.toList
    fromItems = Vector.fromList
    singleton = Vector.singleton
    size = Vector.length

instance Filterable Vector where
    filter = Vector.filter

instance (Eq a) => SetLike [a] a where
    conj = (:)
    remove x = filter (/= x)
    elem = List.elem
    null = List.null
    items = id
    fromItems = id
    singleton = (:[])
    size = List.length

instance Filterable [] where
    filter = List.filter

instance (Eq v, Hashable v) => SetLike (HashSet v) v where
    conj = HashSet.insert
    remove = HashSet.delete
    elem = HashSet.member
    null = HashSet.null
    items = HashSet.toList
    fromItems = HashSet.fromList
    singleton = HashSet.singleton
    size = HashSet.size

instance Filterable HashSet where
    filter = HashSet.filter

instance (Eq v, Ord v) => SetLike (Set v) v where
    conj = Set.insert
    remove = Set.delete
    elem = Set.member
    null = Set.null
    items = Set.toList
    fromItems = Set.fromList
    singleton = Set.singleton
    size = Set.size

instance Filterable Set where
    filter = Set.filter

instance (Eq k, Hashable k) => Lookup (HashMap.HashMap k) k where
    lookup = HashMap.lookup

instance (Eq k, Hashable k) => DictLike HashMap.HashMap k where
    insert = HashMap.insert
    delete = HashMap.delete
    update = flip HashMap.update
    pairs = HashMap.toList
    fromPairs = HashMap.fromList
    keys = HashMap.keys
    elems = HashMap.elems
    singletonMap = HashMap.singleton
    member = HashMap.member

instance (Eq k, Hashable k) => SetLike (HashMap k v) (k, v) where
    conj = uncurry insert
    remove = delete . fst
    elem = member . fst
    null = HashMap.null
    items = pairs
    fromItems = fromPairs
    singleton = uncurry singletonMap

instance Filterable (HashMap k) where
    filter = HashMap.filter

instance (Eq k, Ord k) => Lookup (Map.Map k) k where
    lookup = Map.lookup

instance (Eq k, Ord k) => DictLike Map.Map k where
    insert = Map.insert
    delete = Map.delete
    update = flip Map.update
    pairs = Map.toList
    fromPairs = Map.fromList
    keys = Map.keys
    elems = Map.elems
    singletonMap = Map.singleton
    member = Map.member

instance (Eq k, Ord k) => SetLike (Map k v) (k, v) where
    conj = uncurry insert
    remove = delete . fst
    elem = member . fst
    null = Map.null
    items = pairs
    fromItems = fromPairs
    singleton = uncurry singletonMap

instance Filterable (Map k) where
    filter = Map.filter

overLHashMap :: (HashMap k v -> HashMap k v) -> LHashMap k v -> LHashMap k v
overLHashMap f = LHashMap . f . unLHashMap

instance (Eq k, Hashable k) => DictLike LHashMap k where
    insert k v = overLHashMap $ LHashMap.insert k v
    delete k = overLHashMap $ LHashMap.delete k
    update k f = overLHashMap $ LHashMap.update f k
    pairs = LHashMap.toList . unLHashMap
    fromPairs = LHashMap . LHashMap.fromList
    keys = LHashMap.keys . unLHashMap
    elems = LHashMap.elems . unLHashMap
    singletonMap k v = LHashMap (LHashMap.singleton k v)
    member k = LHashMap.member k . unLHashMap

instance (Eq k, Hashable k) => Lookup (LHashMap k) k where
    lookup k = LHashMap.lookup k . unLHashMap

instance (Eq k, Hashable k) => SetLike (LHashMap k v) (k, v) where
    conj = uncurry insert
    remove = delete . fst
    elem = member . fst
    null = LHashMap.null . unLHashMap
    items = pairs
    fromItems = fromPairs
    singleton = uncurry singletonMap

instance Filterable (LHashMap k) where
    filter p = overLHashMap $ LHashMap.filter p

prettyJsonOptions :: JSON.Options
prettyJsonOptions =
    JSON.defaultOptions
        { JSON.fieldLabelModifier = kebab . dropWhile (== '_')
        , JSON.constructorTagModifier = kebab
        , JSON.omitNothingFields = True
        , JSON.sumEncoding = JSON.defaultTaggedObject
                            { JSON.tagFieldName = "what"
                            , JSON.contentsFieldName = "value"
                            }
        }

derivePrettyJSON :: Name -> Q [Dec]
derivePrettyJSON = deriveJSON prettyJsonOptions

asString :: String ->  String
asString = id

asText :: Text ->  Text
asText = id

asLText :: LText ->  LText
asLText = id

asByteString :: ByteString ->  ByteString
asByteString = id

asLByteString :: LByteString ->  LByteString
asLByteString = id

asHashMap :: HashMap k v -> HashMap k v
asHashMap = id

encodeJSON :: ToJSON a => a -> LByteString
encodeJSON = JSON.encode

decodeJSON :: FromJSON a => LByteString -> Maybe a
decodeJSON = JSON.decode

encodeJSONStrict :: ToJSON a => a -> ByteString
encodeJSONStrict = s . JSON.encode

decodeJSONStrict :: FromJSON a => ByteString -> Maybe a
decodeJSONStrict = JSON.decodeStrict

chain :: Traversable t => t (a -> a) -> a -> a
chain = foldl' (.) id

(~>) :: ToJSON a => Text -> a -> (Text, Value)
(~>) = (JSON..=)

decodeBase64 :: ByteString -> ByteString
decodeBase64 = Base64.decodeLenient

encodeBase64 :: ByteString -> ByteString
encodeBase64 = Base64.encode
