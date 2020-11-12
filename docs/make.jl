using SimpleTypePrint
using Documenter

makedocs(;
    modules=[SimpleTypePrint],
    authors="Jiayi Wei <wjydzh1@gmail.com> and contributors",
    repo="https://github.com/MrVPlusOne/SimpleTypePrint.jl/blob/{commit}{path}#L{line}",
    sitename="SimpleTypePrint.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://MrVPlusOne.github.io/SimpleTypePrint.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/MrVPlusOne/SimpleTypePrint.jl",
)
