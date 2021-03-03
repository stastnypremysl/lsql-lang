{-|
Module      : Lsql.Lang.Tokenizer
License     : LGPL-3
Maintainer  : p-w@stty.cz
Stability   : experimental
Portability : POSIX

This module contains the lexer of LSQL language, which return list of tokens defined in `Lsql.Lang.Tokens`.

Tokenizing is the first phase of language processing (after preprocessing by `Lsql.Lang.Expander`), before it is given to the parser (`Lsql.Lang.Parser`), which generates tree of terms (`Lsql.Lang.Terms`).
-}


module Lsql.Lang.Tokenizer() 
where

import Lsql.Lang.Tokens

