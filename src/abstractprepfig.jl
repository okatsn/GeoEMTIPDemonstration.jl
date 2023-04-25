"""
"""
abstract type InformationForFigure end

abstract type Preprocessed end

abstract type PlotColors end

abstract type ColorReference end

# struct 

struct ColormapRef <: ColorReference
    colortag
    colormap
    to_color::Function # given index, return color of the colormap
end

function ColormapRef(cmap::Symbol, colortag)
    colormap = CairoMakie.cgrad(cmap, length(colortag), categorical = true)
    to_color = i -> colormap[i]
    ColormapRef(colortag, colormap, to_color)
end
