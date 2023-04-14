using GeoEMTIPDemonstration
using Documenter

DocMeta.setdocmeta!(GeoEMTIPDemonstration, :DocTestSetup, :(using GeoEMTIPDemonstration); recursive=true)

makedocs(;
    modules=[GeoEMTIPDemonstration],
    authors="okatsn <okatsn@gmail.com> and contributors",
    repo="https://github.com/okatsn/GeoEMTIPDemonstration.jl/blob/{commit}{path}#{line}",
    sitename="GeoEMTIPDemonstration.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://okatsn.github.io/GeoEMTIPDemonstration.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/okatsn/GeoEMTIPDemonstration.jl",
    devbranch="master",
)
