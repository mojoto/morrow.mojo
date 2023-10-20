from ._py import py_dt_datetime
from .util import normalize_timestamp, num2str, _ymd2ord
from ._libc import c_gettimeofday, c_localtime, c_gmtime, c_strptime
from ._libc import CTimeval, CTm
from .timezone import TimeZone
from .timedelta import TimeDelta


@value
struct Morrow:
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int
    var microsecond: Int
    var TimeZone: TimeZone

    fn __init__(
        inout self,
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        microsecond: Int = 0,
        TimeZone: TimeZone = TimeZone.none(),
    ) raises:
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
        self.TimeZone = TimeZone

    @staticmethod
    fn now() raises -> Morrow:
        let t = c_gettimeofday()
        return Morrow._fromtimestamp(t, False)

    @staticmethod
    fn utcnow() raises -> Morrow:
        let t = c_gettimeofday()
        return Morrow._fromtimestamp(t, True)

    @staticmethod
    fn _fromtimestamp(t: CTimeval, utc: Bool) raises -> Morrow:
        let tm: CTm
        let tz: TimeZone
        if utc:
            tm = c_gmtime(t.tv_sec)
            tz = TimeZone(0, "UTC")
        else:
            tm = c_localtime(t.tv_sec)
            tz = TimeZone(tm.tm_gmtoff.to_int(), "local")

        let result = Morrow(
            tm.tm_year.to_int() + 1900,
            tm.tm_mon.to_int() + 1,
            tm.tm_mday.to_int(),
            tm.tm_hour.to_int(),
            tm.tm_min.to_int(),
            tm.tm_sec.to_int(),
            t.tv_usec,
            tz,
        )
        return result

    @staticmethod
    fn fromtimestamp(timestamp: Float64) raises -> Morrow:
        let timestamp_ = normalize_timestamp(timestamp)
        let t = CTimeval(timestamp_.to_int())
        return Morrow._fromtimestamp(t, False)

    @staticmethod
    fn utcfromtimestamp(timestamp: Float64) raises -> Morrow:
        let timestamp_ = normalize_timestamp(timestamp)
        let t = CTimeval(timestamp_.to_int())
        return Morrow._fromtimestamp(t, True)

    @staticmethod
    fn strptime(
        date_str: String, fmt: String, tzinfo: TimeZone = TimeZone.none()
    ) raises -> Morrow:
        """
        Create a Morrow instance from a date string and format,
        in the style of ``datetime.strptime``.  Optionally replaces the parsed TimeZone.

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S')
            <Morrow [2019-01-20T15:49:10+00:00]>
        """
        let tm = c_strptime(date_str, fmt)
        let tz = TimeZone(tm.tm_gmtoff.to_int()) if tzinfo.is_none() else tzinfo
        return Morrow(
            tm.tm_year.to_int() + 1900,
            tm.tm_mon.to_int() + 1,
            tm.tm_mday.to_int(),
            tm.tm_hour.to_int(),
            tm.tm_min.to_int(),
            tm.tm_sec.to_int(),
            0,
            tz,
        )

    @staticmethod
    fn strptime(date_str: String, fmt: String, tz_str: String) raises -> Morrow:
        """
        Create a Morrow instance by time_zone_string with utc format

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S', '+08:00')
            <Morrow [2019-01-20T15:49:10+08:00]>
        """
        let tzinfo = TimeZone.from_utc(tz_str)
        return Morrow.strptime(date_str, fmt, tzinfo)

    fn isoformat(
        self, sep: String = "T", timespec: StringLiteral = "auto"
    ) raises -> String:
        """Return the time formatted according to ISO.

        The full format looks like 'YYYY-MM-DD HH:MM:SS.mmmmmm'.

        If self.tzinfo is not None, the UTC offset is also attached, giving
        giving a full format of 'YYYY-MM-DD HH:MM:SS.mmmmmm+HH:MM'.

        Optional argument sep specifies the separator between date and
        time, default 'T'.

        The optional argument timespec specifies the number of additional
        terms of the time to include. Valid options are 'auto', 'hours',
        'minutes', 'seconds', 'milliseconds' and 'microseconds'.
        """
        let date_str = (
            num2str(self.year, 4)
            + "-"
            + num2str(self.month, 2)
            + "-"
            + num2str(self.day, 2)
        )
        var time_str = String("")
        if timespec == "auto" or timespec == "microseconds":
            time_str = (
                num2str(self.hour, 2)
                + ":"
                + num2str(self.minute, 2)
                + ":"
                + num2str(self.second, 2)
                + "."
                + num2str(self.microsecond, 6)
            )
        elif timespec == "milliseconds":
            time_str = (
                num2str(self.hour, 2)
                + ":"
                + num2str(self.minute, 2)
                + ":"
                + num2str(self.second, 2)
                + "."
                + num2str(self.microsecond // 1000, 3)
            )
        elif timespec == "seconds":
            time_str = (
                num2str(self.hour, 2)
                + ":"
                + num2str(self.minute, 2)
                + ":"
                + num2str(self.second, 2)
            )
        elif timespec == "minutes":
            time_str = num2str(self.hour, 2) + ":" + num2str(self.minute, 2)
        elif timespec == "hours":
            time_str = num2str(self.hour, 2)
        else:
            raise Error()
        if self.TimeZone.is_none():
            return sep.join(date_str, time_str)
        else:
            return sep.join(date_str, time_str) + self.TimeZone.format()

    fn toordinal(self) raises -> Int:
        """Return proleptic Gregorian ordinal for the year, month and day.

        January 1 of year 1 is day 1.  Only the year, month and day values
        contribute to the result.
        """
        return _ymd2ord(self.year, self.month, self.day)

    fn __str__(self) raises -> String:
        return self.isoformat()

    fn __sub__(self, other: Morrow) raises -> TimeDelta:
        let days1 = self.toordinal()
        let days2 = other.toordinal()
        let secs1 = self.second + self.minute * 60 + self.hour * 3600
        let secs2 = other.second + other.minute * 60 + other.hour * 3600
        let base = TimeDelta(
            days1 - days2, secs1 - secs2, self.microsecond - other.microsecond
        )
        return base
