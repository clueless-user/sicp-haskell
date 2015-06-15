module Haffman where
import qualified Data.Map as M
import Control.Applicative
import Control.Monad
import Control.Monad.ST
import Data.STRef
-- $setup
-- >>> import Data.List

frequencies :: Ord a => [a] -> M.Map a Int
frequencies xs = runST $ do
    m <- newSTRef M.empty
    forM_ xs $ \c -> do
        val <- M.lookup c <$> readSTRef m
        case val of
            (Just _) -> modifySTRef' m (M.adjust succ c)
            Nothing -> modifySTRef' m (M.insert c 1)
    readSTRef m

-- |
-- prop> (M.toAscList . frequencies) xs == (map (liftM2 (,) head length) . group . sort) (xs :: [Char])

data HTree a = Leaf { _symbol :: a, _weight :: Int}
             | Tree {
                    _left :: HTree a, _right :: HTree a,
                    _symbols :: [a], _weight :: Int
             } deriving (Show)

symbols :: HTree a -> [a]
symbols (Leaf f _) = return f
symbols (Tree _ _ s _) = s

mkTree :: HTree a -> HTree a -> HTree a
mkTree t0 t1 = Tree t0 t1 sys wei where
    sys = symbols t0 ++ symbols t1
    wei = _weight t0 + _weight t1

--
type Bit = Int
decode :: [Bit] -> HTree a -> [a]
decode [] _ = []
decode bits tree =
    let
        decode1 [] _ = []
        decode1 (b:bs) cBranch =
            case chooseBranch b tree of
                (Leaf symb _) ->  symb:decode1 bs tree
                t@(Tree {}) ->  decode1 bs t
    in
        decode1 bits tree


chooseBranch :: Bit -> HTree a -> HTree a
chooseBranch 0 = _left
chooseBranch 1 = _right
chooseBranch _ = error "invalid bit"
