module TestSimpleTypePrint

if isdefined(@__MODULE__, :LanguageServer)  # hack to make vscode linter work properly
    include("../src/SimpleTypePrint.jl")
    using .SimpleTypePrint
else
    using SimpleTypePrint
end

using Test

module A
    module B
        struct Foo{A} end
    end
end
@testset "type simple print" begin
    @test repr_type(Array{Int, 2}) == "Array{Int64,2}"
    @test repr_type(Array{Int}) == "Array{Int64,N} where N"
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
    @test (repr_type(Tuple{A} where {A <: Tuple{Tuple{Tuple{Int}}}}, max_depth=3)
            == "Tuple{A} where A<:Tuple{Tuple{...}}")

    @test (repr_type(Tuple{(Tuple{A} where A), A} where A) 
            == "Tuple{Tuple{A1} where A1,A} where A")
end

end  # module TestSimpleTypePrint