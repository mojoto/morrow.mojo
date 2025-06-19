import small_time._libc as libc
import small_time.time_zone
from small_time._formatter import FORMATTER
from small_time.time_delta import TimeDelta
from small_time.calendar_math import _DAYS_BEFORE_MONTH, ymd_to_ordinal


alias DAYS_IN_400_YEARS = 146097
"""Number of days in 400 years."""
alias DAYS_IN_100_YEARS = 36524
"""Number of days in 100 years."""
alias DAYS_IN_4_YEARS = 1461
"""Number of days in 4 years."""
alias MAX_TIMESTAMP: Int = 32503737600
"""Maximum timestamp."""
alias MAX_TIMESTAMP_MS = MAX_TIMESTAMP * 1000
"""Maximum timestamp in milliseconds."""
alias MAX_TIMESTAMP_US = MAX_TIMESTAMP * 1_000_000
"""Maximum timestamp in microseconds."""


fn normalize_timestamp(owned timestamp: Float64) raises -> Float64:
    """Normalize millisecond and microsecond timestamps into normal timestamps.

    Args:
        timestamp: The timestamp to normalize.

    Returns:
        The normalized timestamp.

    Raises:
        Error: If the timestamp is too large.
    """
    if timestamp > MAX_TIMESTAMP:
        if timestamp < MAX_TIMESTAMP_MS:
            timestamp /= 1000
        elif timestamp < MAX_TIMESTAMP_US:
            timestamp /= 1_000_000
        else:
            raise Error("The specified timestamp ", timestamp, " is too large.")
    return timestamp


fn now(*, utc: Bool = False) raises -> SmallTime:
    """Return the current time in UTC or local time.

    Args:
        utc: If True, return the current time in UTC. Otherwise, return the current time in local time.

    Returns:
        The current time.
    """
    return from_timestamp(libc.get_time_of_day(), utc=utc)


fn _validate_timestamp(
    tm: libc._CTime, time_zone: TimeZone, time_val: Optional[libc._CTimeValue] = None
) raises -> SmallTime:
    """Validate the timestamp.

    Args:
        tm: The time struct.
        time_zone: The time zone.
        time_val: The time value.

    Returns:
        The validated timestamp.

    Raises:
        Error: If the timestamp is invalid.
    """
    var year = Int(tm.year) + 1900
    if not -1 < year < 10000:
        raise Error("The year parsed out from the timestamp is too large or negative. Received: ", year)

    var month = Int(tm.month) + 1
    if not -1 < month < 13:
        raise Error("The month parsed out from the timestamp is too large or negative. Received: ", month)

    var day = Int(tm.day_of_month)
    if not -1 < day < 32:
        raise Error("The day of the month parsed out from the timestamp is too large or negative. Received: ", day)

    var hours = Int(tm.hours)
    if not -1 < hours < 25:
        raise Error("The hour parsed out from the timestamp is too large or negative. Received: ", hours)

    var minutes = Int(tm.minutes)
    if not -1 < minutes < 61:
        raise Error("The minutes parsed out from the timestamp is too large or negative. Received: ", minutes)

    var seconds = Int(tm.seconds)
    if not -1 < seconds < 61:
        raise Error("The day of the month parsed out from the timestamp is too large or negative. Received: ", seconds)

    var microseconds = Int(time_val.value().microseconds) if time_val else 0
    if microseconds < 0:
        raise Error("Received negative microseconds. Received: ", microseconds)

    return SmallTime(
        year,
        month,
        day,
        hours,
        minutes,
        seconds,
        microseconds,
        time_zone,
    )


fn from_timestamp(t: libc._CTimeValue, *, utc: Bool) raises -> SmallTime:
    """Create a SmallTime instance from a timestamp.

    Args:
        t: The timestamp.
        utc: If True, the timestamp is in UTC. Otherwise, the timestamp is in local time.

    Returns:
        The SmallTime instance.

    Raises:
        Error: If the timestamp is invalid.
    """
    if utc:
        return _validate_timestamp(libc.get_gm_time(t.seconds), TimeZone.UTC, t)

    var tm = libc.get_local_time(t.seconds)
    var tz = TimeZone.from_utc_offset(Int(tm.time_zone_offset))
    return _validate_timestamp(tm, tz, t)


fn from_timestamp(timestamp: Float64, *, utc: Bool = False) raises -> SmallTime:
    """Create a SmallTime instance from a timestamp.

    Args:
        timestamp: The timestamp.
        utc: If True, the timestamp is in UTC. Otherwise, the timestamp is in local time.

    Returns:
        The SmallTime instance.

    Raises:
        Error: If the timestamp is invalid.
    """
    return from_timestamp(libc._CTimeValue(Int(normalize_timestamp(timestamp)), 0), utc=utc)


fn parse_time_with_format(date: StringSlice, format: StringSlice, tzinfo: TimeZone = TimeZone.UTC) raises -> SmallTime:
    """Create a `SmallTime` instance from a date string and format,
    in the style of `datetime.strptime`. Optionally replaces the parsed time_zone.
    Due to cstr pointer creation requiring a mutable reference to `date` and `format` to null terminate them,
    this function will allocate owned copies of the strings.

    Args:
        date: The date string.
        format: The format string.
        tzinfo: The time zone.

    Returns:
        The SmallTime instance.

    Raises:
        Error: If the timestamp is invalid.

    #### Examples:
    ```mojo
    from small_time.small_time import parse_time_with_format
    print(parse_time_with_format('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S'))
    ```
    """
    var date_str = String(date)
    var fmt_str = String(format)
    var tm = libc.parse_time_with_format(date_str, fmt_str)
    return _validate_timestamp(tm, tzinfo)


fn parse_time_with_format(date: StringSlice, format: StringSlice, tz: StringSlice) raises -> SmallTime:
    """Create a `SmallTime` instance from a date string and format,
    in the style of `datetime.strptime`. Optionally replaces the parsed time_zone.
    Due to cstr pointer creation requiring a mutable reference to `date` and `format` to null terminate them,
    this function will allocate owned copies of the strings.

    Args:
        date: The date string.
        format: The format string.
        tz: The time zone.

    Returns:
        The SmallTime instance.

    Raises:
        Error: If the timestamp is invalid.

    Examples:
    ```mojo
    from small_time.small_time import parse_time_with_format
    print(parse_time_with_format('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S'))
    ```
    .
    """
    return parse_time_with_format(date, format, time_zone.from_utc(tz))


fn from_ordinal(ordinal: Int) -> SmallTime:
    """Construct a SmallTime from a proleptic Gregorian ordinal.

    Args:
        ordinal: The proleptic Gregorian ordinal.

    Returns:
        The SmallTime instance.

    Notes:
        January 1 of year 1 is day 1.  Only the year, month and day are
        non-zero in the result.
    """
    var n = ordinal
    # n is a 1-based index, starting at 1-Jan-1.  The pattern of leap years
    # repeats exactly every 400 years.  The basic strategy is to find the
    # closest 400-year boundary at or before n, then work with the offset
    # from that boundary to n.  Life is much clearer if we subtract 1 from
    # n first -- then the values of n at 400-year boundaries are exactly
    # those divisible by DAYS_IN_400_YEARS:
    #
    #     D  M   Y            n              n-1
    #     -- --- ----        ----------     ----------------
    #     31 Dec -400        -DAYS_IN_400_YEARS       -DAYS_IN_400_YEARS -1
    #      1 Jan -399         -DAYS_IN_400_YEARS +1   -DAYS_IN_400_YEARS      400-year boundary
    #     ...
    #     30 Dec  000        -1             -2
    #     31 Dec  000         0             -1
    #      1 Jan  001         1              0            400-year boundary
    #      2 Jan  001         2              1
    #      3 Jan  001         3              2
    #     ...
    #     31 Dec  400         DAYS_IN_400_YEARS        DAYS_IN_400_YEARS -1
    #      1 Jan  401         DAYS_IN_400_YEARS +1     DAYS_IN_400_YEARS      400-year boundary
    n -= 1
    var n400 = n // DAYS_IN_400_YEARS
    n = n % DAYS_IN_400_YEARS
    var year = n400 * 400 + 1  # ..., -399, 1, 401, ...

    # Now n is the (non-negative) offset, in days, from January 1 of year, to
    # the desired date.  Now compute how many 100-year cycles precede n.
    # Note that it's possible for n100 to equal 4!  In that case 4 full
    # 100-year cycles precede the desired day, which implies the desired
    # day is December 31 at the end of a 400-year cycle.
    var n100 = n // DAYS_IN_100_YEARS
    n = n % DAYS_IN_100_YEARS

    # Now compute how many 4-year cycles precede it.
    var n4 = n // DAYS_IN_4_YEARS
    n = n % DAYS_IN_4_YEARS

    # And now how many single years.  Again n1 can be 4, and again meaning
    # that the desired day is December 31 at the end of the 4-year cycle.
    var n1 = n // 365
    n = n % 365

    year += n100 * 100 + n4 * 4 + n1
    if n1 == 4 or n100 == 4:
        return SmallTime(year - 1, 12, 31)

    # Now the year is correct, and n is the offset from January 1.  We find
    # the month via an estimate that's either exact or one too large.
    var leap_year = n1 == 3 and (n4 != 24 or n100 == 3)
    var month = (n + 50) >> 5
    var preceding: Int
    if month > 2 and leap_year:
        preceding = _DAYS_BEFORE_MONTH[month] + 1
    else:
        preceding = _DAYS_BEFORE_MONTH[month]
    if preceding > n:  # estimate is too large
        month -= 1
        if month == 2 and leap_year:
            preceding -= _DAYS_BEFORE_MONTH[month] + 1
        else:
            preceding -= _DAYS_BEFORE_MONTH[month]
    n -= preceding

    # Now the year and month are correct, and n is the offset from the
    # start of that month:  we're done!
    return SmallTime(year, month, n + 1)


@fieldwise_init
@register_passable("trivial")
struct Specification(Copyable, EqualityComparable, ExplicitlyCopyable, Movable):
    """Time specification for the `SmallTime.isoformat` method."""

    var value: Int
    """Internal enum value."""
    alias AUTO = Self(0)
    """Auto specification."""
    alias HOURS = Self(1)
    """Hours specification."""
    alias MINUTES = Self(2)
    """Minutes specification."""
    alias SECONDS = Self(3)
    """Seconds specification."""
    alias MILLISECONDS = Self(4)
    """Milliseconds specification."""
    alias MICROSECONDS = Self(5)
    """Microseconds specification."""

    fn __eq__(self, other: Self) -> Bool:
        """Check if two specifications are equal.

        Args:
            other: The other specification to compare with.

        Returns:
            True if the specifications are equal, False otherwise.
        """
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        """Check if two specifications are not equal.

        Args:
            other: The other specification to compare with.

        Returns:
            True if the specifications are not equal, False otherwise.
        """
        return self.value != other.value


struct SmallTime(Copyable, ExplicitlyCopyable, Movable, Representable, Stringable, Writable):
    """Datetime representation."""

    var year: Int
    """Year."""
    var month: Int
    """Month."""
    var day: Int
    """Day."""
    var hour: Int
    """Hour."""
    var minute: Int
    """Minute."""
    var second: Int
    """Second."""
    var microsecond: Int
    """Microsecond."""
    var time_zone: TimeZone
    """Time zone."""

    fn __init__(
        out self,
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        microsecond: Int = 0,
        tz: TimeZone = TimeZone.UTC,
    ):
        """Initializes a new SmallTime instance.

        Args:
            year: Year.
            month: Month.
            day: Day.
            hour: Hour.
            minute: Minute.
            second: Second.
            microsecond: Microsecond.
            tz: Time zone.
        """
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
        self.time_zone = tz

    fn format[template: String = "YYYY-MM-DD HH:mm:ss ZZ"](self) -> String:
        """Returns a string representation of the `SmallTime`
        formatted according to the provided format string.

        Parameters:
            template: The format string.

        Returns:
            The formatted string.

        Examples:
        ```mojo
        import small_time
        var m = small_time.now()
        print(m.format['YYYY-MM-DD HH:mm:ss ZZ']()) #'2013-05-09 03:56:47 -00:00'
        print(m.format['MMMM DD, YYYY']()) #'May 09, 2013'
        print(m.format()) #'2013-05-09 03:56:47 -00:00'
        ```
        """
        return FORMATTER.format[template](self)

    fn isoformat[specification: Specification = Specification.AUTO](self, separator: String = "T") -> String:
        """Return the time formatted according to ISO.

        Parameters:
            specification: The number of additional terms of the time to include.

        Args:
            separator: The separator between date and time.

        Returns:
            The formatted string.

        Notes:
            The full format looks like 'YYYY-MM-DD HH:MM:SS.mmmmmm'.

            If self.tzinfo is not None, the UTC offset is also attached, giving
            giving a full format of 'YYYY-MM-DD HH:MM:SS.mmmmmm+HH:MM'.

            Optional argument sep specifies the separator between date and
            time, default 'T'.

            The optional argument timespec specifies the number of additional
            terms of the time to include. Valid options are 'auto', 'hours',
            'minutes', 'seconds', 'milliseconds' and 'microseconds'.
        """
        var date = String(
            String(self.year).rjust(4, "0"), "-", String(self.month).rjust(2, "0"), "-", String(self.day).rjust(2, "0")
        )
        var time = String("")

        @parameter
        if specification == Specification.AUTO or specification == Specification.MICROSECONDS:
            time = String(
                String(self.hour).rjust(2, "0"),
                ":",
                String(self.minute).rjust(2, "0"),
                ":",
                String(self.second).rjust(2, "0"),
                ".",
                String(self.microsecond).rjust(6, "0"),
            )
        elif specification == Specification.MILLISECONDS:
            time = String(
                String(self.hour).rjust(2, "0"),
                ":",
                String(self.minute).rjust(2, "0"),
                ":",
                String(self.second).rjust(2, "0"),
                ".",
                String(self.microsecond // 1000).rjust(3, "0"),
            )
        elif specification == Specification.SECONDS:
            time = String(
                String(self.hour).rjust(2, "0"),
                ":",
                String(self.minute).rjust(2, "0"),
                ":",
                String(self.second).rjust(2, "0"),
            )
        elif specification == Specification.MINUTES:
            time = String(String(self.hour).rjust(2, "0"), ":", String(self.minute).rjust(2, "0"))
        elif specification == Specification.HOURS:
            time = String(self.hour).rjust(2, "0")

        return separator.join(date, time) + self.time_zone.format()

    fn to_ordinal(self) -> Int:
        """Return proleptic Gregorian ordinal for the year, month and day.

        Returns:
            Proleptic Gregorian ordinal for the year, month and day.

        Notes:
            January 1 of year 1 is day 1.  Only the year, month and day values
            contribute to the result.
        """
        return ymd_to_ordinal(self.year, self.month, self.day)

    fn iso_weekday(self) -> Int:
        """Returns day of the week.

        Returns:
            Day of the week, where Monday == 1 ... Sunday == 7.
        """
        return self.to_ordinal() % 7 or 7

    fn __str__(self) -> String:
        """Return the string representation of the `SmallTime` instance.

        Returns:
            The string representation.
        """
        return self.isoformat()

    fn __repr__(self) -> String:
        """Return the string representation of the `SmallTime` instance.

        Returns:
            The string representation.
        """
        return String.write(self)

    fn __sub__(self, other: Self) -> TimeDelta:
        """Subtract two `SmallTime` instances.

        Args:
            other: The other `SmallTime` instance.

        Returns:
            The time difference.
        """
        var days1 = self.to_ordinal()
        var days2 = other.to_ordinal()
        var secs1 = self.second + self.minute * 60 + self.hour * 3600
        var secs2 = other.second + other.minute * 60 + other.hour * 3600
        var base = TimeDelta(days1 - days2, secs1 - secs2, self.microsecond - other.microsecond)
        return base

    fn write_to[W: Writer, //](self, mut writer: W):
        """Writes a representation of the `SmallTime` instance to a writer.

        Parameters:
            W: The type of writer to write the contents to.

        Args:
            writer: The writer to write the contents to.
        """

        @parameter
        fn write_optional(opt: Optional[String]):
            if opt:
                writer.write(repr(opt.value()))
            else:
                writer.write(repr(None))

        writer.write(
            "SmallTime(",
            "year=",
            self.year,
            ", month=",
            self.month,
            ", day=",
            self.day,
            ", hour=",
            self.hour,
            ", minute=",
            self.minute,
            ", second=",
            self.second,
            ", microsecond=",
            self.microsecond,
        )
        writer.write(", tz=", "TimeZone(", "offset=", self.time_zone.offset, ", name=")
        write_optional(self.time_zone.name)
        writer.write(")")
        writer.write(")")
