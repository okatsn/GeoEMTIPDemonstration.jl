

struct TrainTestPartition23a <: InformationForFigure
    uniqfrc
    train_yr
end


function figureplot(TTP23a::TrainTestPartition23a; resolution = (700, 300))
    uniqfrc_Nyr = TTP23a.uniqfrc
    nyr = TTP23a.train_yr
    THBsNyr = [TwoHBoxes(Dates.Year(nyr), dt0, dt1-dt0, label) for ((dt0, dt1), label) in zip(dttag2datetime.(uniqfrc_Nyr), uniqfrc_Nyr)]
    theunit = [THB.unit for THB in THBsNyr] |> unique |> only
    approxlenfrc = [THB.right - THB.middle for THB in THBsNyr] |> mean |> round |> Int |> theunit |> Dates.canonicalize |> to_days |> round |> Day
    f0Nyr = Figure(; resolution = resolution)
    ax0N = Axis(f0Nyr[1,1]; title="Validation data partition", subtitle = "training window length: $(TTP23a.train_yr) years; testing window length ~ $approxlenfrc")
    tb = twohstackedboxes!(ax0N, THBsNyr)
    setyticks!(ax0N, THBsNyr)
    datetimeticks!(ax0N, THBsNyr, Month(6))
    ax0N.xticklabelrotation = 0.2π
    Label(f0Nyr[:, 0], "Forecasting Phase", rotation = 0.5π, tellheight = false)
    Legend(f0Nyr[end+1, :], 
        [PolyElement(color = tb.color_left), PolyElement(color = tb.color_right) ], 
        ["training window", "testing window"], 
        tellwidth = false, tellheight = true
    )
    display(f0Nyr)
    (ax0N, f0Nyr)
end

