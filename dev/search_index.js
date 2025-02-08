var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = GeoEMTIPDemonstration","category":"page"},{"location":"#GeoEMTIPDemonstration","page":"Home","title":"GeoEMTIPDemonstration","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for GeoEMTIPDemonstration.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [GeoEMTIPDemonstration]","category":"page"},{"location":"#GeoEMTIPDemonstration.binomial_cache","page":"Home","title":"GeoEMTIPDemonstration.binomial_cache","text":"A dictionary to cache computed binomial coefficients.\n\n\n\n\n\n","category":"constant"},{"location":"#GeoEMTIPDemonstration.DateInterval-Tuple{Any}","page":"Home","title":"GeoEMTIPDemonstration.DateInterval","text":"Iterable DateInterval(edges); returns (t0, t1) from edges where (t0, t1) = edges[i], edges[i + 1] for i in 1:length(edges)-1.\n\nExample\n\njulia> using Dates\n\njulia> edges = [Date(0000, 1, 1), Date(2017, 10, 1), Date(2020, 10, 1), Date(9999,12,31)];\n\njulia> [(t0, t1) for (t0, t1) in DateInterval(edges)]\n3-element Vector{Tuple{Date, Date}}:\n (Date(\"0000-01-01\"), Date(\"2017-10-01\"))\n (Date(\"2017-10-01\"), Date(\"2020-10-01\"))\n (Date(\"2020-10-01\"), Date(\"9999-12-31\"))\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.InformationForFigure","page":"Home","title":"GeoEMTIPDemonstration.InformationForFigure","text":"\n\n\n\n","category":"type"},{"location":"#GeoEMTIPDemonstration.TrialTable","page":"Home","title":"GeoEMTIPDemonstration.TrialTable","text":"The children of TrialTable are used to identify the matching between dataset and trial name. The matching methods are not general, and should be defined for specific projects; for example, see load_data.jl in the Project2024.\n\n\n\n\n\n","category":"type"},{"location":"#GeoEMTIPDemonstration.dtstr2nday-Tuple{Any}","page":"Home","title":"GeoEMTIPDemonstration.dtstr2nday","text":"Given dtstr in format \"yyyymmdd-yyyymmdd\", dtstr2nday(dtstr) returns the number of days covering this range. Saying the two dates are DateTime, dt0 and dt1, it should be noted that dtstr2nday returns (dt1 - dt0).value + 1 rather than (dt1 - dt0).value.\n\ndtstr = \"20150402-20150928\"\ndtstr2nday(dtstr)\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.getdcb-Tuple{Any, Any}","page":"Home","title":"GeoEMTIPDemonstration.getdcb","text":"getdcb(α, neq) calculate alarmed rate and hit rate for the given complementary confidence level α and number of earthquakes neq.\n\ngetdcb applies big if neq is larger than keyword argument applybig (40 by default).\n\nSince julia is slow in handling BigInt, getdcb by default looks into dictionary binomial_cache first if there are cached results already; this behavior is controlled by cache=true keyword argument.\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.prep202304!-Tuple{Any}","page":"Home","title":"GeoEMTIPDemonstration.prep202304!","text":"Given df = CSV.read(\"summary_test.csv\", DataFrame), prep202304!(df) calculates the following new columns:\n\n:FittingDegree\n:prp_ind (for Makie plot use)\n:frc_ind (for Makie plot use)\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.to_days-Tuple{Dates.CompoundPeriod}","page":"Home","title":"GeoEMTIPDemonstration.to_days","text":"to_days(p::Dates.CompoundPeriod) returns the summation of CompoundPeriod.\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.to_days-Tuple{Dates.Week}","page":"Home","title":"GeoEMTIPDemonstration.to_days","text":"Given p::Period, to_days(p) returns Real number of the value in the unit of day.\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.toindex-Tuple{AbstractString, Vector{<:AbstractString}}","page":"Home","title":"GeoEMTIPDemonstration.toindex","text":"toindex(str::AbstractString, uniqlabels::Vector{<:AbstractString}) returns the only index of uniqlabels exactly matched by str.\n\n\n\n\n\n","category":"method"},{"location":"#GeoEMTIPDemonstration.uniqsomething!-Tuple{Any, Any}","page":"Home","title":"GeoEMTIPDemonstration.uniqsomething!","text":"uniqcol = uniqsomething!(df, col) add new column \"col_ind\" as the integer indices for a vector of string uniqcol.\n\n\n\n\n\n","category":"method"}]
}
