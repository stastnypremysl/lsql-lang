{-|
Module      : Lsql.Lang.Terms
License     : LGPL-3
Maintainer  : p-w@stty.cz
Stability   : experimental
Portability : POSIX

This module contains all terms of LSQL language in tree represetation. The tree of terms is generated by parser (`Lsql.Lang.Parser`) after the lexer (`Lsql.Lang.Tokenizer`) tokenize the input.

The document mainly speeks about the language syntax and not about its semantics (the meaning). It is supposed, that a reader knows the language already, so basic concepts are not explained here.

Language use generally two modes of language processing. The batch mode, which returns list of terms, and the arithmetic mode, which returns one term.
The batch mode is generally optimalized for low effort selection, aggregation and appendation by wildcards, bracket expansion,... (similar to bash syntax) If you are inside [] brackets, you are in batch mode.
The arithmetic mode is for low effort arithmetic expressions writting. (similar to awk syntax) If you are inside () brackets, you are in arithmetic mode.
For more details see LSQL documentation.

For better undestanding of the documentation, reading from the left to the right (Europian way of reading line), is the same thing as reading from a head of the list to a tail of the list.

There are two types of constant. Inbuild constant, which value is not returned by lexer, and arbitrary constant, which is given back by lexer together with value.

Be aware that there are two types of functions, which accepts unlimited number (but at least 1) of arguments. `MultiArgArithmeticF`, which is always evaluated in the context of a row, and `AggregateF`, which is evaluated in the context of BY variable attributes.

If a function is given a bad number of arguments in arithmetic mode, then it should always fail. This is always checked by lexer.

If a function is given a bad number of arguments in batch mode, it can eather fail (only if the number of arguments is 0 or is not dividable by expected number of arguments), or will behave like it was run multiple times in MList. 
(f[a1 a2 a3 a4] = [ f(a1,a2) f(a3,a4) ] if expected number of argument is 2)

There are two types of variables. Arrays and scalars. Array can be made of any types of scalars. The scalars can be eather String, Boolean, Double, Int and optionally UnitDouble (for example 5.4 km/h). 
If array is given to an one-argument function, it will map it on it. If array is given to a multi-argument function, it will take all its elements as parameters.
If array should be put inside another array, it will be appended instead of it.
-}

module Lsql.Lang.Terms (
  Root(Root),
  Block(From, Select, If, Sort, By),

  Arg(BatchSymbol, NamedBatchSymbol, BatchFunction, ArithmeticFunction, ArithmeticSymbol, TextSymbol, VariableSymbol, InbuiltConstant), 

  InbuiltConstant(PiConstant, EConstant),

  OneArgArithmeticF(
    Sin, Cos, Tan, Asin, Acos, Atan,
    Sinh, Cosh, Tanh, Asinh, Acosh, Atanh,
    Exp, Log,
    Sqrt,
    Refresh, Size, Length,
    ToString, ToInt, ToBoolean, ToDouble,
    Round, Truncate, Ceiling, Floor,
    MinusS, Abs, Signum, Negate,
    Even, Odd,
    Not,
    Factorial
  ),

  TwoArgArithmeticF(
    Plus, Minus, Multiply, Divide, Power,
    NaturalPower, Div, Quot, Rem, Mod, Gcd, Lcm,
    Less, LessOrEqual, More, MoreOrEqual, Equal, NotEqual, 
    LeftOuterJoin, In,
    And, Or,
    Append,
    When,
    CombinationNumber
  ),

  ThreeArgArithmeticF(Substitute, IfElse),

  MultiArgArithmeticF(MList),

  AggregateF(Cat, List, Sum, Avg, Count, Min, Max),

  EnumF(AggregateF, OneArgArithmeticF, 
    TwoArgArithmeticF, ThreeArgArithmeticF,
    MultiArgArithmeticF
  )

) where

import qualified Data.Text as T

-- | Each query is made of blocks.
-- Queries can be read from left to the right as the data flows.
data Root = Root [Block]

-- | Block is part of program separated by comma.
data Block = 

  -- | `From` block defines the input for a query. (eg. table or csv file). There will be always one and only one From block in the head of `Root`.
  -- `From` block are processed in batch mode.
  -- `From` block might eather contain `BatchSymbol`s or `NamedBatchSymbol`. 
  From [Arg] | 

  -- | `Select` block defines, what will be output of a query. (eg. some columns, aritmetic expressions,...)
  -- Each `Select` block is meant as separator, where previous data is replaced by new data.
  -- `Select` blocks are processed in batch mode.
  Select [Arg] | 

  -- | `If` block defines a condition for a row to be shown. If a condition is evaluated not as true, row should be filtered away.
  --  It is up to implementation, whether evalutation will fail or record skipped, if it can't be converted to bool.
  -- `If` blocks are processed in arithmetic mode.
  -- `If` blocks can contain v`Function` or v`ArithmeticSymbol`.
  If Arg | 

  -- | `Sort` block defines the ordering of data. It should be sorted using args most on the left to args most on the right.
  -- `Sort` blocks are processed in batch mode.
  -- `Sort` blocks can contain only `BatchSymbol`s.
  Sort [Arg] |

  -- | `By` block defines grouping attribute for aggregated functions. Attributes are valid until next select block is processed.
  -- `By` blocks are processed in batch mode.
  -- `By` blocks can contain only `BatchSymbol`s.
  By [Arg]

-- | `Arg` term is an argument eather for block or function.
data Arg = 

  -- | v`BatchFunction` constructor generates `Arg`, which should be later processed by semantic part of language implemantation.
  -- It can be generated only in batch mode.
  --
  -- If there is an excesive number of arguments, it should fail only if the amount of them is not divisable by expected number of arguments.
  -- Otherwise it should behave like function was called multiple times.
  BatchFunction EnumF [Arg] | 

  -- | v`ArithmeticFunction` constructor generates `Arg`, which should be later processed by semantic part of language implemantation.
  -- It can be generated only in arithmetic mode.
  -- If there is an unexpected number of arguments, it should always fail.
  ArithmeticFunction EnumF [Arg] | 

  -- | `BatchSymbol` constructor generates `Arg`, which might be eather a variable, variable wildcard or a constant.
  -- `BatchSymbol` is generated only in batch mode.
  BatchSymbol T.Text | 

  -- | `NamedBatchSymbol` constructor generates named `Arg`, which might be eather a variable, variable wildcard or a constant.
  -- `NamedBatchSymbol` is generated only in batch mode from Name=BatchSymbol syntax.
  NamedBatchSymbol
    T.Text -- ^ Name
    T.Text -- ^ BatchSymbol
    | 

  -- | v`ArithmeticSymbol` constructor generates `Arg`, which might be eather a variable or a constant.
  -- `ArithmeticSymbol` is generated only in arithmetic mode.
  ArithmeticSymbol T.Text |

  -- | v`TextSymbol` constructor generates `Arg`, which represents constant text. 
  -- It should be prefered by semantic part of an implementation of the language to interpret it as String.
  -- It can be generated in both batch and arithmetic mode.
  TextSymbol T.Text |

  -- | v'VariableSymbol' constructor generates `Arg`, which represents one variable.
  -- Semantic part of an implemantation of the language should fail, if the variable can't be found.
  VariableSymbol T.Text |
  
  -- | v'InbuiltConstant' constructor generates `Arg`, which represents one of inbuilt constants.
  InbuiltConstant InbuiltConstant

-- | Enumeration of all inbuilt constants.
data InbuiltConstant =

  -- | Standard pi number.
  PiConstant |

  -- | Standard e number.
  EConstant 

-- | Enumeration of all inbuild one argument functions.
data OneArgArithmeticF = 
  -- | Standard trigonometric sin(arg) function.
  Sin | 
  -- | Standard trigonometric cos(arg) function.
  Cos | 
  -- | Standard trigonometric tan(arg) function.
  Tan | 
  -- | Standard trigonometric asin(arg) function. It is the local inverse function of the sin(arg) function.
  Asin | 
  -- | Standard trigonometric acos(arg) function. It is the local inverse function of the cos(arg) function.
  Acos | 
  -- | Standard trigonometric atan(arg) function. It is the local inverse function of the tan(arg) function.
  Atan | 
  -- | Standard hyperbolic sinh(arg) function.
  Sinh | 
  -- | Standard hyperbolic cosh(arg) function.
  Cosh | 
  -- | Standard hyperbolic tanh(arg) function.
  Tanh |
  -- | Standard hyperbolic asinh(arg) function. It is the inverse function of the sinh(arg) function.
  Asinh | 
  -- | Standard hyperbolic acosh(arg) function. It is the local inverse function of the cosh(arg) function.
  Acosh | 
  -- | Standard hyperbolic atanh(arg) function. It is the inverse function of the tanh(arg) function.
  Atanh | 
  -- | Standard exp(arg) function with e base.
  Exp | 
  -- | Standard log(arg) function with e base. The inverse function of exp(arg) function.
  Log | 
  -- | Standard square root function sqrt(arg). It is the local inverse function of the square function.
  Sqrt |

    -- | len(arg). The length of variable after conversion to the string.
  Length |
  -- | size(arg). Number of elements in the array.
  -- The definition of array is up to language implementation.
  Size | 

  -- | r(arg). Automatic retyping of the arg. 
  -- A language implementation should try to recognize the type of variable after converting it to the string.
  Refresh | 
  -- | s(arg). It should retype an arg to the string.
  -- If arg is a list, it should try to retype all of its elements to the string.
  ToString |
  -- | i(arg). It should try to retype an arg to the int.
  -- If arg is a list, it should try to retype all of its elements to the string.
  ToInt |
  -- | d(arg). It should try to retype an arg to the double (or other numeric type with floating point).
  -- If arg is a list, it should try to retype all of its elements to the int.
  ToDouble |
  -- | b(arg). It should try to retype an arg to the boolean.
  -- If arg is a list, it should try to retype all of its elements to the double.
  ToBoolean |

  -- round(arg). It rounds number. The type should be persisted.
  -- If 
  Round | 
  Truncate | 
  Ceiling | 
  Floor |

  MinusS | Abs | Signum | Negate |
  Even | Odd |
  Not |
  Factorial

data TwoArgArithmeticF =
  Plus | Minus | Multiply | Divide | Power |
  NaturalPower | Div | Quot | Rem | Mod | Gcd | Lcm |
  Less | LessOrEqual | More | MoreOrEqual | Equal | NotEqual |
  LeftOuterJoin | In |
  And | Or | 
  Append | 
  When |
  CombinationNumber

data ThreeArgArithmeticF = 
  Substitute | 
  IfElse

-- | Enumeration of all multiarg functions
data MultiArgArithmeticF =
  -- | Pure operator [arg1 arg2 ...]. It returns the list of arguments.
  --
  -- If MList gets inside `[Arg]`, it should be always catterated as it isn't there. This happens when the brackets are created in batch mode.
  --
  -- If MList gets inside a position, where can only one variable be expected, it should be converted to the array, or to the scalar
  -- This happens, when brackets are created in arithmetics mode.
  --
  -- For example [[arg1] [arg2 arg3]] is the same thing as [arg1 arg2 arg3]
  MList

-- | Enumeration of all aggregate functions
data AggregateF =
  -- | cat[arg1 arg2 ...]. It returns the string concatenation of all arguments.
  Cat | 
  List | Sum | Avg | Count | Min | Max


data EnumF = 
  AggregateF AggregateF | 
  OneArgArithmeticF OneArgArithmeticF | 
  TwoArgArithmeticF TwoArgArithmeticF | 
  ThreeArgArithmeticF ThreeArgArithmeticF |  
  MultiArgArithmeticF MultiArgArithmeticF
