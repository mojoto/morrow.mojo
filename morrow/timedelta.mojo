from std.format import Writable, Writer

comptime SECONDS_OF_DAY = 24 * 3600


struct TimeDelta(Copyable, ImplicitlyCopyable, Movable, Writable):
    """
    Represents a duration of time.
    """

    var days: Int
    var seconds: Int
    var microseconds: Int

    def __init__(
        out self,
        days: Int = 0,
        seconds: Int = 0,
        microseconds: Int = 0,
        milliseconds: Int = 0,
        minutes: Int = 0,
        hours: Int = 0,
        weeks: Int = 0,
    ):
        """
        Initialize a TimeDelta object.
        """
        self.days = 0
        self.seconds = 0
        self.microseconds = 0

        var days_ = days
        var seconds_ = seconds
        var microseconds_ = microseconds

        # Normalize everything to days, seconds, microseconds.
        days_ += weeks * 7
        seconds_ += minutes * 60 + hours * 3600
        microseconds_ += milliseconds * 1000

        self.days = days_
        days_ = seconds_ // SECONDS_OF_DAY
        seconds_ = seconds_ % SECONDS_OF_DAY
        self.days += days_
        self.seconds += seconds_

        seconds_ = microseconds_ // 1000000
        microseconds_ = microseconds_ % 1000000
        days_ = seconds_ // SECONDS_OF_DAY
        seconds_ = seconds_ % SECONDS_OF_DAY
        self.days += days_
        self.seconds += seconds_

        seconds_ = microseconds_ // 1000000
        self.microseconds = microseconds_ % 1000000
        self.seconds += seconds_
        days_ = self.seconds // SECONDS_OF_DAY
        self.seconds = self.seconds % SECONDS_OF_DAY
        self.days += days_

    def __init__(out self, *, copy: Self):
        """
        Copy constructor for TimeDelta.
        """
        self.days = copy.days
        self.seconds = copy.seconds
        self.microseconds = copy.microseconds

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        var mm = self.seconds // 60
        var ss = self.seconds % 60
        var hh = mm // 60
        mm = mm % 60
        var result = String("")
        if self.days != 0:
            if abs(self.days) != 1:
                result += String(self.days) + " days, "
            else:
                result += String(self.days) + " day, "

        result += (
            String(hh)
            + ":"
            + String(mm).ascii_rjust(2, "0")
            + ":"
            + String(ss).ascii_rjust(2, "0")
        )
        if self.microseconds != 0:
            result += "." + String(self.microseconds).ascii_rjust(6, "0")
        return result

    def total_seconds(self) -> Float64:
        """
        Calculate the total number of seconds in the TimeDelta.
        """
        return (
            Float64(
                (self.days * 86400 + self.seconds) * 10**6 + self.microseconds
            )
            / 1000000.0
        )

    @always_inline
    def __add__(self, other: Self) -> Self:
        """
        Add two TimeDelta objects.
        """
        return Self(
            self.days + other.days,
            self.seconds + other.seconds,
            self.microseconds + other.microseconds,
        )

    def __radd__(self, other: Self) -> Self:
        """
        Reverse add operation for TimeDelta.
        """
        return self.__add__(other)

    def __sub__(self, other: Self) -> Self:
        """
        Subtract one TimeDelta from another.
        """
        return Self(
            self.days - other.days,
            self.seconds - other.seconds,
            self.microseconds - other.microseconds,
        )

    def __rsub__(self, other: Self) -> Self:
        """
        Reverse subtract operation for TimeDelta.
        """
        return Self(
            other.days - self.days,
            other.seconds - self.seconds,
            other.microseconds - self.microseconds,
        )

    def __neg__(self) -> Self:
        """
        Negate the TimeDelta.
        """
        return Self(-self.days, -self.seconds, -self.microseconds)

    def __pos__(self) -> Self:
        """
        Return a positive TimeDelta (self).
        """
        return self

    def __abs__(self) -> Self:
        """
        Return the absolute value of the TimeDelta.
        """
        if self.days < 0:
            return -self
        else:
            return self

    @always_inline
    def __mul__(self, other: Int) -> Self:
        """
        Multiply the TimeDelta by an integer.
        """
        return Self(
            self.days * other,
            self.seconds * other,
            self.microseconds * other,
        )

    def __rmul__(self, other: Int) -> Self:
        """
        Reverse multiply operation for TimeDelta.
        """
        return self.__mul__(other)

    def _to_microseconds(self) -> Int:
        """
        Convert the TimeDelta to microseconds.
        """
        return (
            self.days * SECONDS_OF_DAY + self.seconds
        ) * 1000000 + self.microseconds

    def __mod__(self, other: Self) -> Self:
        """
        Calculate the remainder of dividing this TimeDelta by another.
        """
        var r = self._to_microseconds() % other._to_microseconds()
        return Self(0, 0, r)

    def __eq__(self, other: Self) -> Bool:
        """
        Check if two TimeDelta objects are equal.
        """
        return (
            self.days == other.days
            and self.seconds == other.seconds
            and self.microseconds == other.microseconds
        )

    @always_inline
    def __le__(self, other: Self) -> Bool:
        """
        Check if this TimeDelta is less than or equal to another.
        """
        if self.days < other.days:
            return True
        elif self.days == other.days:
            if self.seconds < other.seconds:
                return True
            elif (
                self.seconds == other.seconds
                and self.microseconds <= other.microseconds
            ):
                return True
        return False

    @always_inline
    def __lt__(self, other: Self) -> Bool:
        """
        Check if this TimeDelta is less than another.
        """
        if self.days < other.days:
            return True
        elif self.days == other.days:
            if self.seconds < other.seconds:
                return True
            elif (
                self.seconds == other.seconds
                and self.microseconds < other.microseconds
            ):
                return True
        return False

    def __ge__(self, other: Self) -> Bool:
        """
        Check if this TimeDelta is greater than or equal to another.
        """
        return not self.__lt__(other)

    def __gt__(self, other: Self) -> Bool:
        """
        Check if this TimeDelta is greater than another.
        """
        return not self.__le__(other)

    def __bool__(self) -> Bool:
        """
        Check if the TimeDelta is non-zero.
        """
        return self.days != 0 or self.seconds != 0 or self.microseconds != 0


comptime Min = TimeDelta(-99999999)
comptime Max = TimeDelta(days=99999999)
comptime Resolution = TimeDelta(microseconds=1)
