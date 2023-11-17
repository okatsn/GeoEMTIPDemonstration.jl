"""
Given `dtstr` in format "yyyymmdd-yyyymmdd", `dtstr2nday(dtstr)` returns the number of days
covering this range.
Saying the two dates are `DateTime`, `dt0` and `dt1`, it should be noted that `dtstr2nday` returns `(dt1 - dt0).value + 1` rather than `(dt1 - dt0).value`.

```
dtstr = "20150402-20150928"
dtstr2nday(dtstr)
```
"""
function dtstr2nday(dtstr)
    dfmt = dateformat"yyyymmdd"
    nday = Date.(split(dtstr, "-"), Ref(dfmt)) |> diff |> only |> Day |> v -> getfield(v, :value)
    nday += 1
end
