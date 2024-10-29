
# CairoMakie.categorical_colors(:Dark2_8, 8)[,]



neworder_Paired12 = vcat(1:4, 7:10)

no_red_Paired_12 = getindex(ColorSchemes.Paired_12, neworder_Paired12)

const noredPaired_12 = make_colorscheme(no_red_Paired_12, length(neworder_Paired12)) # ; category="Project2024", notes="Modified from `Paired_12`." # KEYNOTE: these keyword arguments are supported only for "Make a new ColorScheme from a dictionary" or "Make a colorscheme using functions"



neworder_Dark2 = [1, 3, 5, 7, 8]
no_red_Dark2 = getindex(ColorSchemes.Dark2_8, neworder_Dark2)

const noredDark2 =
    make_colorscheme(no_red_Dark2, length(neworder_Dark2))
