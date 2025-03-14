module GeoEMTIPDemonstration

include("datasettypes.jl")
export TrialTable, SummaryJointStation # abstract
export PhaseTest, PhaseTestEQK # concrete


using MolchanCB
include("getdcb.jl")
export getdcb

# # Load abstract type for preprocessing and figureplot
# Please refer these abstract types when working on src code under figure/ and preprocess/
include("abstractprepfig.jl")
export Preprocessed, InformationForFigure, ColormapRef

using Dates
include("to_days.jl")
include("dtstr2nday.jl")
export dtstr2nday

include("projectdir.jl")
export dir_map

include("only1field.jl")
export only1field, only1key

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
include("figure/figure23_colors.jl")
export ColorsFigure23

using OkMakieToolkits, CairoMakie, AlgebraOfGraphics, OkDataFrameTools, Statistics
include("figure/figure23_traintestpart.jl")
export TrainTestPartition23a

include("figure/figure23_molchan.jl")
export MolchanComposite23a

export figureplot

end
