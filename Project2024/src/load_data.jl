function load_all_trials()
    df23 = CWBProjectSummaryDatasets.dataset("SummaryJointStation", "PhaseTest_MIX_3yr_180d_500md_2023A10")

    df24 = CWBProjectSummaryDatasets.dataset("Summary_JointStation-J28-1qx", "PhaseTest_3yr_173d_J28")

    df24a = CWBProjectSummaryDatasets.dataset("Summary_JointStation-A19-4Dr", "PhaseTest_3yr_173d_A19")


    insertcols!(df23, :trial => "use S, K")
    insertcols!(df24, :trial => "use S, K, SEP, FIM")
    insertcols!(df24a, :trial => "use S, K, SEP")

    return (
        t1=df23,
        t2=df24a,
        t3=df24
    )
end
