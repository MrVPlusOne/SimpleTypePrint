module SimpleTypePrint

export show_type, repr_type, config_type_display

"""
# Examples
```jldoctest
julia> using SimpleTypePrint: print_multiple
       print_multiple(show, stdout, 1:10, "{", ",", "}")
{1,2,3,4,5,6,7,8,9,10}
```
"""
function print_multiple(f, io::IO, xs, left="{", sep=",", right="}")
    n = length(xs)::Int
    print(io, left)
    for (i, x) in enumerate(xs)
        f(io,x)
        i < n && print(io, sep)
    end
    print(io, right)
end

"""
    show_type(io, type; kwargs...)
"""
function show_type(io::IO, @nospecialize(ty::Type); max_depth::Int = 3, short_type_name::Bool = true)
    t_var_scope::Set{Symbol} = Set{Symbol}()

    function rec(x::DataType, d)
        # to be consistent with the Julia Compiler.
        (x === Tuple) && return Base.show_type_name(io, x.name)
        if x.name === Tuple.name
            n = length(x.parameters)::Int
            if n > 3 && all(i -> (x.parameters[1] === i), x.parameters)
                # Print homogeneous tuples with more than 3 elements compactly as NTuple
                print(io, "NTuple{", n, ',') 
                rec(x.parameters[1], d-1) 
                print(io, "}")
                return
            end
        end

        short_type_name ? print(io, nameof(x)) : Base.show_type_name(io, x.name)
        if !isempty(x.parameters)
            if d ≤ 1
                print(io, "{...}")
            else
                print_multiple((_,p) -> rec(p, d-1), io, x.parameters)
            end
        end
    end

    function rec(x::Union, d)
        if x.a isa DataType && Core.Compiler.typename(x.a) === Core.Compiler.typename(DenseArray)
            T, N = x.a.parameters
            if x == StridedArray{T,N}
                print(io, "StridedArray")
                print_multiple(show, io, (T,N))
                return
            elseif x == StridedVecOrMat{T}
                print(io, "StridedVecOrMat")
                print_multiple(show, io, (T,))
                return
            elseif StridedArray{T,N} <: x
                print(io, "Union")
                elems = vcat(StridedArray{T,N}, 
                    Base.uniontypes(Core.Compiler.typesubtract(x, StridedArray{T,N})))
                print_multiple((_, p) -> rec(p, d-1), io, elems)
                return
            end
        end
        print(io, "Union")
        print_multiple((_, p) -> rec(p, d-1), io, Base.uniontypes(x))
    end

    function show_tv_def(tv::TypeVar, d)
        function show_bound(io::IO, @nospecialize(b))
            parens = isa(b,UnionAll) && !Base.print_without_params(b)
            parens && print(io, "(")
            rec(b, d-1)
            parens && print(io, ")")
        end
        lb, ub = tv.lb, tv.ub
        if lb !== Base.Bottom
            if ub === Any
                Base.show_unquoted(io, tv.name)
                print(io, ">:")
                show_bound(io, lb)
            else
                show_bound(io, lb)
                print(io, "<:")
                Base.show_unquoted(io, tv.name)
            end
        else
            Base.show_unquoted(io, tv.name)
        end
        if ub !== Any
            print(io, "<:")
            show_bound(io, ub)
        end
        nothing
    end

    function rec(x::UnionAll, d, var_group::Vector{TypeVar}=TypeVar[])
        # rename tvar as needed
        var_symb = x.var.name
        if var_symb === :_ || var_symb ∈ t_var_scope
            counter = 1
            while true
                newname = Symbol(var_symb, counter)
                if newname ∉ t_var_scope
                    newtv = TypeVar(newname, x.var.lb, x.var.ub)
                    x = UnionAll(newtv, x{newtv})
                    break
                end
                counter += 1
            end
        end
        var_symb = x.var.name

        push!(var_group, x.var)
        push!(t_var_scope, var_symb)
        if x.body isa UnionAll
            # current var group continues
            rec(x.body, d, var_group)
        else
            # current var group ends
            rec(x.body, d)
            print(io, " where ")
            if length(var_group) == 1
                show_tv_def(var_group[1], d)
            else
                print_multiple((_, v) -> show_tv_def(v, d), io, var_group)
            end
        end
        delete!(t_var_scope, var_symb)
    end

    function rec(tv::TypeVar, d)
        Base.show_unquoted(io, tv.name)
    end

    function rec(ohter, d)
        @nospecialize(other)
        show(io, ohter)
    end

    rec(ty, max_depth)
end

"""
    repr_type(ty::Type; kwargs...)::String
"""
repr_type(ty::Type; kwargs...) = sprint((io,t) -> show_type(io,t; kwargs...), ty)

"""
    config_type_display(;kwargs...)

Replace `Base.show(io::IO, x::Type)` with the simpler type printing funciton 
`show_type`. 

See also: `show_type`, `repr_type`.
"""
function config_type_display(;kwargs...)
    @eval Base.show(io::IO, x::Type) = show_type(io, x; $(kwargs)...)
end

"""
# Keyword args
- `max_depth=3`: the maximal type AST depth to show. Type arguments deeper than this value
will be printed as `...`.
- `short_type_name=true`: when set to `true`, will print simple type names without their 
corresponding module path. e.g. "Name" instead of "ModuleA.ModuleB.Name". Note that the 
shorter name will always be used if the type is visible from the current scope. 
"""
show_type, repr_type, config_type_display

end  # module SimpleTypePrint
