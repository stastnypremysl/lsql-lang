{-|
Module      : Lsql.Lang.Tokens
License     : LGPL-3
Maintainer  : p-w@stty.cz
Stability   : experimental
Portability : POSIX

This module contains all tokens of LSQL language. 
Tokenizing is the first phase of language processing (after preprocessing by `Lsql.Lang.Expander`), before it is given to the parser (`Lsql.Lang.Parser`), which generates tree of terms (`Lsql.Lang.Terms`).
-}

module Lsql.Lang.Tokens() 
where


