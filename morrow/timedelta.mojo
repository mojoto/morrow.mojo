from math import abs
from .util import num2str


@value
struct TimeDelta:
    var days: Int
    var seconds: Int
    var microseconds: Int

    fn __init__(inout self, days: Int = 0, seconds: Int = 0, microseconds: Int = 0):
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
        return (
            (self.days * 86400 + self.seconds) * 10**6 + self.microseconds
        ) / 10**6

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

    @always_inline
    fn __mul__(self, other: Int) -> TimeDelta:
        return TimeDelta(
            self.days * other,
            self.seconds * other,
            self.microseconds * other,
        )

    fn __rmul__(self, other: Int) -> TimeDelta:
        return self.__mul__(other)

    fn _to_microseconds(self) -> Int:
        return (self.days * (24 * 3600) + self.seconds) * 1000000 + self.microseconds

    fn __mod__(self, other: TimeDelta) -> TimeDelta:
        let r = self._to_microseconds() % other._to_microseconds()
        return TimeDelta(0, 0, r)

    fn __eq__(self, other: TimeDelta) -> Bool:
        return (
            self.days == other.days
            and self.seconds == other.seconds
            and self.microseconds == other.microseconds
        )

    @always_inline
    fn __le__(self, other: TimeDelta) -> Bool:
        if self.days < other.days:
            return True
        elif self.days == other.days:
            if self.seconds < other.seconds:
                return True
            elif self.seconds == other.seconds and self.microseconds <= other.microseconds:
                return True
        return False

    @always_inline
    fn __lt__(self, other: TimeDelta) -> Bool:
        if self.days < other.days:
            return True
        elif self.days == other.days:
            if self.seconds < other.seconds:
                return True
            elif self.seconds == other.seconds and self.microseconds < other.microseconds:
                return True
        return False

    fn __ge__(self, other: TimeDelta) -> Bool:
        return not self.__lt__(other)

    fn __gt__(self, other: TimeDelta) -> Bool:
        return not self.__le__(other)

    fn __bool__(self) -> Bool:
        return self.days != 0 or self.seconds != 0 or self.microseconds != 0


alias Min = TimeDelta(-99999999)
alias Max = TimeDelta(days=99999999)
alias Resolution = TimeDelta(microseconds=1)
