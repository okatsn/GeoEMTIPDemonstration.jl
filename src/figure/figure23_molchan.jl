struct MolchanComposite23a <: InformationForFigure
    P::Prep202304
    by_trial::String
    by_train::Int
    CF23::ColorsFigure23
end

function figureplot(MO23a::MolchanComposite23a)
    df = groupby(MO23a.P.table, [:trial, :train_yr])[(trial=MO23a.by_trial, train_yr=MO23a.by_train)]

    df = dropnanmissing!(DataFrame(deepcopy(df)))
    uniqcolors_prp = MO23a.CF23.prp.colormap
    xymap = mapping(
        :AlarmedRateForecasting => identity => "alarmed rate",
        :MissingRateForecasting => identity => "missing rate",
    )
    layer_contour = AlgebraOfGraphics.density() * visual(Contour, levels=40, linewidth=0.5)

    # additional abline:
    randlinekwargs = (color="red", linestyle=:dashdot)
    randguess = data((x=[0, 1], y=[1, 0])) * visual(Lines; randlinekwargs...) * mapping(:x => "alarmed rate", :y => "missing rate")

    fmolall = Figure(; resolution=(750, 800))
    ftop = fmolall[1, 1] = GridLayout(1, 2)
    fbtm = fmolall[2, 1] = GridLayout(1, 2)
    molall = data(df) * visual(Scatter, markersize=6, colormap=uniqcolors_prp) * xymap * mapping(color=:prp_ind => "Filter") + randguess
    # molall2 = data(df) * AlgebraOfGraphics.density() * visual(Contour) * xymap * mapping(color = :prp => "Filter") + randguess
    draw2Dscatter = draw!(ftop[1, 1], molall; axis=(title="With stations: $(MO23a.by_trial); Training-window length: $(MO23a.by_train)",))
    # draw!(fmolall[1, 2], molall2)


    # density 2D plot
    plotbyprp2D = data(df) * layer_contour * xymap * mapping(col=:prp) + randguess
    draw2Dcountour = draw!(fbtm[1, 1], plotbyprp2D; axis=(aspect=1,))
    Legend(ftop[1, 2],
        vcat(
            [MarkerElement(color=clri, marker='•', markersize=30) for clri in uniqcolors_prp],
            [LineElement(; randlinekwargs...)]),
        vcat(MO23a.CF23.prp.colortag, ["random guess"])
    )

    colorbar!(fbtm[1, 2], draw2Dcountour; tellheight=false, vertical=true)


    rowsize!(fmolall.layout, 1, Relative(3 / 4))
    fmolall

end
