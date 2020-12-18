# SimpleTypePrint.jl

[![Build Status](https://travis-ci.com/MrVPlusOne/SimpleTypePrint.svg?branch=master)](https://travis-ci.com/MrVPlusOne/SimpleTypePrint)
[![Coverage](https://codecov.io/gh/MrVPlusOne/SimpleTypePrint/branch/master/graph/badge.svg)](https://codecov.io/gh/MrVPlusOne/SimpleTypePrint)

**Display Julia types in a more human-friendly way.**

## Motivation

This package provides alternative type printing functions to make it easier to read Julia types. So instead of having to read messy outputs like this:
![Before.png](images/Before.png)

Using this package, we can overwrite `Base.show(::IO, ::Type)` to achieve a much cleaner result:
![After.png](images/After.png)

## Usages
First, install the package with
```julia
Using Pkg; Pkg.add("SimpleTypePrint")
```

You can then override the default type printing behavior by calling
```julia
config_type_display(max_depth=3, short_type_name=true)
```

If you prefer not to override the Julia default, you can instead use the provided `show_type(io, type; kwargs...)` and `repr_type(type; kwargs...)` function to manually print selected types.

## Changes compared to `Base.show`

### Merging nested where clauses
By default, Julia display multiple where clauses separately, whereas in SimpleTypePrint, where clauses are correctly merged, just like how you would write them.

|                 |                                        |
|-----------------|----------------------------------------|
| Input           | `Tuple{A,B,C} where {A, B, C}`         |
| Base.show       | `Tuple{A,B,C} where C where B where A` |
| SimpleTypePrint | `Tuple{A,B,C} where {A,B,C}`           |

### Displaying deeply nested parts as ellipsis
The default max display depth is 3, but you can change this value using the `max_depth` keyword argument. 

|                 |                                        |
|-----------------|----------------------------------------|
| Input           | `Tuple{Tuple{Tuple{A,B},C},D} where {A,B,C,D}` |
| Base.show       | `Tuple{Tuple{Tuple{A,B},C},D} where D where C where B where A` |
| SimpleTypePrint(max_depth=3) | `Tuple{Tuple{Tuple{...},C},D} where {A,B,C,D}`           |

### Displaying type names without module prefixes
By default, Julia displays module prefixes unless the type is directly visible from the current scope. SimpleTypePrint allows you to opt-out from this behavior.

```julia
julia> module A
           module B
               struct Foo{A} end
           end
       end  # Foo is nested inside A and B.
Main.A
```

|                 |                                        |
|-----------------|----------------------------------------|
| Input           | `A.B.Foo` |
| Base.show       | `Main.A.B.Foo` |
| SimpleTypePrint(short_type_name=true) | `Foo{A} where A`           |


### Renaming type variables with conflicting names

|                 |                                        |
|-----------------|----------------------------------------|
| Input           | `Tuple{(Tuple{A} where A), A} where A` |
| Base.show       | `Tuple{Tuple{A} where A,A} where A` |
| SimpleTypePrint | `Tuple{Tuple{A1} where A1,A} where A`           |


