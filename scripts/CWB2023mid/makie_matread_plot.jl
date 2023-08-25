using DataFrames, CSV
using CairoMakie, AlgebraOfGraphics
using Statistics
using LaTeXStrings
using Printf
import NaNMath: mean as nanmean
# using Revise # using Revise through VSCode settings
using CWBProjectSummaryDatasets
using GeoEMTIPDemonstration
using Dates
using OkFiles
using MAT



# It's useless
info = only1key(matread("data/temp/[JointStation]Information.mat"))
flist = filelist(r"\[JointStation\]ID", "data/temp")

f1 = flist[1]
Jst = only1key(matread(f1))
# useful
Jst["HitRatesForecasting"]
Jst["BestModelNames"]
Jst["AlarmedRateForecasting"]
Jst["ProbabilityLon"]
Jst["ProbabilityLat"]
Jst["TIP3"]
Jst["Probability"]
Jst["TIPvalid3"]


# useless
Jst["EQKs"]
Jst["validStationTime"]
Jst["ProbabilityTime"]
Jst["BestModels"]
