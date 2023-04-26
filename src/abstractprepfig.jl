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

function ColormapRef(cmap, colortag)
    colormap, to_color = _get_colormap(cmap, colortag)
    ColormapRef(colortag, colormap, to_color)
end

function _get_colormap(cmap::Symbol, colortag)
    colormap = CairoMakie.cgrad(cmap, length(colortag), categorical = true)
    to_color = i -> colormap[i]
    return (colormap, to_color)
end

_get_colormap(cmap::Vector, colortag) = (cmap[1:length(colortag)], i -> cmap[i])

