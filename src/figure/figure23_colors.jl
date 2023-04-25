
mutable struct ColorsFigure23{T<:Union{ColormapRef, Nothing}} <: PlotColors
    frc::T
    prp::T
end

function ColorsFigure23(P::Prep202304; frccolor = :rainbow, prpcolor = :Paired_4)
    ColorsFigure23(
        ColormapRef(frccolor, P.uniqfrc), 
        ColormapRef(prpcolor, P.uniqprp), 
    )
end