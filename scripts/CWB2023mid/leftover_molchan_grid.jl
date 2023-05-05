# These are pieces of code from makie_molchan_plane.jl, for backup, and
# they are not ready for being included to run.
# 


# ## group of figure (since dimension `frc` may be too large)
insertcols!(df, :figure => missing)
maxrowperfig = 6 # max rows per figure

nr = 1
figid = 1
for dfg in groupby(df, :frc)
    if nr > maxrowperfig
        figid = figid + 1
        nr = 1
    end
    dfg.figure .= figid
    nr = nr + 1
end

molplane_scatter = data(df) * xymap

# ### colored by group *prp*:
# scatter plot 
set_aog_theme!()
axis = (width = 225, height = 225)
molplane_scatter * visual(colormap = CF23.prp.colormap) * mapping(color = :prp_ind) |> draw  # Noted that layer_basic can be ignored

# contour plot 
layer_contour = AlgebraOfGraphics.density() * visual(Contour)
# molplane_scatter * layer_contour * mapping(color = :prp) |> draw

# # contour with scatter
# molp_all = molplane_scatter * (layer_contour + visual()) * mapping(color = :prp => "Filter")
# molp_all |> draw

# density 3D plot
layer_wireframe = AlgebraOfGraphics.density() * visual(Wireframe, linewidth = 0.5)
ax3d = (type = Axis3, width = 300, height = 300)
molplane_scatter * layer_wireframe * mapping(col = :prp) |> p -> draw(p; axis = ax3d)

# ## In subplots
molp_all = molplane_scatter * layer_basic * mapping(color = :prp, layout = :frc => "forecasting phase") + randguess
molp_all |> draw

molp_all = molplane_scatter * (layer_contour + layer_basic) * mapping(col = :prp, row = :frc => "forecasting phase") + randguess
molp_all |> p -> draw(p; axis = (width = 225, height = 225))



# plot_elements = visual(Scatter, color = CF23.prp.colormap[1]) +  AlgebraOfGraphics.density() * visual(Contour, levels = 5, colormap = :dense)
plot_elements = [
    AlgebraOfGraphics.density(npoints = 50) * visual(colormap = :grayC),
    visual(Scatter, color = (CF23.prp.colormap[3], 1), markersize = 3), 
]
figs_data = [data(dfg) for dfg in groupby(df, :figure)]
figs = figs_data .* 
        Ref(xymap) .*
        Ref(reduce(+, plot_elements)) .* 
        Ref(mapping(col = :prp, row = :frc => "forecasting phase")) .+ 
        Ref(randguess) .|> 
        Ref(x -> draw(x; axis = (width = 150, height = 140, limits = (0, 1 ,0 ,1)))) 

figs[1]
figs[2]
figs[3]




tbl = (x = [1, 1, 1, 2, 2, 2, 3, 3, 3],
       height = 0.1:0.1:0.9,
       grp = [1, 2, 3, 1, 2, 3, 1, 2, 3],
       grp1 = [1, 2, 2, 1, 1, 2, 1, 1, 2],
       grp2 = [1, 1, 2, 1, 2, 1, 1, 2, 1]
       )

barplot(tbl.x, tbl.height,
        stack = tbl.grp[1:8],
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Stacked bars"),
        )