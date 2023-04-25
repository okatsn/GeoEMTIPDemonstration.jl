module GeoEMTIPDemonstration

# # Load abstract type for preprocessing and figureplot
# Please refer these abstract types when working on src code under figure/ and preprocess/ 
include("abstractprepfig.jl")
export Preprocessed, InformationForFigure


using DrWatson
include("projectdir.jl")
export dir_cwb2023mid

include("only1field.jl")
export only1field

using Dates
include("dateinterval.jl")
export DateInterval

include("toindex.jl")

using DataFrames
include("preprocess/summary_test.jl")
export prep202304!
export dttag2datetime

using OkDataFrameTools
include("viewgroup.jl")
export viewgroup

# figureplot
using OkMakieToolkits, CairoMakie, AlgebraOfGraphics, OkDataFrameTools
include("figure/figure23_traintestpart.jl")
export TrainTestPartition23a

include("figure/figure23_molchan.jl")
export MolchanOverallComposite23a




export figureplot

end
