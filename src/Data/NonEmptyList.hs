{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, PatternGuards #-}

module Data.NonEmptyList where

import Control.Monad (liftM2)
import Control.Arrow (first)
import qualified Prelude
import Prelude hiding (mapM, concatMap)

data NeList a = NeList a [a] deriving (Eq, Show)

head :: NeList a -> a
head (NeList x _) = x

tail :: NeList a -> [a]
tail (NeList _ x) = x

-- head and tail are separate functions rather than record fields so that users may say "import NonEmptyList (NeList(..))" to only get the type and constructor.

instance Functor NeList where fmap f (NeList x l) = NeList (f x) (map f l)

cons :: a -> NeList a -> NeList a
cons h = NeList h . to_plain

one :: a -> NeList a
one x = NeList x []

to_plain :: NeList a -> [a]
to_plain (NeList x l) = x : l

from_plain :: [a] -> Maybe (NeList a)
from_plain [] = Nothing
from_plain (h:t) = Just $ NeList h t

mapM :: Monad m => (a -> m b) -> NeList a -> m (NeList b)
mapM f (NeList x l) = liftM2 NeList (f x) (Prelude.mapM f l)

concat :: NeList (NeList a) -> NeList a
concat (NeList (NeList x y) z) = NeList x $ y ++ Prelude.concatMap to_plain z

nth :: Int -> NeList a -> Maybe a
nth n l | (- length l') <= n, n < length l' = return $ l' !! (n `mod` length l') where l' = to_plain l
nth _ _ = Nothing

reverse :: NeList a -> NeList a
reverse = work []
  where
    work l (NeList a []) = NeList a l
    work l (NeList a (h:t)) = work (a : l) (NeList h t)

app_plain_left :: [a] -> NeList a -> NeList a
app_plain_left [] l = l
app_plain_left (h:t) (NeList h' t') = NeList h (t ++ h' : t')

init_last :: NeList a -> ([a], a)
init_last (NeList x []) = ([], x)
init_last (NeList x (h:t)) = first (x:) $ init_last $ NeList h t

concatMap :: (a -> NeList a) -> NeList a -> NeList a
concatMap f (NeList x y) = NeList a $ b ++ Prelude.concatMap (to_plain . f) y
  where (NeList a b) = f x
