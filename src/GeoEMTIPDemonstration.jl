module GeoEMTIPDemonstration

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

using DrWatson
include("projectdir.jl")
export dir_cwb2023mid

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

include("stationlocation_shift.jl")
export station_location_text_shift
export textoffset

end
