mutable struct ColorsFigure23{T<:Union{ColormapRef, Nothing}} <: PlotColors
    frc::T
    prp::T
    trial::T
end


"""
`categorical_colors(args...; kwargs...)` creates a vector of colors of `RGBA` with by-default `alpha=1.0`; it takes the same `args` and `kwargs` as `CairoMakie.cgrad`.
"""
function categorical_colors(args...; alpha=1.0, kwargs...) # alpha is required and it overwrite the ones in kwargs.
    colorgrad = CairoMakie.cgrad(args...; categorical = true, kwargs...) # to avoid `ERROR: ArgumentError: range(0.0, stop=1.0, length=1): endpoints differ` when the length of colors is 1
    return identity.(colorgrad.colors) # See  Makie.wong_colors |> methods
end


function ColorsFigure23(P::Prep202304;
                frccolor = :jet,
                prpcolor = categorical_colors(:Set1_4, 4), # Makie.wong_colors()
                trialcolor = ["#E10098", "#F48024", "#1db954"]) # other nice candidates: :Set1_3,:Dark2_3
    ColorsFigure23(
        ColormapRef(frccolor, P.uniqfrc),
        ColormapRef(prpcolor, P.uniqprp),
        ColormapRef(trialcolor, P.uniqtrial),
    )
end


"""
You may alternatively do:
```julia
colors = ["#FC7808", "#8C00EC", "#107A78"]
style = (color= colors, )
df = (x=rand(["a", "b", "c"], 100), y=rand(100))
plt = data(df) * mapping(:x, :y, color = :x) * visual(BoxPlot)
draw(plt, palettes = style)
```
See the thread [Styling AlgebraOfGraphics boxplots](https://discourse.julialang.org/t/styling-algebraofgraphics-boxplots/65335/8).
"""
function set_aog_pallete!(cref::ColormapRef)
    update_theme!(
        Theme(
            palette = (color = cref.colormap, )
        )
    )
end
