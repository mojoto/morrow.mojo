from math import abs
from .util import num2str

@value
struct TimeDelta:
    var days: Int
    var seconds: Int
    var microseconds: Int

    fn __init__(
        inout self,
        days: Int = 0,
        seconds: Int = 0,
        microseconds: Int = 0,
    ) raises:
        self.days = days
        self.seconds = seconds
        self.microseconds = microseconds

    fn __str__(self) -> String:
        var mm = self.seconds // 60
        let ss = self.seconds % 60
        let hh = mm // 60
        mm = mm % 60
        var s = String(hh) + ":" + num2str(mm, 2) + ":" + num2str(ss, 2)
        if self.days:
            if abs(self.days) != 1:
                s = String(self.days) + " days " + s
            else:
                s = String(self.days) + " day " + s
        if self.microseconds:
            s = s + num2str(self.microseconds, 6)
        return s
