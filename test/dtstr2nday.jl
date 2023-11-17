@testset "dtstr2nday.jl" begin
    yyyy = rand(1900:2030, 10)
    mm = rand(1:12, 10)
    dd = rand(1:28, 10)
    nday = rand(1:400, 10)

    for (y, m, d, nd) in zip(yyyy, mm, dd, nday)
        dt0 = Date(y, m, d)
        dt1 = dt0 + Day(nd)
        dtstr0 = Dates.format(dt0, "yyyymmdd")
        dtstr1 = Dates.format(dt1, "yyyymmdd")
        dtstr = "$dtstr0-$dtstr1"
        @test dtstr2nday(dtstr) == nd + 1
    end
end
