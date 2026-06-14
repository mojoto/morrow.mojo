from .util import normalize_timestamp, _ymd2ord, _days_before_year
from ._libc import c_gettimeofday, c_localtime, c_gmtime, c_strptime
from ._libc import CTimeval, CTm
from .timezone import TimeZone
from .timedelta import TimeDelta
from .formatter import format_morrow
from .constants import days_before_month
from std.format import Writable, Writer


comptime _DI400Y = 146097  # number of days in 400 years
comptime _DI100Y = 36524  #    "    "   "   " 100   "
comptime _DI4Y = 1461  #    "    "   "   "   4   "


struct Morrow(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int
    var microsecond: Int
    var tz: TimeZone

    fn __init__(
        out self,
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        microsecond: Int = 0,
        tz: TimeZone = TimeZone.none(),
    ):
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
        self.tz = tz

    fn __copyinit__(out self, copy: Self):
        self.year = copy.year
        self.month = copy.month
        self.day = copy.day
        self.hour = copy.hour
        self.minute = copy.minute
        self.second = copy.second
        self.microsecond = copy.microsecond
        self.tz = copy.tz

    fn __moveinit__(out self, deinit take: Self):
        self.year = take.year
        self.month = take.month
        self.day = take.day
        self.hour = take.hour
        self.minute = take.minute
        self.second = take.second
        self.microsecond = take.microsecond
        self.tz = take.tz^

    @staticmethod
    fn now() -> Self:
        """
        Return a Morrow object representing the current local date and time.
        """
        var t = c_gettimeofday()
        return Self._fromtimestamp(t, False)

    @staticmethod
    fn utcnow() -> Self:
        """
        Return a Morrow object representing the current UTC date and time.
        """
        var t = c_gettimeofday()
        return Self._fromtimestamp(t, True)

    @staticmethod
    fn _fromtimestamp(t: CTimeval, utc: Bool) -> Self:
        var tm: CTm
        var tz: TimeZone
        if utc:
            tm = c_gmtime(t.tv_sec)
            tz = TimeZone(0, "UTC")
        else:
            tm = c_localtime(t.tv_sec)
            tz = TimeZone(Int(tm.tm_gmtoff), "local")

        var result = Self(
            Int(tm.tm_year) + 1900,
            Int(tm.tm_mon) + 1,
            Int(tm.tm_mday),
            Int(tm.tm_hour),
            Int(tm.tm_min),
            Int(tm.tm_sec),
            t.tv_usec,
            tz,
        )
        return result

    @staticmethod
    fn fromtimestamp(timestamp: Float64) raises -> Self:
        var timestamp_ = normalize_timestamp(timestamp)
        var t = CTimeval(Int(timestamp_))
        return Self._fromtimestamp(t, False)

    @staticmethod
    fn utcfromtimestamp(timestamp: Float64) raises -> Self:
        var timestamp_ = normalize_timestamp(timestamp)
        var t = CTimeval(Int(timestamp_))
        return Self._fromtimestamp(t, True)

    @staticmethod
    fn strptime(
        date_str: String, fmt: String, tzinfo: TimeZone = TimeZone.none()
    ) -> Self:
        """
        Create a Morrow instance from a date string and format,
        in the style of ``datetime.strptime``.  Optionally replaces the parsed TimeZone.

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S')
            <Morrow [2019-01-20T15:49:10+00:00]>
        """
        var tm = c_strptime(date_str, fmt)
        var tz = TimeZone(Int(tm.tm_gmtoff)) if tzinfo.is_none() else tzinfo
        return Self(
            Int(tm.tm_year) + 1900,
            Int(tm.tm_mon) + 1,
            Int(tm.tm_mday),
            Int(tm.tm_hour),
            Int(tm.tm_min),
            Int(tm.tm_sec),
            0,
            tz,
        )

    @staticmethod
    fn strptime(date_str: String, fmt: String, tz_str: String) raises -> Self:
        """
        Create a Morrow instance by time_zone_string with utc format.

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S', '+08:00')
            <Morrow [2019-01-20T15:49:10+08:00]>
        """
        var tzinfo = TimeZone.from_utc(tz_str)
        return Self.strptime(date_str, fmt, tzinfo)

    fn format(self, fmt: String = "YYYY-MM-DD HH:mm:ss ZZ") raises -> String:
        """
        Returns a string representation of the `Morrow`
        formatted according to the provided format string.

        :param fmt: the format string.

        Usage::
            >>> var m = Morrow.now()
            >>> m.format('YYYY-MM-DD HH:mm:ss ZZ')
            '2013-05-09 03:56:47 -00:00'

            >>> m.format('MMMM DD, YYYY')
            'May 09, 2013'

            >>> m.format()
            '2013-05-09 03:56:47 -00:00'

        """
        return format_morrow(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
            self.tz.offset,
            self.tz.name,
            self.tz.is_none(),
            self.isoweekday(),
            fmt,
        )

    fn isoformat(
        self, sep: String = "T", timespec: StringLiteral = "auto"
    ) raises -> String:
        """
        Return the time formatted according to ISO.

        The full format looks like 'YYYY-MM-DD HH:MM:SS.mmmmmm'.

        If self.tzinfo is not None, the UTC offset is also attached, giving
        giving a full format of 'YYYY-MM-DD HH:MM:SS.mmmmmm+HH:MM'.

        Optional argument sep specifies the separator between date and
        time, default 'T'.

        The optional argument timespec specifies the number of additional
        terms of the time to include. Valid options are 'auto', 'hours',
        'minutes', 'seconds', 'milliseconds' and 'microseconds'.
        """
        var date_str = self._date_string()
        var time_str: String
        if timespec == "auto" or timespec == "microseconds":
            time_str = self._time_string_microseconds()
        elif timespec == "milliseconds":
            time_str = (
                String(self.hour).ascii_rjust(2, "0")
                + ":"
                + String(self.minute).ascii_rjust(2, "0")
                + ":"
                + String(self.second).ascii_rjust(2, "0")
                + "."
                + String(self.microsecond // 1000).ascii_rjust(3, "0")
            )
        elif timespec == "seconds":
            time_str = (
                String(self.hour).ascii_rjust(2, "0")
                + ":"
                + String(self.minute).ascii_rjust(2, "0")
                + ":"
                + String(self.second).ascii_rjust(2, "0")
            )
        elif timespec == "minutes":
            time_str = (
                String(self.hour).ascii_rjust(2, "0")
                + ":"
                + String(self.minute).ascii_rjust(2, "0")
            )
        elif timespec == "hours":
            time_str = String(self.hour).ascii_rjust(2, "0")
        else:
            raise Error()
        if self.tz.is_none():
            return date_str + sep + time_str
        else:
            return date_str + sep + time_str + self.tz.format()

    fn _date_string(self) -> String:
        return (
            String(self.year).ascii_rjust(4, "0")
            + "-"
            + String(self.month).ascii_rjust(2, "0")
            + "-"
            + String(self.day).ascii_rjust(2, "0")
        )

    fn _time_string_microseconds(self) -> String:
        return (
            String(self.hour).ascii_rjust(2, "0")
            + ":"
            + String(self.minute).ascii_rjust(2, "0")
            + ":"
            + String(self.second).ascii_rjust(2, "0")
            + "."
            + String(self.microsecond).ascii_rjust(6, "0")
        )

    fn _isoformat_auto(self) -> String:
        var result = (
            self._date_string() + "T" + self._time_string_microseconds()
        )
        if not self.tz.is_none():
            result += self.tz.format()
        return result

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self._isoformat_auto())

    fn toordinal(self) raises -> Int:
        """
        Return the proleptic Gregorian ordinal of the date, where January 1 of year 1 has ordinal 1.
        """
        return _ymd2ord(self.year, self.month, self.day)

    @staticmethod
    fn fromordinal(ordinal: Int) raises -> Self:
        """
        Construct a Morrow object from a proleptic Gregorian ordinal.

        January 1 of year 1 is day 1. Only the year, month and day are non-zero in the result.
        """
        # n is a 1-based index, starting at 1-Jan-1.  The pattern of leap years
        # repeats exactly every 400 years.  The basic strategy is to find the
        # closest 400-year boundary at or before n, then work with the offset
        # from that boundary to n.  Life is much clearer if we subtract 1 from
        # n first -- then the values of n at 400-year boundaries are exactly
        # those divisible by _DI400Y:
        #
        #     D  M   Y            n              n-1
        #     -- --- ----        ----------     ----------------
        #     31 Dec -400        -_DI400Y       -_DI400Y -1
        #      1 Jan -399         -_DI400Y +1   -_DI400Y      400-year boundary
        #     ...
        #     30 Dec  000        -1             -2
        #     31 Dec  000         0             -1
        #      1 Jan  001         1              0            400-year boundary
        #      2 Jan  001         2              1
        #      3 Jan  001         3              2
        #     ...
        #     31 Dec  400         _DI400Y        _DI400Y -1
        #      1 Jan  401         _DI400Y +1     _DI400Y      400-year boundary
        var n = ordinal
        n -= 1
        var n400 = n // _DI400Y
        n = n % _DI400Y
        var year = n400 * 400 + 1  # ..., -399, 1, 401, ...

        # Now n is the (non-negative) offset, in days, from January 1 of year, to
        # the desired date.  Now compute how many 100-year cycles precede n.
        # Note that it's possible for n100 to equal 4!  In that case 4 full
        # 100-year cycles precede the desired day, which implies the desired
        # day is December 31 at the end of a 400-year cycle.
        var n100 = n // _DI100Y
        n = n % _DI100Y

        # Now compute how many 4-year cycles precede it.
        var n4 = n // _DI4Y
        n = n % _DI4Y

        # And now how many single years.  Again n1 can be 4, and again meaning
        # that the desired day is December 31 at the end of the 4-year cycle.
        var n1 = n // 365
        n = n % 365

        year += n100 * 100 + n4 * 4 + n1
        if n1 == 4 or n100 == 4:
            return Self(year - 1, 12, 31)

        # Now the year is correct, and n is the offset from January 1.  We find
        # the month via an estimate that's either exact or one too large.
        var leapyear = n1 == 3 and (n4 != 24 or n100 == 3)
        var month = (n + 50) >> 5
        var preceding: Int
        if month > 2 and leapyear:
            preceding = days_before_month(month) + 1
        else:
            preceding = days_before_month(month)
        if preceding > n:  # estimate is too large
            month -= 1
            if month == 2 and leapyear:
                preceding -= days_before_month(month) + 1
            else:
                preceding -= days_before_month(month)
        n -= preceding

        # Now the year and month are correct, and n is the offset from the
        # start of that month:  we're done!
        return Self(year, month, n + 1)

    fn isoweekday(self) raises -> Int:
        """
        Return the day of the week as an integer, where Monday is 1 and Sunday is 7.
        """
        # 1-Jan-0001 is a Monday
        return self.toordinal() % 7 or 7

    fn __str__(self) raises -> String:
        return self.isoformat()

    fn __sub__(self, other: Self) raises -> TimeDelta:
        var days1 = self.toordinal()
        var days2 = other.toordinal()
        var secs1 = self.second + self.minute * 60 + self.hour * 3600
        var secs2 = other.second + other.minute * 60 + other.hour * 3600
        var base = TimeDelta(
            days1 - days2, secs1 - secs2, self.microsecond - other.microsecond
        )
        return base
