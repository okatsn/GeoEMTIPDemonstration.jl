using DataFrames, MAT
using Revise
using GeoEMTIPDemonstration
FDS = dir_cwb2023mid("FDS_tag=O29F23_group=both_frcdur=365d.mat") |> matread |> only1field
trntags = FDS["trnTags"] |> vec
frctags = FDS["frcTags"] |> vec

FDS["mean"]

DCs = dir_cwb2023mid("DCs_tag=O29F23_group=both_frcdur=365d.mat") |> matread |> only1field
