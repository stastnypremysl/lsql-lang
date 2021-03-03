{-|
Module      : Lsql.Lang
License     : LGPL-3
Maintainer  : p-w@stty.cz
Stability   : experimental
Portability : POSIX

This module contains procedure for whole LSQL syntax analysis (tokenazing and parsing).

LSQL is firstly preprocessed by `Lsql.Lang.Expander`, then it is given to `Lsql.Lang.Tokenizer` and finally to `Lsql.Lang.Parser`.
-}

module Lsql.Lang() 
where


