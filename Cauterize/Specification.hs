module Cauterize.Specification
  ( module Cauterize.Specification.Types
  , fromSchema
  ) where

import Cauterize.Specification.Types
import Cauterize.FormHash
import Cauterize.Common.BuiltIn

import Data.Bits
import Data.List

import qualified Data.ByteString as B
import qualified Cauterize.Schema as SC

fromSchema :: SC.Schema -> Maybe Specification
fromSchema (SC.Schema n v fs) =
  let spec = Specification n v (show $ formHash spec) (fromSchemaForms fs)
  in Just spec

fromSchemaForms :: [SC.SchemaForm] -> [SpecForm]
fromSchemaForms = map fromSchemaForm
  where
    fromSchemaForm (SC.FType f) = SpecForm $ fromSchemaType f

fromSchemaType :: SC.Type -> Type
fromSchemaType (SC.TBuiltIn b) = TBuiltIn b
fromSchemaType (SC.TScalar n b) = TScalar n b
fromSchemaType (SC.TConst n b i) = TConst n b i
fromSchemaType (SC.TFixedArray n m i) = TFixedArray n m i
fromSchemaType (SC.TBoundedArray n m i) = TBoundedArray n m i (minimalExpression i)
fromSchemaType (SC.TStruct n fs) = TStruct n (fromSchemaStructFields fs)
fromSchemaType (SC.TSet n fs) = TSet n (minimalBitField $ length fs) (fromSchemaSetFields fs)
fromSchemaType (SC.TEnum n vs) = TEnum n (minimalExpression $ length vs) (fromSchemaEnumVariants vs)
fromSchemaType (SC.TPartial n l vs) = TPartial n l (minimalExpression l) (fromSchemaPartialVariants vs)
fromSchemaType (SC.TPad n l) = TPad n l

fromSchemaStructFields :: [SC.StructField] -> [StructField]
fromSchemaStructFields = map go
  where
    go (SC.StructField n t) = StructField n t

fromSchemaSetFields :: [SC.SetField] -> [SetField]
fromSchemaSetFields fs = snd $ mapAccumL go 0 fs
  where
    go :: Int -> SC.SetField -> (Int, SetField)
    go a (SC.SetField n m) = (a + 1, SetField n m (1 `shiftL` a))

fromSchemaEnumVariants :: [SC.EnumVariant] -> [EnumVariant]
fromSchemaEnumVariants vs = snd $ mapAccumL go 0 vs
  where
    go :: Int -> SC.EnumVariant -> (Int, EnumVariant)
    go a (SC.EnumVariant n m) = (a + 1, EnumVariant n m (fromIntegral a))

fromSchemaPartialVariants :: [SC.PartialVariant] -> [PartialVariant]
fromSchemaPartialVariants = map go
  where
    go :: SC.PartialVariant -> PartialVariant
    go (SC.PartialVariant n t) = PartialVariant n t (FormHash $ B.pack [0])
