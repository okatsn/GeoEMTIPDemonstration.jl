function figureplot(P::Prep202304, FDB::FDB2Panel23mid)
    df = tablegroupselect(P, FDB)

    uniqcolors_frc = gadfly_colors(length(P.uniqfrc))
    dfcb = combine(groupby(df, [:prp_ind, :frc_ind]), :FittingDegree => sum, nrow; renamecols = false)
    fd_norm_str = "Fitting Degree (normalized over jointstation models)"
    transform!(dfcb, [:FittingDegree, :nrow] => ByRow((x, y) -> x / y) => fd_norm_str)
    fbar = Figure(; resolution=(600, 500))
    
    axbar = Axis(fbar[1, 2])
    axbar2 = Axis(fbar[2, 2])
    barplot!(axbar, dfcb.prp_ind, dfcb[!, fd_norm_str]; 
        stack = dfcb.frc_ind, 
        color = uniqcolors_frc[dfcb.frc_ind], 
        )
    dfcb2 = combine(groupby(dfcb, :prp_ind), fd_norm_str => sum; renamecols = false)
    barplot!(axbar2, dfcb2.prp_ind, dfcb2[!, fd_norm_str]; 
        color = :black, 
        )
    axbar2.xticks[] = (collect(eachindex(P.uniqprp)), P.uniqprp)
    Label(fbar[:, 1], fd_norm_str, tellheight = false, rotation = π/2, fontsize =15)
    Legend(fbar[:, 3], 
        [PolyElement(polycolor = uniqcolors_frc[i]) for i in eachindex(uniqcolors_frc)], 
        P.uniqfrc,
        "Forecasting phase",
        tellheight = false, tellwidth = false
    )
    return (figure = fbar, ax1 = axbar, ax2 = axbar2)
end