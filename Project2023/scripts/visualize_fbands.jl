using CairoMakie, AlgebraOfGraphics
using ColorSchemes
using DataFrames

fbands = DataFrame(
    :ULF_A => [0.001, 0.003],
    :ULF_B => [0.001, 0.01],
    :ULF_C => [0.001, 0.1],
    :BP_35 => [0.00032, 0.0178],
    :BP_40 => [0.00010, 0.0178],
    :index => [:low, :high])


fstk = stack(fbands, Not(:index), :index, variable_name=:band)
dfg = groupby(fstk, :index)
lows = dfg[(; index=:low)]
highs = dfg[(; index=:high)]

bands = lows.band
@assert isequal(bands, highs.band)

f = Figure(; resolution=(600, 200))
ax = Axis(f[:, :], xlabel="Hz")
rangebars!(ax, eachindex(bands), lows.value, highs.value; direction=:x, whiskerwidth=10)
ax.yticks = (eachindex(bands), bands)
ylims!(ax, extrema(eachindex(bands)) .+ [-0.5, 0.5])
f

Makie.save("FreqBands.png", f)
