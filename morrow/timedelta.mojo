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

    fn total_seconds(self) -> Float64:
        """Total seconds in the duration."""
        return ((self.days * 86400 + self.seconds) * 10 ** 6 + 
                self.microseconds) / 10 ** 6
    
    @always_inline
    fn __add__(self, other: TimeDelta) -> TimeDelta:
        return TimeDelta(
            self.days + other.days,
            self.seconds + other.seconds,
            self.microseconds + other.microseconds,
        )
    
    fn __radd_(self, other: TimeDelta) -> TimeDelta:
        return self.__add__(other)
    
    fn __sub__(self, other: TimeDelta) -> TimeDelta:
        return TimeDelta(
            self.days - other.days,
            self.seconds - other.seconds,
            self.microseconds - other.microseconds,
        )
    
    fn __rsub__(self, other: TimeDelta) -> TimeDelta:
        return TimeDelta(
            other.days - self.days,
            other.seconds - self.seconds,
            other.microseconds - self.microseconds,
        )
    
    fn __neg__(self) -> TimeDelta:
        return TimeDelta(-self.days, -self.seconds, -self.microseconds)
    
    fn __pos__(self) -> TimeDelta:
        return self
    
    def __abs__(self) -> TimeDelta:
        if self.days < 0:
            return -self
        else:
            return self
    
    fn __mul__(self, other: Int) -> TimeDelta:
        return TimeDelta(
            self.days * other,
            self.seconds * other,
            self.microseconds * other,
        )
