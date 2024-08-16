mutable struct ColorsFigure23{T<:Union{ColormapRef,Nothing}} <: PlotColors
    frc::T
    prp::T
    trial::T
end

function ColorsFigure23(P::Prep202304;
    frccolor=:jet,
    prpcolor=CairoMakie.categorical_colors(:Set1_4, 4), # Makie.wong_colors()
    trialcolor=["#3249ec", "#1db954", "#F48024"]) # other nice candidates: :Set1_3,:Dark2_3
    ColorsFigure23(
        ColormapRef(frccolor, P.uniqfrc),
        ColormapRef(prpcolor, P.uniqprp),
        ColormapRef(trialcolor, P.uniqtrial),
    )
end
