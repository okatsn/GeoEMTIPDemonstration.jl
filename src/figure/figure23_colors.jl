
mutable struct ColorsFigure23{T<:Union{ColormapRef, Nothing}} <: PlotColors
    frc::T
    prp::T
    trial::T
end

function ColorsFigure23(P::Prep202304; 
                frccolor = :jet, 
                prpcolor = Makie.wong_colors(),
                trialcolor = :Set1_3)
    ColorsFigure23(
        ColormapRef(frccolor, P.uniqfrc), 
        ColormapRef(prpcolor, P.uniqprp), 
        ColormapRef(trialcolor, P.uniqtrial), 
    )
end