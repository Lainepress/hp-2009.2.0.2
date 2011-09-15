-----------------------------------------------------------------------------
-- |
-- Module      :  Network.HTTP.Utils
-- Copyright   :  (c) Warrick Gray 2002, Bjorn Bringert 2003-2004, Simon Foster 2004, 2007 Robin Bate Boerop, 2008- Sigbjorn Finne
-- License     :  BSD
--
-- Maintainer  :  Sigbjorn Finne <sigbjorn.finne@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable (not tested)
--
-- Set of utility functions and definitions used by package modules.
--
module Network.HTTP.Utils
       ( trim     -- :: String -> String
       , trimL    -- :: String -> String
       , trimR    -- :: String -> String
       
       , crlf     -- :: String
       , sp       -- :: String

       , split    -- :: Eq a => a -> [a] -> Maybe ([a],[a])
       , splitBy  -- :: Eq a => a -> [a] -> [[a]]
       
       , readsOne -- :: Read a => (a -> b) -> b -> String -> b
       
       ) where
       
import Data.Char
import Data.List ( elemIndex )
import Data.Maybe ( fromMaybe )

-- | @crlf@ is our beloved two-char line terminator.
crlf :: String
crlf = "\r\n"

-- | @sp@ lets you save typing one character.
sp :: String
sp   = " "

-- | @split delim ls@ splits a list into two parts, the @delim@ occurring
-- at the head of the second list.  If @delim@ isn't in @ls@, @Nothing@ is
-- returned.
split :: Eq a => a -> [a] -> Maybe ([a],[a])
split delim list = case delim `elemIndex` list of
    Nothing -> Nothing
    Just x  -> Just $ splitAt x list

-- | @trim str@ removes leading and trailing whitespace from @str@.
trim :: String -> String
trim xs = trimR (trimL xs)
   
-- | @trimL str@ removes leading whitespace (as defined by 'Data.Char.isSpace')
-- from @str@.
trimL :: String -> String
trimL xs = dropWhile isSpace xs

-- | @trimL str@ removes trailing whitespace (as defined by 'Data.Char.isSpace')
-- from @str@.
trimR :: String -> String
trimR str = fromMaybe "" $ foldr trimIt Nothing str
 where
  trimIt x (Just xs) = Just (x:xs)
  trimIt x Nothing   
   | isSpace x = Nothing
   | otherwise = Just [x]

-- | @splitMany delim ls@ removes the delimiter @delim@ from @ls@.
splitBy :: Eq a => a -> [a] -> [[a]]
splitBy _ [] = []
splitBy c xs = 
    case break (==c) xs of
      (_,[]) -> [xs]
      (as,_:bs) -> as : splitBy c bs

-- | @readsOne f def str@ tries to 'read' @str@, taking
-- the first result and passing it to @f@. If the 'read'
-- doesn't succeed, return @def@.
readsOne :: Read a => (a -> b) -> b -> String -> b
readsOne f n str = 
 case reads str of
   ((v,_):_) -> f v
   _ -> n

