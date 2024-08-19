using GeoEMTIPDemonstration
using Documenter
# using DocumenterCitations
# # 1. Uncomment this line and the CitationBibliography line
# # 2. add docs/src/refs.bib
# # 3. Cite something in refs.bib and add ```@bibliography ``` (in index.md, for example)
# # Please refer https://juliadocs.org/DocumenterCitations.jl/stable/


DocMeta.setdocmeta!(GeoEMTIPDemonstration, :DocTestSetup, :(using GeoEMTIPDemonstration); recursive=true)

makedocs(;
    modules=[GeoEMTIPDemonstration],
    authors="okatsn <okatsn@gmail.com> and contributors",
    repo="https://github.com/okatsn/GeoEMTIPDemonstration.jl/blob/{commit}{path}#{line}",
    sitename="GeoEMTIPDemonstration.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://okatsn.github.io/GeoEMTIPDemonstration.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    # plugins=[
    #     CitationBibliography(joinpath(@__DIR__, "src", "refs.bib")),
    # ],
)

deploydocs(;
    repo="github.com/okatsn/GeoEMTIPDemonstration.jl",
    devbranch="main",
)
