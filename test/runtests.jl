module TestSimpleTypePrint

if isdefined(@__MODULE__, :LanguageServer)  # hack to make vscode linter work properly
    include("../src/SimpleTypePrint.jl")
    using .SimpleTypePrint
else
    using SimpleTypePrint: repr_type
end

using Test

module A
    module B
        struct Foo{A} end

        f(x) = x
    end
end

macro type_print_test(ty, result) 
    esc(:(@test repr_type($ty) == $result))
end

@testset "type simple print" begin
    @test repr_type(Array{Int64, 2}) == "Array{Int64,2}"
    @test repr_type(Array{Int64}) == "Array{Int64,N} where N"
    @test repr_type(Tuple{A,B,C} where {A, B, C}) == "Tuple{A,B,C} where {A,B,C}"
    let nested = Tuple{Tuple{Tuple{A,B},C},D} where {A,B,C,D}
        expected = [
            "Tuple{...} where {A,B,C,D}",
            "Tuple{Tuple{...},D} where {A,B,C,D}",
            "Tuple{Tuple{Tuple{...},C},D} where {A,B,C,D}",
            "Tuple{Tuple{Tuple{A,B},C},D} where {A,B,C,D}",
            "Tuple{Tuple{Tuple{A,B},C},D} where {A,B,C,D}",
        ]
        @testset "with different depth limit" begin
            for d in 1:5
                @test repr_type(nested, max_depth=d) == expected[d]
            end
        end
    end

    @test repr_type(A.B.Foo) == "Foo{A} where A"
    @test endswith(repr_type(A.B.Foo; short_type_name=false), "A.B.Foo{A} where A")
    @test (repr_type(Tuple{A,B,C} where {A, B >: A, A<:C<:B}) 
            == "Tuple{A,B,C} where {A,B>:A,A<:C<:B}")
    @test (repr_type(Tuple{A} where {A <: Tuple{Tuple{Tuple{Int64}}}}, max_depth=3)
            == "Tuple{A} where A<:Tuple{Tuple{...}}")

    @type_print_test(Tuple{(Tuple{A} where A), A} where A, 
        "Tuple{Tuple{A1} where A1,A} where A")

    union_s = repr_type(Union{A,B} where {A,B})
    @test union_s ∈ ["Union{A,B} where {A,B}", "Union{B,A} where {A,B}"]
    
    @type_print_test(StridedArray{T,N} where {T, N}, "StridedArray{T,N} where {T,N}")
    @type_print_test(StridedVecOrMat{String}, "StridedVecOrMat{String}")

    @type_print_test NTuple{2, Int64} "Tuple{Int64,Int64}"
    @type_print_test NTuple{5, Int64} "NTuple{5,Int64}"


    f_repr = repr_type(typeof(A.B.f))
    @test startswith(f_repr, "typeof(") && endswith(f_repr, "A.B.f)")
end

end  # module TestSimpleTypePrint