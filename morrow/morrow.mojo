from .util import (
    normalize_timestamp,
    _ymd2ord,
    _days_before_year,
    _days_in_month,
)
from ._libc import (
    c_gettimeofday,
    c_localtime,
    c_gmtime,
    c_strptime,
    c_strptime_consumed,
)
from ._libc import CTimeval, CTm
from .timezone import TimeZone
from .timedelta import TimeDelta
from .formatter import format_morrow, format_strftime
from .constants import (
    MAX_ORDINAL,
    MAX_TIMESTAMP,
    MAX_TIMESTAMP_MS,
    MAX_TIMESTAMP_US,
    days_before_month,
    day_abbreviation,
    day_name,
    month_abbreviation,
    month_name,
)
from std.collections import List
from std.format import Writable, Writer


comptime _DI400Y = 146097  # number of days in 400 years
comptime _DI100Y = 36524  #    "    "   "   " 100   "
comptime _DI4Y = 1461  #    "    "   "   "   4   "
comptime _US_PER_SECOND = 1000000
comptime _US_PER_MINUTE = 60 * _US_PER_SECOND
comptime _US_PER_HOUR = 60 * _US_PER_MINUTE
comptime _US_PER_DAY = 24 * _US_PER_HOUR
comptime _UNIX_EPOCH_ORDINAL = 719163  # 1970-01-01
comptime _UNBOUNDED_LIMIT = -2147483648
comptime _HUMANIZE_SECONDS_PER_MONTH = 2635200  # 30.5 days
comptime _HUMANIZE_SECONDS_PER_QUARTER = 7905600  # 91.5 days


struct Morrow(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int
    var microsecond: Int
    var tz: TimeZone

    def __init__(
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

    def __init__(out self, *, copy: Self):
        self.year = copy.year
        self.month = copy.month
        self.day = copy.day
        self.hour = copy.hour
        self.minute = copy.minute
        self.second = copy.second
        self.microsecond = copy.microsecond
        self.tz = copy.tz

    def __init__(out self, *, deinit take: Self):
        self.year = take.year
        self.month = take.month
        self.day = take.day
        self.hour = take.hour
        self.minute = take.minute
        self.second = take.second
        self.microsecond = take.microsecond
        self.tz = take.tz^

    @staticmethod
    def now() -> Self:
        """
        Return a Morrow object representing the current local date and time.
        """
        var t = c_gettimeofday()
        return Self._fromtimestamp(t, False)

    @staticmethod
    def now(tz: TimeZone) raises -> Self:
        """
        Return the current time converted to a fixed-offset timezone.
        """
        return Self.utcnow().to(tz)

    @staticmethod
    def now(tz_str: String) raises -> Self:
        """
        Return the current time converted to a timezone parsed from a UTC offset string.
        """
        if tz_str == "local":
            return Self.now()
        return Self.utcnow().to(tz_str)

    @staticmethod
    def utcnow() -> Self:
        """
        Return a Morrow object representing the current UTC date and time.
        """
        var t = c_gettimeofday()
        return Self._fromtimestamp(t, True)

    @staticmethod
    def min() -> Self:
        """
        Return the minimum supported UTC Morrow value.
        """
        return Self(1, 1, 1, 0, 0, 0, 0, Self._utc_timezone())

    @staticmethod
    def max() -> Self:
        """
        Return the maximum supported UTC Morrow value.
        """
        return Self(9999, 12, 31, 23, 59, 59, 999999, Self._utc_timezone())

    @staticmethod
    def resolution() -> TimeDelta:
        """
        Return the smallest representable difference between Morrow values.
        """
        return TimeDelta(microseconds=1)

    @staticmethod
    def _fromtimestamp(t: CTimeval, utc: Bool) -> Self:
        var tm: CTm
        var tz: TimeZone
        if utc:
            tm = c_gmtime(t.tv_sec)
            tz = TimeZone(0, "UTC")
        else:
            tm = c_localtime(t.tv_sec)
            tz = TimeZone(Int(tm.tm_gmtoff), "local")

        var year = Int(tm.tm_year) + 1900
        var month = Int(tm.tm_mon) + 1
        var day = Int(tm.tm_mday)
        var hour = Int(tm.tm_hour)
        var minute = Int(tm.tm_min)
        var second = Int(tm.tm_sec)
        return Self(year, month, day, hour, minute, second, t.tv_usec, tz)

    @staticmethod
    def _fromtimestamp_checked(t: CTimeval, utc: Bool) raises -> Self:
        var result = Self._fromtimestamp(t, utc)
        Self._validate_fields(
            result.year,
            result.month,
            result.day,
            result.hour,
            result.minute,
            result.second,
            result.microsecond,
        )
        return result

    @staticmethod
    def fromtimestamp(timestamp: Float64) raises -> Self:
        return Self._fromtimestamp_checked(
            Self._timeval_from_timestamp(timestamp), False
        )

    @staticmethod
    def fromtimestamp(timestamp: Int) raises -> Self:
        return Self._fromtimestamp_checked(
            Self._timeval_from_timestamp(timestamp), False
        )

    @staticmethod
    def fromtimestamp(timestamp: String) raises -> Self:
        return Self.fromtimestamp(Float64(timestamp))

    @staticmethod
    def fromtimestamp(timestamp: Float64, tz: TimeZone) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def fromtimestamp(timestamp: Int, tz: TimeZone) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def fromtimestamp(timestamp: String, tz: TimeZone) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def fromtimestamp(timestamp: Float64, tz_str: String) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def fromtimestamp(timestamp: Int, tz_str: String) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def fromtimestamp(timestamp: String, tz_str: String) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def utcfromtimestamp(timestamp: Float64) raises -> Self:
        return Self._fromtimestamp_checked(
            Self._timeval_from_timestamp(timestamp), True
        )

    @staticmethod
    def utcfromtimestamp(timestamp: Int) raises -> Self:
        return Self._fromtimestamp_checked(
            Self._timeval_from_timestamp(timestamp), True
        )

    @staticmethod
    def utcfromtimestamp(timestamp: String) raises -> Self:
        return Self.utcfromtimestamp(Float64(timestamp))

    @staticmethod
    def _timeval_from_timestamp(timestamp: Int) raises -> CTimeval:
        var seconds = timestamp
        var microseconds = 0
        if timestamp > MAX_TIMESTAMP:
            if timestamp < MAX_TIMESTAMP_MS:
                seconds = timestamp // 1000
                microseconds = (timestamp % 1000) * 1000
            elif timestamp < MAX_TIMESTAMP_US:
                seconds = timestamp // _US_PER_SECOND
                microseconds = timestamp % _US_PER_SECOND
            else:
                raise Error("timestamp is too large")
        return CTimeval(seconds, microseconds)

    @staticmethod
    def _timeval_from_timestamp(timestamp: Float64) raises -> CTimeval:
        var timestamp_ = normalize_timestamp(timestamp)
        var seconds = Int(timestamp_)
        if Float64(seconds) > timestamp_:
            seconds -= 1
        var microseconds = Int(
            (timestamp_ - Float64(seconds)) * 1000000.0 + 0.5
        )
        if microseconds >= _US_PER_SECOND:
            seconds += 1
            microseconds -= _US_PER_SECOND
        return CTimeval(seconds, microseconds)

    @staticmethod
    def get() -> Self:
        """
        Create a UTC Morrow for the current time.
        """
        return Self.utcnow()

    @staticmethod
    def get(tz: TimeZone) raises -> Self:
        """
        Create a Morrow for the current time converted to a fixed-offset timezone.
        """
        return Self.now(tz)

    @staticmethod
    def _from_components(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        microsecond: Int,
        tz: TimeZone,
    ) raises -> Self:
        Self._validate_fields(
            year, month, day, hour, minute, second, microsecond
        )
        return Self(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            tz,
        )

    @staticmethod
    def get(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        microsecond: Int = 0,
    ) raises -> Self:
        """
        Create a UTC Morrow from date and time components.
        """
        return Self._from_components(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            Self._utc_timezone(),
        )

    @staticmethod
    def get(year: Int, month: Int, day: Int, tz: TimeZone) raises -> Self:
        """
        Create a Morrow from date components and a fixed-offset timezone.
        """
        return Self._from_components(year, month, day, 0, 0, 0, 0, tz)

    @staticmethod
    def get(year: Int, month: Int, day: Int, tz_str: String) raises -> Self:
        """
        Create a Morrow from date components and a timezone string.
        """
        return Self.get(year, month, day, Self._parse_timezone_argument(tz_str))

    @staticmethod
    def get(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        microsecond: Int,
        tz: TimeZone,
    ) raises -> Self:
        """
        Create a Morrow from date and time components with a fixed-offset timezone.
        """
        return Self._from_components(
            year, month, day, hour, minute, second, microsecond, tz
        )

    @staticmethod
    def get(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        microsecond: Int,
        tz_str: String,
    ) raises -> Self:
        """
        Create a Morrow from date and time components with a timezone string.
        """
        return Self.get(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            Self._parse_timezone_argument(tz_str),
        )

    @staticmethod
    def get(timestamp: Int) raises -> Self:
        """
        Create a UTC Morrow from a POSIX timestamp.
        """
        return Self.utcfromtimestamp(timestamp)

    @staticmethod
    def get(timestamp: Float64) raises -> Self:
        """
        Create a UTC Morrow from a POSIX timestamp.
        """
        return Self.utcfromtimestamp(timestamp)

    @staticmethod
    def get(timestamp: Int, tz: TimeZone) raises -> Self:
        """
        Create a Morrow from a POSIX timestamp converted to a fixed-offset timezone.
        """
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def get(timestamp: Float64, tz: TimeZone) raises -> Self:
        """
        Create a Morrow from a POSIX timestamp converted to a fixed-offset timezone.
        """
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def get(timestamp: Int, tz_str: String) raises -> Self:
        """
        Create a Morrow from a POSIX timestamp converted to a timezone string.
        """
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def get(timestamp: Float64, tz_str: String) raises -> Self:
        """
        Create a Morrow from a POSIX timestamp converted to a timezone string.
        """
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def get(date_str: String) raises -> Self:
        """
        Create a UTC Morrow from an ISO 8601 string.
        """
        return Self.fromisoformat(date_str)

    @staticmethod
    def get(date_str: String, normalize_whitespace: Bool) raises -> Self:
        """
        Create a UTC Morrow from an ISO 8601 string, optionally normalizing ASCII whitespace.
        """
        if normalize_whitespace:
            return Self.fromisoformat(Self._normalize_whitespace(date_str))
        return Self.fromisoformat(date_str)

    @staticmethod
    def get(date_str: String, formats: List[String]) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order.
        """
        return Self._parse_arrow_formats(date_str, formats)

    @staticmethod
    def get(
        date_str: String, formats: List[String], tz: TimeZone
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order and replacing timezone.
        """
        return Self._parse_arrow_formats(date_str, formats, tz)

    @staticmethod
    def get(
        date_str: String, formats: List[String], tz_str: String
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order and parsed replacement timezone.
        """
        return Self._parse_arrow_formats(
            date_str, formats, Self._parse_timezone_argument(tz_str)
        )

    @staticmethod
    def get(date_str: String, fmt: String) raises -> Self:
        """
        Create a Morrow by parsing a string with Arrow format tokens.
        """
        return Self._parse_arrow(date_str, fmt)

    @staticmethod
    def get(
        date_str: String, fmt: String, normalize_whitespace: Bool
    ) raises -> Self:
        """
        Create a Morrow by parsing Arrow tokens, optionally normalizing ASCII whitespace.
        """
        if normalize_whitespace:
            return Self._parse_arrow(
                Self._normalize_whitespace(date_str),
                Self._normalize_whitespace(fmt),
            )
        return Self._parse_arrow(date_str, fmt)

    @staticmethod
    def get(date_str: String, fmt: String, tz: TimeZone) raises -> Self:
        """
        Create a Morrow by parsing a string with Arrow format tokens and replacement timezone.
        """
        return Self._parse_arrow(date_str, fmt, tz)

    @staticmethod
    def get(date_str: String, fmt: String, tz_str: String) raises -> Self:
        """
        Create a Morrow by parsing a string with Arrow format tokens and parsed replacement timezone.
        """
        return Self._parse_arrow(
            date_str, fmt, Self._parse_timezone_argument(tz_str)
        )

    @staticmethod
    def get(date: MorrowDate) -> Self:
        """
        Create a UTC Morrow from a date view.
        """
        return Self.fromdate(date)

    @staticmethod
    def get(date: MorrowDate, tz: TimeZone) -> Self:
        """
        Create a Morrow from a date view and replacement timezone.
        """
        return Self.fromdate(date, tz)

    @staticmethod
    def get(date: MorrowDate, tz_str: String) raises -> Self:
        """
        Create a Morrow from a date view and parsed replacement timezone.
        """
        return Self.fromdate(date, tz_str)

    @staticmethod
    def get(dt: Self) -> Self:
        """
        Create a Morrow from another Morrow object.
        """
        return Self.fromdatetime(dt)

    @staticmethod
    def get(dt: Self, tz: TimeZone) -> Self:
        """
        Create a Morrow from another Morrow object and replacement timezone.
        """
        return Self.fromdatetime(dt, tz)

    @staticmethod
    def get(dt: Self, tz_str: String) raises -> Self:
        """
        Create a Morrow from another Morrow object and parsed replacement timezone.
        """
        return Self.fromdatetime(dt, tz_str)

    @staticmethod
    def get(iso: MorrowIsoCalendar) raises -> Self:
        """
        Create a UTC Morrow from ISO calendar fields.
        """
        return Self.fromisocalendar(iso.year, iso.week, iso.weekday)

    @staticmethod
    def fromisoformat(date_str: String) raises -> Self:
        """
        Create a Morrow from an ISO 8601 string.
        """
        var length = date_str.byte_length()
        if length < 4:
            raise Error("isoformat string is too short")

        var year: Int
        var month: Int
        var day: Int
        var pos: Int
        if length == 4:
            year = Int(date_str[byte=0:4])
            month = 1
            day = 1
            pos = 4
        elif (
            length >= 7
            and date_str[byte=4] == "-"
            and Self._is_ascii_digit(ord(date_str[byte=5]))
            and Self._is_ascii_digit(ord(date_str[byte=6]))
            and (
                length == 7
                or date_str[byte=7] == "T"
                or date_str[byte=7] == "t"
                or date_str[byte=7] == " "
            )
        ):
            year = Int(date_str[byte=0:4])
            month = Int(date_str[byte=5:7])
            day = 1
            pos = 7
        elif length >= 7 and (
            (date_str[byte=4] == "-" and date_str[byte=5] == "W")
            or date_str[byte=4] == "W"
        ):
            var iso_week = Self._parse_iso_week_date(date_str, 0)
            var date = Self.fromisocalendar(
                iso_week.year, iso_week.week, iso_week.weekday
            )
            year = date.year
            month = date.month
            day = date.day
            pos = iso_week.pos
        elif (
            length >= 8
            and date_str[byte=4] == "-"
            and Self._is_ascii_digit(ord(date_str[byte=5]))
            and Self._is_ascii_digit(ord(date_str[byte=6]))
            and Self._is_ascii_digit(ord(date_str[byte=7]))
        ):
            year = Int(date_str[byte=0:4])
            var day_of_year = Int(date_str[byte=5:8])
            if day_of_year < 1 or day_of_year > 366:
                raise Error("isoformat day of year is invalid")
            var date = Self.fromordinal(_ymd2ord(year, 1, 1) + day_of_year - 1)
            year = date.year
            month = date.month
            day = date.day
            pos = 8
        elif (
            length >= 7
            and Self._is_ascii_digit(ord(date_str[byte=0]))
            and Self._is_ascii_digit(ord(date_str[byte=1]))
            and Self._is_ascii_digit(ord(date_str[byte=2]))
            and Self._is_ascii_digit(ord(date_str[byte=3]))
            and Self._is_ascii_digit(ord(date_str[byte=4]))
            and Self._is_ascii_digit(ord(date_str[byte=5]))
            and Self._is_ascii_digit(ord(date_str[byte=6]))
            and (
                length == 7
                or date_str[byte=7] == "T"
                or date_str[byte=7] == "t"
                or date_str[byte=7] == " "
            )
        ):
            year = Int(date_str[byte=0:4])
            var day_of_year = Int(date_str[byte=4:7])
            if day_of_year < 1 or day_of_year > 366:
                raise Error("isoformat day of year is invalid")
            var date = Self.fromordinal(_ymd2ord(year, 1, 1) + day_of_year - 1)
            year = date.year
            month = date.month
            day = date.day
            pos = 7
        elif (
            length >= 6
            and Self._is_ascii_digit(ord(date_str[byte=0]))
            and Self._is_ascii_digit(ord(date_str[byte=1]))
            and Self._is_ascii_digit(ord(date_str[byte=2]))
            and Self._is_ascii_digit(ord(date_str[byte=3]))
            and (
                date_str[byte=4] == "-"
                or date_str[byte=4] == "/"
                or date_str[byte=4] == "."
            )
            and Self._is_ascii_digit(ord(date_str[byte=5]))
        ):
            year = Int(date_str[byte=0:4])
            var date_separator = ord(date_str[byte=4])
            var month_parsed = Self._parse_variable_int(date_str, 5, 2)
            month = month_parsed.value
            pos = month_parsed.pos
            if (
                pos == length
                or date_str[byte=pos] == "T"
                or date_str[byte=pos] == "t"
                or date_str[byte=pos] == " "
            ):
                if pos != 7:
                    raise Error("isoformat month is invalid")
                day = 1
            elif ord(date_str[byte=pos]) == date_separator:
                pos += 1
                var day_parsed = Self._parse_variable_int(date_str, pos, 2)
                day = day_parsed.value
                pos = day_parsed.pos
            else:
                raise Error("isoformat date separator is invalid")
        elif (
            length >= 10 and date_str[byte=4] == "-" and date_str[byte=7] == "-"
        ):
            year = Int(date_str[byte=0:4])
            month = Int(date_str[byte=5:7])
            day = Int(date_str[byte=8:10])
            pos = 10
        else:
            year = Int(date_str[byte=0:4])
            month = Int(date_str[byte=4:6])
            day = Int(date_str[byte=6:8])
            pos = 8

        var hour = 0
        var minute = 0
        var second = 0
        var microsecond = 0
        var tz = TimeZone.from_utc("UTC")

        if pos < length:
            var separator = ord(date_str[byte=pos])
            if separator != ord("T") and separator != ord(" "):
                raise Error("isoformat date/time separator is invalid")
            pos += 1
            if length < pos + 2:
                raise Error("isoformat time is invalid")

            hour = Int(date_str[byte = pos : pos + 2])
            pos += 2

            if pos < length and date_str[byte=pos] == ":":
                pos += 1
                if length < pos + 2:
                    raise Error("isoformat minute is invalid")
                minute = Int(date_str[byte = pos : pos + 2])
                pos += 2
                if pos < length and date_str[byte=pos] == ":":
                    pos += 1
                    if length < pos + 2:
                        raise Error("isoformat second is invalid")
                    second = Int(date_str[byte = pos : pos + 2])
                    pos += 2
            else:
                if pos < length and Self._is_ascii_digit(
                    ord(date_str[byte=pos])
                ):
                    if length < pos + 2:
                        raise Error("isoformat minute is invalid")
                    minute = Int(date_str[byte = pos : pos + 2])
                    pos += 2
                    if pos < length and Self._is_ascii_digit(
                        ord(date_str[byte=pos])
                    ):
                        if length < pos + 2:
                            raise Error("isoformat second is invalid")
                        second = Int(date_str[byte = pos : pos + 2])
                        pos += 2

            if pos < length and (
                date_str[byte=pos] == "." or date_str[byte=pos] == ","
            ):
                pos += 1
                var parsed = Self._parse_subsecond(date_str, pos, 6)
                microsecond = parsed.value
                pos = parsed.pos

            if pos < length:
                if date_str[byte=pos] == "Z":
                    tz = TimeZone.from_utc("UTC")
                    pos += 1
                elif date_str[byte=pos] == "+" or date_str[byte=pos] == "-":
                    var parsed = Self._parse_iso_timezone_offset(date_str, pos)
                    tz = parsed.tz
                    pos = parsed.pos
                else:
                    raise Error("isoformat timezone is invalid")

        if pos != length:
            raise Error("isoformat string has trailing data")
        var carried_fraction = False
        if microsecond >= _US_PER_SECOND:
            second += microsecond // _US_PER_SECOND
            microsecond = microsecond % _US_PER_SECOND
            carried_fraction = True
        if carried_fraction and second >= 60:
            Self._validate_fields(
                year, month, day, hour, minute, 0, microsecond
            )
            return Self(
                year, month, day, hour, minute, 0, microsecond, tz
            ).shift(seconds=second)
        if hour == 24:
            if minute != 0 or second != 0 or microsecond != 0:
                raise Error("midnight at the end of day must be exactly 24:00")
            Self._validate_fields(year, month, day, 0, 0, 0, 0)
            return Self(year, month, day, 0, 0, 0, 0, tz).shift(days=1)
        Self._validate_fields(
            year, month, day, hour, minute, second, microsecond
        )
        return Self(year, month, day, hour, minute, second, microsecond, tz)

    @staticmethod
    def _parse_arrow(
        date_str: String, fmt: String, tzinfo: TimeZone = TimeZone.none()
    ) raises -> Self:
        try:
            return Self._parse_arrow_at(date_str, fmt, tzinfo, 0, False)
        except e:
            pass

        for date_start in range(date_str.byte_length()):
            if not Self._has_left_parse_boundary(date_str, date_start):
                continue
            try:
                return Self._parse_arrow_at(
                    date_str, fmt, tzinfo, date_start, True
                )
            except e:
                pass
        raise Error("date string does not match format")

    @staticmethod
    def _parse_arrow_at(
        date_str: String,
        fmt: String,
        tzinfo: TimeZone,
        date_start: Int,
        allow_trailing_text: Bool,
    ) raises -> Self:
        var year = 1
        var has_year = False
        var month = 1
        var day = 1
        var day_of_year = -1
        var has_month = False
        var has_day = False
        var parsed_weekday_name = 0
        var hour = 0
        var minute = 0
        var second = 0
        var microsecond = 0
        var tz = Self._utc_timezone()
        var am_pm = 0

        var date_pos = date_start
        var fmt_pos = 0
        while fmt_pos < fmt.byte_length():
            if fmt[byte=fmt_pos] == "[":
                var literal_start = fmt_pos + 1
                var literal_end = literal_start
                while literal_end < fmt.byte_length() and ord(
                    fmt[byte=literal_end]
                ) != ord("]"):
                    literal_end += 1
                if literal_end >= fmt.byte_length():
                    raise Error("format literal is missing closing bracket")

                if Self._is_whitespace_regex_literal(
                    fmt, literal_start, literal_end
                ):
                    date_pos = Self._parse_whitespace_regex(date_str, date_pos)
                elif Self._is_optional_whitespace_regex_literal(
                    fmt, literal_start, literal_end
                ):
                    date_pos = Self._parse_optional_whitespace_regex(
                        date_str, date_pos
                    )
                else:
                    var literal_pos = literal_start
                    while literal_pos < literal_end:
                        Self._parse_literal_char(
                            date_str, date_pos, fmt, literal_pos
                        )
                        date_pos += 1
                        literal_pos += 1
                fmt_pos = literal_end + 1
            elif Self._starts_with(fmt, fmt_pos, "YYYY"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 4)
                year = parsed.value
                has_year = True
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "YY"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                year = Self._parse_two_digit_year(parsed.value)
                has_year = True
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "MMMM"):
                var parsed = Self._parse_month_name(date_str, date_pos, False)
                month = parsed.value
                has_month = True
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "MMM"):
                var parsed = Self._parse_month_name(date_str, date_pos, True)
                month = parsed.value
                has_month = True
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "MM"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                month = parsed.value
                has_month = True
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "M"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                month = parsed.value
                has_month = True
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "DDDD"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 3)
                day_of_year = parsed.value
                has_day = True
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "DDD"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 3)
                day_of_year = parsed.value
                has_day = True
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "Do"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                day = parsed.value
                has_day = True
                date_pos = parsed.pos
                date_pos = Self._parse_ordinal_suffix(date_str, date_pos, day)
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "DD"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                day = parsed.value
                has_day = True
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "D"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                day = parsed.value
                has_day = True
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "W"):
                var parsed = Self._parse_iso_week_date(date_str, date_pos)
                var date = Self.fromisocalendar(
                    parsed.year, parsed.week, parsed.weekday
                )
                year = date.year
                month = date.month
                day = date.day
                has_year = True
                has_month = True
                has_day = True
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "dddd"):
                var parsed = Self._parse_weekday_name(date_str, date_pos, False)
                parsed_weekday_name = parsed.value
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "ddd"):
                var parsed = Self._parse_weekday_name(date_str, date_pos, True)
                parsed_weekday_name = parsed.value
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "d"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 1)
                if parsed.value < 1 or parsed.value > 7:
                    raise Error("weekday must be in 1..7")
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "HH"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                hour = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "H"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                hour = parsed.value
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "hh"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                hour = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "h"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                hour = parsed.value
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "mm"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                minute = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "m"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                minute = parsed.value
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "ss"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                second = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "s"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                second = parsed.value
                date_pos = parsed.pos
                fmt_pos += 1
            elif fmt[byte=fmt_pos] == "S":
                var token_end = fmt_pos
                while (
                    token_end < fmt.byte_length() and fmt[byte=token_end] == "S"
                ):
                    token_end += 1
                var parsed = Self._parse_subsecond(
                    date_str, date_pos, token_end - fmt_pos
                )
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos = token_end
            elif Self._starts_with(fmt, fmt_pos, "X"):
                if fmt_pos + 1 != fmt.byte_length():
                    raise Error("timestamp token must be the full format")
                var timestamp_str = String(date_str[byte=date_pos:])
                Self._validate_timestamp_seconds_token(timestamp_str)
                var parsed = Self.utcfromtimestamp(timestamp_str)
                if not tzinfo.is_none():
                    return parsed.replace(tzinfo=tzinfo)
                return parsed
            elif Self._starts_with(fmt, fmt_pos, "x"):
                if fmt_pos + 1 != fmt.byte_length():
                    raise Error("timestamp token must be the full format")
                var timestamp_str = String(date_str[byte=date_pos:])
                Self._validate_expanded_timestamp_token(timestamp_str)
                var parsed = Self._from_expanded_timestamp_value(
                    Int(timestamp_str)
                )
                if not tzinfo.is_none():
                    return parsed.replace(tzinfo=tzinfo)
                return parsed
            elif Self._starts_with(fmt, fmt_pos, "ZZZ"):
                var parsed = Self._parse_timezone_name(date_str, date_pos)
                tz = parsed.tz
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "ZZ"):
                var parsed = Self._parse_timezone_offset(
                    date_str, date_pos, True
                )
                tz = parsed.tz
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "Z"):
                var parsed = Self._parse_timezone_offset(
                    date_str, date_pos, False
                )
                tz = parsed.tz
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "A"):
                date_pos = Self._parse_am_pm(date_str, date_pos, True)
                am_pm = 2 if Self._last_am_pm_was_pm(date_str, date_pos) else 1
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "a"):
                date_pos = Self._parse_am_pm(date_str, date_pos, False)
                am_pm = 2 if Self._last_am_pm_was_pm(date_str, date_pos) else 1
                fmt_pos += 1
            else:
                Self._parse_literal_char(date_str, date_pos, fmt, fmt_pos)
                date_pos += 1
                fmt_pos += 1

        if allow_trailing_text:
            if not Self._has_right_parse_boundary(date_str, date_pos):
                raise Error("date string does not match format boundary")
        elif date_pos != date_str.byte_length():
            raise Error("date string has trailing data")
        if am_pm == 1:
            if hour > 12:
                raise Error("hour must be in 0..12 for AM")
            if hour == 12:
                hour = 0
        elif am_pm == 2:
            if hour < 12:
                hour += 12
        if day_of_year != -1:
            if not has_year:
                raise Error("year component is required with day of year")
            if day_of_year < 1 or day_of_year > 366:
                raise Error("day of year is invalid")
            var date = Self.fromordinal(_ymd2ord(year, 1, 1) + day_of_year - 1)
            year = date.year
            month = date.month
            day = date.day
        elif parsed_weekday_name != 0 and not has_day:
            if not has_year:
                year = 1970
            if not has_month:
                month = 1
            Self._validate_fields(year, month, 1, 0, 0, 0, 0)
            var first_day = Self(year, month, 1)
            var weekday_offset = parsed_weekday_name - first_day.isoweekday()
            if weekday_offset < 0:
                weekday_offset += 7
            var date = first_day.shift(days=weekday_offset)
            year = date.year
            month = date.month
            day = date.day
        if microsecond >= _US_PER_SECOND:
            second += microsecond // _US_PER_SECOND
            microsecond = microsecond % _US_PER_SECOND
        var midnight_end_of_day = False
        if hour == 24:
            if minute != 0:
                raise Error(
                    "midnight at the end of day must not contain minutes"
                )
            if second != 0:
                raise Error(
                    "midnight at the end of day must not contain seconds"
                )
            if microsecond != 0:
                raise Error(
                    "midnight at the end of day must not contain microseconds"
                )
            hour = 0
            midnight_end_of_day = True
        if not tzinfo.is_none():
            tz = tzinfo
        Self._validate_fields(
            year, month, day, hour, minute, second, microsecond
        )
        var parsed = Self(
            year, month, day, hour, minute, second, microsecond, tz
        )
        if midnight_end_of_day:
            return parsed.shift(days=1)
        return parsed

    @staticmethod
    def _parse_arrow_formats(
        date_str: String,
        formats: List[String],
        tzinfo: TimeZone = TimeZone.none(),
    ) raises -> Self:
        for i in range(len(formats)):
            try:
                return Self._parse_arrow(date_str, formats[i], tzinfo)
            except e:
                pass
        raise Error("date string does not match any format")

    @staticmethod
    def fromdate(date: MorrowDate) -> Self:
        """
        Construct a Morrow from a date view. Time fields are set to zero.
        """
        return Self.fromdate(date, Self._utc_timezone())

    @staticmethod
    def fromdate(date: MorrowDate, tz: TimeZone) -> Self:
        """
        Construct a Morrow from a date view and replacement timezone.
        """
        return Self(date.year, date.month, date.day, tz=tz)

    @staticmethod
    def fromdate(date: MorrowDate, tz_str: String) raises -> Self:
        """
        Construct a Morrow from a date view and parsed replacement timezone.
        """
        return Self.fromdate(date, Self._parse_timezone_argument(tz_str))

    @staticmethod
    def fromdatetime(dt: Self) -> Self:
        """
        Construct a Morrow from another Morrow object.
        """
        if dt.tz.is_none():
            return Self.fromdatetime(dt, Self._utc_timezone())
        return dt.clone()

    @staticmethod
    def fromdatetime(dt: Self, tz: TimeZone) -> Self:
        """
        Construct a Morrow from another Morrow object and replacement timezone.
        """
        return Self(
            dt.year,
            dt.month,
            dt.day,
            dt.hour,
            dt.minute,
            dt.second,
            dt.microsecond,
            tz,
        )

    @staticmethod
    def fromdatetime(dt: Self, tz_str: String) raises -> Self:
        """
        Construct a Morrow from another Morrow object and parsed replacement timezone.
        """
        return Self.fromdatetime(dt, Self._parse_timezone_argument(tz_str))

    @staticmethod
    def strptime(
        date_str: String, fmt: String, tzinfo: TimeZone = TimeZone.none()
    ) raises -> Self:
        """
        Create a Morrow instance from a date string and format,
        in the style of ``datetime.strptime``.  Optionally replaces the parsed TimeZone.

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S')
            <Morrow [2019-01-20T15:49:10+00:00]>
        """
        var normalized_date = date_str
        var normalized_fmt = fmt
        var microsecond = 0
        var parsed_tz = TimeZone.none()

        while True:
            var directive = Self._find_strptime_extension_directive(
                normalized_fmt
            )
            if directive.pos == -1:
                break

            var prefix_fmt = String(normalized_fmt[byte = 0 : directive.pos])
            var value_start = c_strptime_consumed(normalized_date, prefix_fmt)
            var value_end: Int
            if directive.value == ord("f"):
                value_end = value_start
                while (
                    value_end < normalized_date.byte_length()
                    and Self._is_ascii_digit(
                        ord(normalized_date[byte=value_end])
                    )
                    and value_end - value_start < 6
                ):
                    value_end += 1
                if value_end == value_start:
                    raise Error("microsecond is missing")
                if (
                    value_end < normalized_date.byte_length()
                    and Self._is_ascii_digit(
                        ord(normalized_date[byte=value_end])
                    )
                ):
                    raise Error("unconverted data remains")

                var digits = String(normalized_date[byte=value_start:value_end])
                while digits.byte_length() < 6:
                    digits += "0"
                microsecond = Int(digits)
            elif directive.value == ord("z"):
                var parsed = Self._parse_strptime_timezone_offset(
                    normalized_date, value_start
                )
                value_end = parsed.pos
                parsed_tz = parsed.tz
            else:
                var parsed = Self._parse_strptime_timezone_name(
                    normalized_date, value_start
                )
                value_end = parsed.pos
                parsed_tz = parsed.tz

            normalized_date = String(
                normalized_date[byte=0:value_start]
            ) + String(normalized_date[byte=value_end:])
            normalized_fmt = prefix_fmt + String(
                normalized_fmt[byte = directive.pos + 2 :]
            )

        var tm = c_strptime(normalized_date, normalized_fmt)
        return Self._from_strptime_tm(tm, microsecond, tzinfo, parsed_tz)

    @staticmethod
    def _from_strptime_tm(
        tm: CTm,
        microsecond: Int,
        tzinfo: TimeZone,
        parsed_tz: TimeZone = TimeZone.none(),
    ) raises -> Self:
        var tz: TimeZone
        if not tzinfo.is_none():
            tz = tzinfo
        elif not parsed_tz.is_none():
            tz = parsed_tz
        else:
            tz = TimeZone(Int(tm.tm_gmtoff))
        return Self._from_components(
            Int(tm.tm_year) + 1900,
            Int(tm.tm_mon) + 1,
            Int(tm.tm_mday),
            Int(tm.tm_hour),
            Int(tm.tm_min),
            Int(tm.tm_sec),
            microsecond,
            tz,
        )

    @staticmethod
    def _find_strptime_extension_directive(fmt: String) -> MorrowParseInt:
        var pos = 0
        while pos + 1 < fmt.byte_length():
            if fmt[byte=pos] == "%":
                if fmt[byte=pos + 1] == "%":
                    pos += 2
                    continue
                if (
                    fmt[byte=pos + 1] == "f"
                    or fmt[byte=pos + 1] == "z"
                    or fmt[byte=pos + 1] == "Z"
                ):
                    return MorrowParseInt(ord(fmt[byte=pos + 1]), pos)
                pos += 2
            else:
                pos += 1
        return MorrowParseInt(0, -1)

    @staticmethod
    def _parse_strptime_timezone_name(
        date_str: String, date_pos: Int
    ) raises -> MorrowParseTimeZone:
        if Self._starts_with_ascii_case_insensitive(date_str, date_pos, "UTC"):
            return MorrowParseTimeZone(Self._utc_timezone(), date_pos + 3)
        if Self._starts_with_ascii_case_insensitive(date_str, date_pos, "GMT"):
            return MorrowParseTimeZone(Self._utc_timezone(), date_pos + 3)
        if date_pos >= date_str.byte_length():
            raise Error("timezone is missing")
        raise Error("timezone name is invalid")

    @staticmethod
    def _parse_strptime_timezone_offset(
        date_str: String, date_pos: Int
    ) raises -> MorrowParseTimeZone:
        if date_pos >= date_str.byte_length():
            raise Error("timezone is missing")
        if date_str[byte=date_pos] == "Z":
            return MorrowParseTimeZone(TimeZone.from_utc("UTC"), date_pos + 1)

        var sign = 1
        if date_str[byte=date_pos] == "-":
            sign = -1
        elif not date_str[byte=date_pos] == "+":
            raise Error("timezone must be Z or a fixed offset")

        var pos = date_pos + 1
        if (
            pos + 2 > date_str.byte_length()
            or not Self._is_ascii_digit(ord(date_str[byte=pos]))
            or not Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
        ):
            raise Error("timezone hour is invalid")
        var hours = Int(date_str[byte = pos : pos + 2])
        pos += 2

        var minutes: Int
        var seconds = 0
        if pos < date_str.byte_length() and date_str[byte=pos] == ":":
            pos += 1
            if (
                pos + 2 > date_str.byte_length()
                or not Self._is_ascii_digit(ord(date_str[byte=pos]))
                or not Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
            ):
                raise Error("timezone minute is invalid")
            minutes = Int(date_str[byte = pos : pos + 2])
            pos += 2
            if pos < date_str.byte_length() and date_str[byte=pos] == ":":
                pos += 1
                if (
                    pos + 2 > date_str.byte_length()
                    or not Self._is_ascii_digit(ord(date_str[byte=pos]))
                    or not Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
                ):
                    raise Error("timezone second is invalid")
                seconds = Int(date_str[byte = pos : pos + 2])
                pos += 2
        else:
            if (
                pos + 2 > date_str.byte_length()
                or not Self._is_ascii_digit(ord(date_str[byte=pos]))
                or not Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
            ):
                raise Error("timezone minute is invalid")
            minutes = Int(date_str[byte = pos : pos + 2])
            pos += 2
            if (
                pos + 2 <= date_str.byte_length()
                and Self._is_ascii_digit(ord(date_str[byte=pos]))
                and Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
            ):
                seconds = Int(date_str[byte = pos : pos + 2])
                pos += 2

        if minutes > 59:
            raise Error("timezone minute is invalid")
        if seconds > 59:
            raise Error("timezone second is invalid")
        var offset = sign * (hours * 3600 + minutes * 60 + seconds)
        if offset <= -86400 or offset >= 86400:
            raise Error(
                "timezone offset must be strictly between -24:00 and +24:00"
            )
        return MorrowParseTimeZone(TimeZone(offset), pos)

    @staticmethod
    def strptime(date_str: String, fmt: String, tz_str: String) raises -> Self:
        """
        Create a Morrow instance by time_zone_string with utc format.

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S', '+08:00')
            <Morrow [2019-01-20T15:49:10+08:00]>
        """
        var tzinfo = Self._parse_timezone_argument(tz_str)
        return Self.strptime(date_str, fmt, tzinfo)

    def clone(self) -> Self:
        """
        Return a copy of this Morrow.
        """
        return Self(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
            self.tz,
        )

    def datetime(self) -> Self:
        """
        Return a datetime representation of this Morrow.
        """
        return self.clone()

    def naive(self) -> Self:
        """
        Return a copy without timezone information.
        """
        return Self(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
            TimeZone.none(),
        )

    def timestamp(self) raises -> Float64:
        """
        Return the POSIX timestamp for this Morrow as UTC seconds.
        """
        return Float64(self._utc_microseconds()) / 1000000.0

    def float_timestamp(self) raises -> Float64:
        """
        Return the POSIX timestamp for this Morrow as a floating point value.
        """
        return self.timestamp()

    def int_timestamp(self) raises -> Int:
        """
        Return the POSIX timestamp for this Morrow as integer UTC seconds.
        """
        var total_us = self._utc_microseconds()
        if total_us < 0:
            return -((-total_us) // _US_PER_SECOND)
        return total_us // _US_PER_SECOND

    def for_json(self) raises -> String:
        """
        Return an ISO 8601 string for JSON serialization.
        """
        return self.isoformat()

    def quarter(self) -> Int:
        """
        Return the calendar quarter as an integer in 1..4.
        """
        return (self.month - 1) // 3 + 1

    def week(self) raises -> Int:
        """
        Return the ISO week number.
        """
        return self.isocalendar().week

    def ctime(self) raises -> String:
        """
        Return a ctime formatted representation of the date and time.
        """
        return (
            day_abbreviation(self.isoweekday())
            + " "
            + month_abbreviation(self.month)
            + " "
            + String(self.day).ascii_rjust(2, " ")
            + " "
            + String(self.hour).ascii_rjust(2, "0")
            + ":"
            + String(self.minute).ascii_rjust(2, "0")
            + ":"
            + String(self.second).ascii_rjust(2, "0")
            + " "
            + String(self.year).ascii_rjust(4, "0")
        )

    def date(self) -> MorrowDate:
        """
        Return the date components.
        """
        return MorrowDate(self.year, self.month, self.day)

    def time(self) -> MorrowTime:
        """
        Return the time components without timezone information.
        """
        return MorrowTime(
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
            TimeZone.none(),
        )

    def timetz(self) -> MorrowTime:
        """
        Return the time components with timezone information.
        """
        return MorrowTime(
            self.hour, self.minute, self.second, self.microsecond, self.tz
        )

    def tzinfo(self) -> TimeZone:
        """
        Return this Morrow's timezone.
        """
        return self.tz

    def tzname(self) -> String:
        """
        Return this Morrow's timezone name.
        """
        if self.tz.is_none():
            return ""
        if (
            self.tz.name.byte_length() > 0
            and self.tz.name != "utc"
            and self.tz.name != "UTC"
        ):
            return self.tz.name
        if self.tz.offset == 0:
            return "UTC"
        return "UTC" + self.tz.format()

    def utcoffset(self) -> TimeDelta:
        """
        Return this Morrow's fixed UTC offset.
        """
        return TimeDelta(seconds=self.tz.offset)

    def dst(self) -> TimeDelta:
        """
        Return daylight-saving offset. Fixed-offset timezones have none.
        """
        return TimeDelta()

    def fold(self) -> Int:
        """
        Return the fold value. Fixed-offset timezones do not repeat wall times.
        """
        return 0

    def ambiguous(self) -> Bool:
        """
        Return whether this wall time is ambiguous in its timezone.
        """
        return False

    def imaginary(self) -> Bool:
        """
        Return whether this wall time is nonexistent in its timezone.
        """
        return False

    def timetuple(self) raises -> MorrowTimeTuple:
        """
        Return local date and time fields in Python struct_time style.
        """
        return self._time_tuple()

    def utctimetuple(self) raises -> MorrowTimeTuple:
        """
        Return UTC date and time fields in Python struct_time style.
        """
        return self.to("UTC")._time_tuple()

    def humanize(
        self,
    ) raises -> String:
        """
        Return an English human-readable relative difference from now.
        """
        return self.humanize(Self.utcnow())

    def humanize(
        self,
        only_distance: Bool,
    ) raises -> String:
        """
        Return an English human-readable relative difference from now.
        """
        return self.humanize(Self.utcnow(), only_distance)

    def humanize(
        self,
        other: Self,
        only_distance: Bool = False,
        granularity: String = "auto",
    ) raises -> String:
        """
        Return an English human-readable relative difference.
        """
        var delta_us = self._utc_microseconds() - other._utc_microseconds()
        var unit = granularity
        if unit != "auto":
            _ = Self._humanize_unit_seconds(unit)

        if delta_us == 0:
            if only_distance:
                return "instantly"
            return "just now"

        var rounded_delta_seconds = Self._rounded_seconds(delta_us)
        var seconds = abs(rounded_delta_seconds)
        if unit == "auto":
            return self._humanize_auto(other, delta_us, only_distance)
        if unit == "second" and seconds < 2:
            if only_distance:
                return "instantly"
            return "just now"
        var count = Self._humanize_count(seconds, unit)
        return Self._format_humanize_result(
            rounded_delta_seconds, count, unit, only_distance
        )

    def humanize(self, other: Self, granularity: List[String]) raises -> String:
        """
        Return an English human-readable relative difference with multiple granularities.
        """
        return self.humanize(other, False, granularity)

    def humanize(
        self,
        other: Self,
        only_distance: Bool,
        granularity: List[String],
    ) raises -> String:
        """
        Return an English human-readable relative difference with multiple granularities.
        """
        if len(granularity) == 0:
            raise Error("granularity cannot be empty")
        if len(granularity) == 1 and granularity[0] == "auto":
            return self.humanize(other, only_distance)

        var ordered_granularity = Self._normalize_humanize_granularity_list(
            granularity
        )
        var delta_us = self._utc_microseconds() - other._utc_microseconds()
        var rounded_delta_seconds = Self._rounded_seconds(delta_us)
        var remaining = abs(rounded_delta_seconds)
        if (
            len(ordered_granularity) == 1
            and ordered_granularity[0] == "second"
            and remaining < 2
        ):
            if only_distance:
                return "instantly"
            return "just now"

        var parts = List[String]()
        for i in range(len(ordered_granularity)):
            var unit = ordered_granularity[i]
            var unit_seconds = Self._humanize_unit_seconds(unit)
            var count = remaining // unit_seconds
            parts.append(Self._format_humanize_distance(count, unit))
            remaining = remaining % unit_seconds

        var distance = Self._join_humanize_parts(parts)
        if only_distance:
            return distance
        if rounded_delta_seconds >= 0:
            return "in " + distance
        return distance + " ago"

    def dehumanize(self, input_string: String) raises -> Self:
        """
        Shift this Morrow by an English human-readable relative difference.
        """
        if input_string == "just now":
            return self

        var future: Bool
        var phrase: String
        if input_string.byte_length() > 3 and input_string[byte=0:3] == "in ":
            future = True
            phrase = String(input_string[byte=3:])
        elif (
            input_string.byte_length() > 4
            and input_string[byte = input_string.byte_length() - 4 :] == " ago"
        ):
            future = False
            phrase = String(
                input_string[byte = 0 : input_string.byte_length() - 4]
            )
        else:
            raise Error(
                "humanized string must start with 'in ' or end with ' ago'"
            )

        var result = self
        var parsed = False
        var pos = 0
        while pos < phrase.byte_length():
            while pos < phrase.byte_length() and phrase[byte=pos] == " ":
                pos += 1
            if pos >= phrase.byte_length():
                break

            var word_start = pos
            while pos < phrase.byte_length() and ord(phrase[byte=pos]) != ord(
                " "
            ):
                pos += 1
            var count_word = String(phrase[byte=word_start:pos])
            if count_word == "and":
                continue

            var count: Int
            if count_word == "a" or count_word == "an":
                count = 1
            else:
                count = Int(count_word)

            while pos < phrase.byte_length() and phrase[byte=pos] == " ":
                pos += 1
            if pos >= phrase.byte_length():
                raise Error("humanized distance is invalid")

            var unit_start = pos
            while pos < phrase.byte_length() and ord(phrase[byte=pos]) != ord(
                " "
            ):
                pos += 1
            var unit = Self._normalize_dehumanize_unit(
                count_word, count, String(phrase[byte=unit_start:pos])
            )
            if not future:
                count = -count
            result = result._shift_humanize_unit(unit, count)
            parsed = True

        if not parsed:
            raise Error("humanized distance is invalid")
        return result

    def to(self, tz: TimeZone) raises -> Self:
        """
        Return this instant converted to a fixed-offset timezone.
        """
        var shifted = self.shift(seconds=tz.offset - self.tz.offset)
        return Self(
            shifted.year,
            shifted.month,
            shifted.day,
            shifted.hour,
            shifted.minute,
            shifted.second,
            shifted.microsecond,
            tz,
        )

    def to(self, tz_str: String) raises -> Self:
        """
        Return this instant converted to a timezone parsed from a UTC offset string.
        """
        return self.to(Self._parse_timezone_argument(tz_str))

    def astimezone(self, tz: TimeZone) raises -> Self:
        """
        Return this instant converted to a fixed-offset timezone.
        """
        return self.to(tz)

    def astimezone(self, tz_str: String) raises -> Self:
        """
        Return this instant converted to a timezone parsed from a UTC offset string.
        """
        return self.to(tz_str)

    def replace(
        self,
        year: Int = -1,
        month: Int = -1,
        day: Int = -1,
        hour: Int = -1,
        minute: Int = -1,
        second: Int = -1,
        microsecond: Int = -1,
        tzinfo: TimeZone = TimeZone.none(),
    ) raises -> Self:
        """
        Return a new Morrow with selected fields replaced.
        """
        var year_ = self.year if year == -1 else year
        var month_ = self.month if month == -1 else month
        var day_ = self.day if day == -1 else day
        var hour_ = self.hour if hour == -1 else hour
        var minute_ = self.minute if minute == -1 else minute
        var second_ = self.second if second == -1 else second
        var microsecond_ = (
            self.microsecond if microsecond == -1 else microsecond
        )
        var tzinfo_ = self.tz if tzinfo.is_none() else tzinfo
        Self._validate_fields(
            year_, month_, day_, hour_, minute_, second_, microsecond_
        )
        return Self(
            year_, month_, day_, hour_, minute_, second_, microsecond_, tzinfo_
        )

    def replace(
        self,
        tzinfo: String,
        year: Int = -1,
        month: Int = -1,
        day: Int = -1,
        hour: Int = -1,
        minute: Int = -1,
        second: Int = -1,
        microsecond: Int = -1,
    ) raises -> Self:
        """
        Return a new Morrow with timezone parsed and replaced without conversion.
        """
        return self.replace(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            Self._parse_timezone_argument(tzinfo),
        )

    def shift(
        self,
        years: Int = 0,
        months: Int = 0,
        quarters: Int = 0,
        weeks: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        microseconds: Int = 0,
        weekday: Int = -9999,
    ) raises -> Self:
        """
        Return a new Morrow shifted by relative date and time offsets.
        """
        if weekday != -9999 and (weekday < -7 or weekday > 6):
            raise Error("weekday must be in -7..6")
        var total_months = (
            self.year * 12
            + (self.month - 1)
            + years * 12
            + quarters * 3
            + months
        )
        var year = total_months // 12
        var month = total_months % 12 + 1
        if month < 1:
            month += 12
            year -= 1
        var max_day = _days_in_month(year, month)
        var day = self.day if self.day <= max_day else max_day
        Self._validate_fields(
            year,
            month,
            day,
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
        )
        var shifted = Self(
            year,
            month,
            day,
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
            self.tz,
        )
        var day_offset = weeks * 7 + days
        if weekday != -9999:
            var target_weekday = weekday
            if target_weekday < 0:
                target_weekday += 7
            var current_weekday = shifted.weekday()
            var weekday_offset = target_weekday - current_weekday
            if weekday_offset < 0:
                weekday_offset += 7
            day_offset += weekday_offset
        return shifted._shift_day_time(
            day_offset, hours, minutes, seconds, microseconds
        )

    def span(
        self,
        frame: String,
        count: Int = 1,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> MorrowSpan:
        """
        Return the start and end of this Morrow's span in a given timeframe.
        """
        Self._validate_bounds(bounds)

        var start = self if exact else self._floor_frame(frame, week_start)
        var end = start._shift_frame(frame, count)
        return Self._span_from_bounds(start, end, bounds)

    def floor(self, frame: String, week_start: Int = 1) raises -> Self:
        """
        Return the start of this Morrow's span in a given timeframe.
        """
        return self._floor_frame(frame, week_start)

    def ceil(self, frame: String, week_start: Int = 1) raises -> Self:
        """
        Return the end of this Morrow's span in a given timeframe.
        """
        return self.span(frame, week_start=week_start).end

    @staticmethod
    def range(
        frame: String,
        start: Self,
        end: Self,
        limit: Int = _UNBOUNDED_LIMIT,
    ) raises -> List[Self]:
        """
        Return points in time between start and end, stepping by frame.
        """
        var items = List[Self]()
        var current = start
        var original_day = start.day
        var emitted = 0
        while current._utc_microseconds() <= end._utc_microseconds():
            if limit != _UNBOUNDED_LIMIT and emitted >= limit:
                break
            items.append(current)
            current = current._shift_frame_preserving_day(
                frame, 1, original_day
            )
            emitted += 1
        return items^

    @staticmethod
    def range(frame: String, start: Self, limit: Int) raises -> List[Self]:
        """
        Return a limited number of points starting at start.
        """
        var items = List[Self]()
        if limit <= 0:
            return items^
        var current = start
        var original_day = start.day
        var emitted = 0
        while emitted < limit:
            items.append(current)
            current = current._shift_frame_preserving_day(
                frame, 1, original_day
            )
            emitted += 1
        return items^

    @staticmethod
    def range(
        frame: String,
        start: Self,
        end: Self,
        tz: TimeZone,
        limit: Int = _UNBOUNDED_LIMIT,
    ) raises -> List[Self]:
        """
        Return points after replacing start and end timezones.
        """
        return Self.range(
            frame, start.replace(tzinfo=tz), end.replace(tzinfo=tz), limit
        )

    @staticmethod
    def range(
        frame: String,
        start: Self,
        end: Self,
        tz_str: String,
        limit: Int = _UNBOUNDED_LIMIT,
    ) raises -> List[Self]:
        """
        Return points after replacing start and end with a parsed timezone.
        """
        return Self.range(
            frame, start, end, Self._parse_timezone_argument(tz_str), limit
        )

    @staticmethod
    def range(
        frame: String,
        start: Self,
        tz: TimeZone,
        limit: Int,
    ) raises -> List[Self]:
        """
        Return a limited number of points after replacing the start timezone.
        """
        return Self.range(frame, start.replace(tzinfo=tz), limit)

    @staticmethod
    def range(
        frame: String,
        start: Self,
        tz_str: String,
        limit: Int,
    ) raises -> List[Self]:
        """
        Return a limited number of points after replacing the start with a parsed timezone.
        """
        return Self.range(
            frame, start, Self._parse_timezone_argument(tz_str), limit
        )

    @staticmethod
    def span_range(
        frame: String,
        start: Self,
        end: Self,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return spans between start and end.
        """
        return Self._span_range(
            frame, start, end, 1, limit, bounds, exact, week_start
        )

    @staticmethod
    def span_range(
        frame: String,
        start: Self,
        end: Self,
        tz: TimeZone,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return spans after replacing start and end timezones.
        """
        return Self.span_range(
            frame,
            start.replace(tzinfo=tz),
            end.replace(tzinfo=tz),
            limit,
            bounds,
            exact,
            week_start,
        )

    @staticmethod
    def span_range(
        frame: String,
        start: Self,
        end: Self,
        tz_str: String,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return spans after replacing start and end with a parsed timezone.
        """
        return Self.span_range(
            frame,
            start,
            end,
            Self._parse_timezone_argument(tz_str),
            limit,
            bounds,
            exact,
            week_start,
        )

    @staticmethod
    def interval(
        frame: String,
        start: Self,
        end: Self,
        interval: Int = 1,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return spans between start and end, grouping each span by interval frames.
        """
        return Self._span_range(
            frame, start, end, interval, limit, bounds, exact, week_start
        )

    @staticmethod
    def interval(
        frame: String,
        start: Self,
        end: Self,
        interval: Int,
        tz: TimeZone,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return grouped spans after replacing start and end timezones.
        """
        return Self.interval(
            frame,
            start.replace(tzinfo=tz),
            end.replace(tzinfo=tz),
            interval,
            limit,
            bounds,
            exact,
            week_start,
        )

    @staticmethod
    def interval(
        frame: String,
        start: Self,
        end: Self,
        interval: Int,
        tz_str: String,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return grouped spans after replacing start and end with a parsed timezone.
        """
        return Self.interval(
            frame,
            start,
            end,
            interval,
            Self._parse_timezone_argument(tz_str),
            limit,
            bounds,
            exact,
            week_start,
        )

    @staticmethod
    def _span_range(
        frame: String,
        start: Self,
        end: Self,
        interval: Int,
        limit: Int,
        bounds: String,
        exact: Bool,
        week_start: Int,
    ) raises -> List[MorrowSpan]:
        if interval < 1:
            raise Error("interval must be greater than 0")
        Self._validate_bounds(bounds)

        var spans = List[MorrowSpan]()
        var emitted = 0
        var end_key = end._utc_microseconds()
        var current = start if exact else start._floor_frame(frame, week_start)
        var original_day = start.day

        while current._utc_microseconds() <= end_key:
            if exact and current._utc_microseconds() >= end_key:
                break
            if limit != _UNBOUNDED_LIMIT and emitted >= limit:
                break

            if exact:
                var next = current._shift_frame_preserving_day(
                    frame, interval, original_day
                )
                var raw_end = next
                if raw_end._utc_microseconds() > end_key:
                    raw_end = end
                spans.append(Self._span_from_bounds(current, raw_end, bounds))
                current = next
            else:
                spans.append(
                    current.span(
                        frame,
                        count=interval,
                        bounds=bounds,
                        week_start=week_start,
                    )
                )
                current = current._shift_frame(frame, interval)
            emitted += 1

        return spans^

    @staticmethod
    def _span_from_bounds(
        start: Self, end: Self, bounds: String
    ) raises -> MorrowSpan:
        var start_ = start
        var end_ = end
        if ord(bounds[byte=0]) == 40:  # (
            start_ = start_.shift(microseconds=1)
        if ord(bounds[byte=1]) == 41:  # )
            end_ = end_.shift(microseconds=-1)
        return MorrowSpan(start_, end_)

    def is_between(
        self, start: Self, end: Self, bounds: String = "()"
    ) raises -> Bool:
        """
        Return True when this Morrow is between start and end.
        """
        Self._validate_bounds(bounds)
        var value = self._utc_microseconds()
        var low = start._utc_microseconds()
        var high = end._utc_microseconds()

        var left: Bool
        if ord(bounds[byte=0]) == 91:  # [
            left = value >= low
        else:
            left = value > low

        var right: Bool
        if ord(bounds[byte=1]) == 93:  # ]
            right = value <= high
        else:
            right = value < high

        return left and right

    @staticmethod
    def _validate_bounds(bounds: String) raises:
        if bounds.byte_length() != 2:
            raise Error("bounds must be one of [), [], (), (]")
        var left = ord(bounds[byte=0])
        var right = ord(bounds[byte=1])
        if (left != 91 and left != 40) or (right != 93 and right != 41):
            raise Error("bounds must be one of [), [], (), (]")

    def _floor_frame(self, frame: String, week_start: Int = 1) raises -> Self:
        if frame == "year" or frame == "years":
            return Self(self.year, 1, 1, 0, 0, 0, 0, self.tz)
        elif frame == "quarter" or frame == "quarters":
            var month = ((self.month - 1) // 3) * 3 + 1
            return Self(self.year, month, 1, 0, 0, 0, 0, self.tz)
        elif frame == "month" or frame == "months":
            return Self(self.year, self.month, 1, 0, 0, 0, 0, self.tz)
        elif frame == "week" or frame == "weeks":
            if week_start < 1 or week_start > 7:
                raise Error("week_start must be in 1..7")
            var offset = self.isoweekday() - week_start
            if offset < 0:
                offset += 7
            return Self(
                self.year, self.month, self.day, 0, 0, 0, 0, self.tz
            )._shift_day_time(-offset, 0, 0, 0, 0)
        elif frame == "day" or frame == "days":
            return Self(self.year, self.month, self.day, 0, 0, 0, 0, self.tz)
        elif frame == "hour" or frame == "hours":
            return Self(
                self.year, self.month, self.day, self.hour, 0, 0, 0, self.tz
            )
        elif frame == "minute" or frame == "minutes":
            return Self(
                self.year,
                self.month,
                self.day,
                self.hour,
                self.minute,
                0,
                0,
                self.tz,
            )
        elif frame == "second" or frame == "seconds":
            return Self(
                self.year,
                self.month,
                self.day,
                self.hour,
                self.minute,
                self.second,
                0,
                self.tz,
            )
        elif frame == "microsecond" or frame == "microseconds":
            return self
        else:
            raise Error("unsupported frame")

    def _shift_frame(self, frame: String, count: Int) raises -> Self:
        if frame == "year" or frame == "years":
            return self.shift(years=count)
        elif frame == "quarter" or frame == "quarters":
            return self.shift(months=count * 3)
        elif frame == "month" or frame == "months":
            return self.shift(months=count)
        elif frame == "week" or frame == "weeks":
            return self.shift(weeks=count)
        elif frame == "day" or frame == "days":
            return self.shift(days=count)
        elif frame == "hour" or frame == "hours":
            return self.shift(hours=count)
        elif frame == "minute" or frame == "minutes":
            return self.shift(minutes=count)
        elif frame == "second" or frame == "seconds":
            return self.shift(seconds=count)
        elif frame == "microsecond" or frame == "microseconds":
            return self.shift(microseconds=count)
        else:
            raise Error("unsupported frame")

    def _shift_frame_preserving_day(
        self, frame: String, count: Int, original_day: Int
    ) raises -> Self:
        var shifted = self._shift_frame(frame, count)
        if (
            frame == "year"
            or frame == "years"
            or frame == "quarter"
            or frame == "quarters"
            or frame == "month"
            or frame == "months"
        ):
            if shifted.day < original_day and original_day <= _days_in_month(
                shifted.year, shifted.month
            ):
                return shifted.replace(day=original_day)
        return shifted

    @staticmethod
    def _validate_fields(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        microsecond: Int,
    ) raises:
        if year < 1 or year > 9999:
            raise Error("year must be in 1..9999")
        if month < 1 or month > 12:
            raise Error("month must be in 1..12")
        if day < 1 or day > _days_in_month(year, month):
            raise Error("day is out of range for month")
        if hour < 0 or hour > 23:
            raise Error("hour must be in 0..23")
        if minute < 0 or minute > 59:
            raise Error("minute must be in 0..59")
        if second < 0 or second > 59:
            raise Error("second must be in 0..59")
        if microsecond < 0 or microsecond >= _US_PER_SECOND:
            raise Error("microsecond must be in 0..999999")

    @staticmethod
    def _utc_timezone() -> TimeZone:
        return TimeZone(0, "utc")

    @staticmethod
    def _parse_timezone_argument(tz_str: String) raises -> TimeZone:
        if tz_str == "local":
            return TimeZone.local()
        return TimeZone.from_utc(tz_str)

    @staticmethod
    def _parse_iso_timezone_offset(
        date_str: String, date_pos: Int
    ) raises -> MorrowParseTimeZone:
        var sign = ord(date_str[byte=date_pos])
        if sign != ord("+") and sign != ord("-"):
            raise Error("isoformat timezone must be a fixed offset")

        var pos = date_pos + 1
        if pos + 2 > date_str.byte_length():
            raise Error("isoformat timezone hour is invalid")
        for i in range(2):
            if not Self._is_ascii_digit(ord(date_str[byte=pos + i])):
                raise Error("isoformat timezone hour is invalid")
        pos += 2

        if pos == date_str.byte_length():
            return MorrowParseTimeZone(
                TimeZone.from_utc(String(date_str[byte=date_pos:pos])), pos
            )

        if date_str[byte=pos] == ":":
            pos += 1
            if pos + 2 > date_str.byte_length():
                raise Error("isoformat timezone minute is invalid")
            for i in range(2):
                if not Self._is_ascii_digit(ord(date_str[byte=pos + i])):
                    raise Error("isoformat timezone minute is invalid")
            pos += 2
        elif (
            pos + 2 <= date_str.byte_length()
            and Self._is_ascii_digit(ord(date_str[byte=pos]))
            and Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
        ):
            pos += 2
        else:
            raise Error("isoformat timezone minute is invalid")

        if pos != date_str.byte_length():
            raise Error("isoformat timezone has trailing data")
        return MorrowParseTimeZone(
            TimeZone.from_utc(String(date_str[byte=date_pos:pos])), pos
        )

    @staticmethod
    def _from_utc_microseconds_value(total_us: Int) raises -> Self:
        var seconds = total_us // _US_PER_SECOND
        var microsecond = total_us % _US_PER_SECOND
        if microsecond < 0:
            seconds -= 1
            microsecond += _US_PER_SECOND

        var days = seconds // 86400
        var seconds_in_day = seconds % 86400
        if seconds_in_day < 0:
            days -= 1
            seconds_in_day += 86400

        var date = Self.fromordinal(_UNIX_EPOCH_ORDINAL + days)
        var hour = seconds_in_day // 3600
        var minute = (seconds_in_day % 3600) // 60
        var second = seconds_in_day % 60
        return Self(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
            second,
            microsecond,
            Self._utc_timezone(),
        )

    @staticmethod
    def _from_expanded_timestamp_value(timestamp: Int) raises -> Self:
        if timestamp > MAX_TIMESTAMP:
            if timestamp < MAX_TIMESTAMP_MS:
                return Self._from_utc_microseconds_value(timestamp * 1000)
            if timestamp < MAX_TIMESTAMP_US:
                return Self._from_utc_microseconds_value(timestamp)
            raise Error("timestamp is too large")
        return Self.utcfromtimestamp(Float64(timestamp))

    @staticmethod
    def _starts_with(s: String, pos: Int, pattern: String) -> Bool:
        if pos + pattern.byte_length() > s.byte_length():
            return False
        for i in range(pattern.byte_length()):
            if ord(s[byte=pos + i]) != ord(pattern[byte=i]):
                return False
        return True

    @staticmethod
    def _starts_with_ascii_case_insensitive(
        s: String, pos: Int, pattern: String
    ) -> Bool:
        if pos + pattern.byte_length() > s.byte_length():
            return False
        for i in range(pattern.byte_length()):
            if Self._ascii_lower(ord(s[byte=pos + i])) != Self._ascii_lower(
                ord(pattern[byte=i])
            ):
                return False
        return True

    @staticmethod
    def _ascii_lower(c: Int) -> Int:
        if c >= ord("A") and c <= ord("Z"):
            return c + 32
        return c

    @staticmethod
    def _has_left_parse_boundary(s: String, pos: Int) -> Bool:
        if pos == 0:
            return True
        var c = ord(s[byte=pos - 1])
        if Self._is_ascii_whitespace(c):
            return True
        if Self._is_parse_punctuation(c):
            return pos == 1 or Self._is_ascii_whitespace(ord(s[byte=pos - 2]))
        return False

    @staticmethod
    def _has_right_parse_boundary(s: String, pos: Int) -> Bool:
        if pos == s.byte_length():
            return True
        var c = ord(s[byte=pos])
        if Self._is_ascii_whitespace(c):
            return True
        if Self._is_parse_punctuation(c):
            return pos + 1 == s.byte_length() or Self._is_ascii_whitespace(
                ord(s[byte=pos + 1])
            )
        return False

    @staticmethod
    def _is_parse_punctuation(c: Int) -> Bool:
        return (
            c == ord(",")
            or c == ord(".")
            or c == ord(";")
            or c == ord(":")
            or c == ord("?")
            or c == ord("!")
            or c == ord('"')
            or c == ord("`")
            or c == ord("'")
            or c == ord("[")
            or c == ord("]")
            or c == ord("{")
            or c == ord("}")
            or c == ord("(")
            or c == ord(")")
            or c == ord("<")
            or c == ord(">")
        )

    @staticmethod
    def _is_ascii_alphanumeric(c: Int) -> Bool:
        return (
            Self._is_ascii_digit(c)
            or (c >= ord("A") and c <= ord("Z"))
            or (c >= ord("a") and c <= ord("z"))
        )

    @staticmethod
    def _is_ascii_digit(c: Int) -> Bool:
        return c >= ord("0") and c <= ord("9")

    @staticmethod
    def _is_ascii_whitespace(c: Int) -> Bool:
        return c == ord(" ") or c == 9 or c == 10 or c == 13

    @staticmethod
    def _normalize_whitespace(s: String) -> String:
        var result = ""
        var pending_space = False
        for i in range(s.byte_length()):
            if Self._is_ascii_whitespace(ord(s[byte=i])):
                if result.byte_length() > 0:
                    pending_space = True
            else:
                if pending_space:
                    result += " "
                    pending_space = False
                result += String(s[byte = i : i + 1])
        return result

    @staticmethod
    def _is_whitespace_regex_literal(fmt: String, start: Int, end: Int) -> Bool:
        return (
            end - start == 3
            and ord(fmt[byte=start]) == 92
            and ord(fmt[byte=start + 1]) == ord("s")
            and ord(fmt[byte=start + 2]) == ord("+")
        )

    @staticmethod
    def _is_optional_whitespace_regex_literal(
        fmt: String, start: Int, end: Int
    ) -> Bool:
        return (
            end - start == 3
            and ord(fmt[byte=start]) == 92
            and ord(fmt[byte=start + 1]) == ord("s")
            and ord(fmt[byte=start + 2]) == ord("*")
        )

    @staticmethod
    def _parse_whitespace_regex(date_str: String, date_pos: Int) raises -> Int:
        var pos = date_pos
        while pos < date_str.byte_length() and Self._is_ascii_whitespace(
            ord(date_str[byte=pos])
        ):
            pos += 1
        if pos == date_pos:
            raise Error("whitespace is missing")
        return pos

    @staticmethod
    def _parse_optional_whitespace_regex(
        date_str: String, date_pos: Int
    ) -> Int:
        var pos = date_pos
        while pos < date_str.byte_length() and Self._is_ascii_whitespace(
            ord(date_str[byte=pos])
        ):
            pos += 1
        return pos

    @staticmethod
    def _parse_literal_char(
        date_str: String, date_pos: Int, fmt: String, fmt_pos: Int
    ) raises:
        if date_pos >= date_str.byte_length():
            raise Error("date string is shorter than format")
        if ord(date_str[byte=date_pos]) != ord(fmt[byte=fmt_pos]):
            raise Error("date string does not match format literal")

    @staticmethod
    def _parse_fixed_int(
        date_str: String, date_pos: Int, count: Int
    ) raises -> MorrowParseInt:
        if date_pos + count > date_str.byte_length():
            raise Error("date string is shorter than numeric token")
        for i in range(count):
            if not Self._is_ascii_digit(ord(date_str[byte=date_pos + i])):
                raise Error("numeric token contains non-digit data")
        return MorrowParseInt(
            Int(date_str[byte = date_pos : date_pos + count]), date_pos + count
        )

    @staticmethod
    def _parse_variable_int(
        date_str: String, date_pos: Int, max_count: Int
    ) raises -> MorrowParseInt:
        var pos = date_pos
        var end = date_pos + max_count
        if end > date_str.byte_length():
            end = date_str.byte_length()
        while pos < end and Self._is_ascii_digit(ord(date_str[byte=pos])):
            pos += 1
        if pos == date_pos:
            raise Error("numeric token is missing")
        return MorrowParseInt(Int(date_str[byte=date_pos:pos]), pos)

    @staticmethod
    def _parse_subsecond(
        date_str: String, date_pos: Int, count: Int
    ) raises -> MorrowParseInt:
        var pos = date_pos
        while pos < date_str.byte_length() and Self._is_ascii_digit(
            ord(date_str[byte=pos])
        ):
            pos += 1
        if pos == date_pos:
            raise Error("subsecond token is missing")

        var digit_count = pos - date_pos
        if digit_count <= 6:
            var digits = String(date_str[byte=date_pos:pos])
            while digits.byte_length() < 6:
                digits += "0"
            return MorrowParseInt(Int(digits), pos)

        var value = Int(date_str[byte = date_pos : date_pos + 6])
        var round_digit = Int(date_str[byte = date_pos + 6 : date_pos + 7])
        var should_round = round_digit > 5
        if round_digit == 5:
            var has_remaining = False
            for i in range(date_pos + 7, pos):
                if ord(date_str[byte=i]) != ord("0"):
                    has_remaining = True
            should_round = has_remaining or value % 2 == 1
        if should_round:
            value += 1
        return MorrowParseInt(value, pos)

    @staticmethod
    def _validate_timestamp_seconds_token(timestamp_str: String) raises:
        var length = timestamp_str.byte_length()
        if length == 0:
            raise Error("timestamp token is missing")
        var pos = 0
        if timestamp_str[byte=pos] == "-":
            pos += 1
            if pos == length:
                raise Error("timestamp token is missing")

        var digit_start = pos
        while pos < length and Self._is_ascii_digit(
            ord(timestamp_str[byte=pos])
        ):
            pos += 1
        var digit_count = pos - digit_start
        if digit_count == 0:
            raise Error("timestamp token must start with digits")

        var has_fraction = False
        if pos < length and timestamp_str[byte=pos] == ".":
            has_fraction = True
            pos += 1
            var fraction_start = pos
            while pos < length and Self._is_ascii_digit(
                ord(timestamp_str[byte=pos])
            ):
                pos += 1
            if pos == fraction_start:
                raise Error("timestamp token fraction is missing")

        if pos != length:
            raise Error("timestamp token has invalid characters")
        if not has_fraction and digit_count < 2:
            raise Error("timestamp token integer is too short")

    @staticmethod
    def _validate_expanded_timestamp_token(timestamp_str: String) raises:
        var length = timestamp_str.byte_length()
        if length == 0:
            raise Error("timestamp token is missing")
        var pos = 0
        if timestamp_str[byte=pos] == "-":
            pos += 1
            if pos == length:
                raise Error("timestamp token is missing")
        while pos < length and Self._is_ascii_digit(
            ord(timestamp_str[byte=pos])
        ):
            pos += 1
        if pos != length:
            raise Error("timestamp token has invalid characters")

    @staticmethod
    def _parse_ordinal_suffix(
        date_str: String, date_pos: Int, value: Int
    ) raises -> Int:
        if date_pos + 2 > date_str.byte_length():
            raise Error("ordinal suffix is missing")
        var expected = "th"
        var mod100 = value % 100
        if mod100 < 11 or mod100 > 13:
            var mod10 = value % 10
            if mod10 == 1:
                expected = "st"
            elif mod10 == 2:
                expected = "nd"
            elif mod10 == 3:
                expected = "rd"
        if Self._starts_with_ascii_case_insensitive(
            date_str, date_pos, expected
        ):
            return date_pos + 2
        raise Error("ordinal suffix is invalid")

    @staticmethod
    def _parse_two_digit_year(year: Int) -> Int:
        if year >= 69:
            return 1900 + year
        return 2000 + year

    @staticmethod
    def _parse_month_name(
        date_str: String, date_pos: Int, abbreviated: Bool
    ) raises -> MorrowParseInt:
        for value in range(1, 13):
            var name = month_abbreviation(value) if abbreviated else month_name(
                value
            )
            if Self._starts_with_ascii_case_insensitive(
                date_str, date_pos, name
            ):
                return MorrowParseInt(value, date_pos + name.byte_length())
        raise Error("month name is invalid")

    @staticmethod
    def _parse_weekday_name(
        date_str: String, date_pos: Int, abbreviated: Bool
    ) raises -> MorrowParseInt:
        for value in range(1, 8):
            var name = day_abbreviation(value) if abbreviated else day_name(
                value
            )
            if Self._starts_with_ascii_case_insensitive(
                date_str, date_pos, name
            ):
                return MorrowParseInt(value, date_pos + name.byte_length())
        raise Error("weekday name is invalid")

    @staticmethod
    def _parse_iso_week_date(
        date_str: String, date_pos: Int
    ) raises -> MorrowParseIsoWeek:
        var year_parsed = Self._parse_fixed_int(date_str, date_pos, 4)
        var pos = year_parsed.pos
        if pos < date_str.byte_length() and date_str[byte=pos] == "-":
            pos += 1
        if pos >= date_str.byte_length() or ord(date_str[byte=pos]) != ord("W"):
            raise Error("ISO week date is missing W marker")
        pos += 1
        var week_parsed = Self._parse_fixed_int(date_str, pos, 2)
        pos = week_parsed.pos

        var weekday = 1
        if pos < date_str.byte_length() and date_str[byte=pos] == "-":
            if pos + 1 < date_str.byte_length() and Self._is_ascii_digit(
                ord(date_str[byte=pos + 1])
            ):
                pos += 1
                var weekday_parsed = Self._parse_fixed_int(date_str, pos, 1)
                weekday = weekday_parsed.value
                pos = weekday_parsed.pos
        elif pos < date_str.byte_length() and Self._is_ascii_digit(
            ord(date_str[byte=pos])
        ):
            var weekday_parsed = Self._parse_fixed_int(date_str, pos, 1)
            weekday = weekday_parsed.value
            pos = weekday_parsed.pos

        return MorrowParseIsoWeek(
            year_parsed.value, week_parsed.value, weekday, pos
        )

    @staticmethod
    def _parse_timezone_name(
        date_str: String, date_pos: Int
    ) raises -> MorrowParseTimeZone:
        if Self._starts_with_ascii_case_insensitive(date_str, date_pos, "UTC"):
            return MorrowParseTimeZone(Self._utc_timezone(), date_pos + 3)
        if Self._starts_with_ascii_case_insensitive(date_str, date_pos, "GMT"):
            return MorrowParseTimeZone(TimeZone(0, "GMT"), date_pos + 3)
        if Self._starts_with(date_str, date_pos, "local"):
            return MorrowParseTimeZone(TimeZone.local(), date_pos + 5)
        if date_pos >= date_str.byte_length():
            raise Error("timezone is missing")
        raise Error("timezone name is invalid")

    @staticmethod
    def _parse_timezone_offset(
        date_str: String, date_pos: Int, colon: Bool
    ) raises -> MorrowParseTimeZone:
        if Self._starts_with(date_str, date_pos, "Z"):
            return MorrowParseTimeZone(Self._utc_timezone(), date_pos + 1)
        if date_pos >= date_str.byte_length():
            raise Error("timezone is missing")

        var sign = ord(date_str[byte=date_pos])
        if sign != ord("+") and sign != ord("-"):
            raise Error("timezone must be Z or a fixed offset")

        var pos = date_pos + 1
        if pos + 2 > date_str.byte_length():
            raise Error("timezone hour is invalid")
        for i in range(2):
            if not Self._is_ascii_digit(ord(date_str[byte=pos + i])):
                raise Error("timezone hour is invalid")
        pos += 2

        if pos < date_str.byte_length() and date_str[byte=pos] == ":":
            if not colon:
                raise Error("timezone offset must not contain a colon")
            pos += 1
            if pos + 2 > date_str.byte_length():
                raise Error("timezone minute is invalid")
            for i in range(2):
                if not Self._is_ascii_digit(ord(date_str[byte=pos + i])):
                    raise Error("timezone minute is invalid")
            pos += 2
        elif (
            pos + 2 <= date_str.byte_length()
            and Self._is_ascii_digit(ord(date_str[byte=pos]))
            and Self._is_ascii_digit(ord(date_str[byte=pos + 1]))
        ):
            if colon:
                raise Error("timezone offset minutes must contain a colon")
            pos += 2
        return MorrowParseTimeZone(
            TimeZone.from_utc(String(date_str[byte=date_pos:pos])), pos
        )

    @staticmethod
    def _parse_am_pm(
        date_str: String, date_pos: Int, upper: Bool
    ) raises -> Int:
        if Self._starts_with_ascii_case_insensitive(
            date_str, date_pos, "AM"
        ) or Self._starts_with_ascii_case_insensitive(date_str, date_pos, "PM"):
            return date_pos + 2
        raise Error("AM/PM marker is invalid")

    @staticmethod
    def _last_am_pm_was_pm(date_str: String, date_pos: Int) -> Bool:
        if date_pos < 2:
            return False
        var c = ord(date_str[byte=date_pos - 2])
        return c == ord("P") or c == ord("p")

    def _shift_day_time(
        self,
        days: Int,
        hours: Int,
        minutes: Int,
        seconds: Int,
        microseconds: Int,
    ) raises -> Self:
        var total_us = (
            (self.hour * 3600 + self.minute * 60 + self.second) * _US_PER_SECOND
            + self.microsecond
            + hours * _US_PER_HOUR
            + minutes * _US_PER_MINUTE
            + seconds * _US_PER_SECOND
            + microseconds
        )
        var extra_days = total_us // _US_PER_DAY
        var remaining_us = total_us % _US_PER_DAY
        var date = Self.fromordinal(self.toordinal() + days + extra_days)
        var hour = remaining_us // _US_PER_HOUR
        remaining_us = remaining_us % _US_PER_HOUR
        var minute = remaining_us // _US_PER_MINUTE
        remaining_us = remaining_us % _US_PER_MINUTE
        var second = remaining_us // _US_PER_SECOND
        var microsecond = remaining_us % _US_PER_SECOND
        return Self(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
            second,
            microsecond,
            self.tz,
        )

    def _humanize_auto(
        self, other: Self, delta_us: Int, only_distance: Bool
    ) raises -> String:
        var rounded_delta_seconds = Self._rounded_seconds(delta_us)
        var seconds = abs(rounded_delta_seconds)
        if seconds < 60:
            if seconds < 10:
                if only_distance:
                    return "instantly"
                return "just now"
            return Self._format_humanize_result(
                rounded_delta_seconds, seconds, "second", only_distance
            )
        elif seconds < 3600:
            if seconds < 120:
                return Self._format_humanize_result(
                    rounded_delta_seconds, 1, "minute", only_distance
                )
            var minutes = seconds // 60
            if minutes < 2:
                minutes = 2
            return Self._format_humanize_result(
                rounded_delta_seconds, minutes, "minute", only_distance
            )
        elif seconds < 86400:
            if seconds < 7200:
                return Self._format_humanize_result(
                    rounded_delta_seconds, 1, "hour", only_distance
                )
            var hours = seconds // 3600
            if hours < 2:
                hours = 2
            return Self._format_humanize_result(
                rounded_delta_seconds, hours, "hour", only_distance
            )

        var calendar_months = self._humanize_calendar_months(other)
        if seconds < 172800:
            return Self._format_humanize_result(
                rounded_delta_seconds, 1, "day", only_distance
            )
        elif seconds < 604800:
            var days = seconds // 86400
            if days < 2:
                days = 2
            return Self._format_humanize_result(
                rounded_delta_seconds, days, "day", only_distance
            )
        elif calendar_months >= 1 and seconds < 31536000:
            return Self._format_humanize_result(
                rounded_delta_seconds, calendar_months, "month", only_distance
            )
        elif seconds < 1209600:
            return Self._format_humanize_result(
                rounded_delta_seconds, 1, "week", only_distance
            )
        elif seconds < 2592000:
            var weeks = seconds // 604800
            if weeks < 2:
                weeks = 2
            return Self._format_humanize_result(
                rounded_delta_seconds, weeks, "week", only_distance
            )
        elif seconds < 63072000:
            return Self._format_humanize_result(
                rounded_delta_seconds, 1, "year", only_distance
            )

        var years = seconds // 31536000
        if years < 2:
            years = 2
        return Self._format_humanize_result(
            rounded_delta_seconds, years, "year", only_distance
        )

    def _humanize_calendar_months(self, other: Self) raises -> Int:
        var start = other
        var end = self
        if self._utc_microseconds() < other._utc_microseconds():
            start = self
            end = other

        var months = (end.year - start.year) * 12 + end.month - start.month
        var days: Int
        if end.day >= start.day:
            days = end.day - start.day
        else:
            months -= 1
            var previous_year = end.year
            var previous_month = end.month - 1
            if previous_month < 1:
                previous_month = 12
                previous_year -= 1
            days = (
                end.day
                + _days_in_month(previous_year, previous_month)
                - start.day
            )

        if days > 14:
            months += 1
        if months > 12:
            return 12
        return months

    @staticmethod
    def _format_humanize_result(
        delta_seconds: Int, count: Int, unit: String, only_distance: Bool
    ) raises -> String:
        var distance = Self._format_humanize_distance(count, unit)
        if only_distance:
            return distance
        if delta_seconds >= 0:
            return "in " + distance
        return distance + " ago"

    @staticmethod
    def _rounded_seconds(delta_us: Int) -> Int:
        var sign = 1
        var abs_us = delta_us
        if abs_us < 0:
            sign = -1
            abs_us = -abs_us
        var seconds = abs_us // _US_PER_SECOND
        var remainder = abs_us % _US_PER_SECOND
        if remainder > _US_PER_SECOND // 2:
            seconds += 1
        elif remainder == _US_PER_SECOND // 2 and seconds % 2 == 1:
            seconds += 1
        return sign * seconds

    @staticmethod
    def _join_humanize_parts(parts: List[String]) -> String:
        if len(parts) == 0:
            return ""
        if len(parts) == 1:
            return String(parts[0])

        var result = String(parts[0])
        for i in range(1, len(parts) - 1):
            result += " " + parts[i]
        return result + " and " + parts[len(parts) - 1]

    @staticmethod
    def _humanize_count(seconds: Int, unit: String) raises -> Int:
        var unit_seconds = Self._humanize_unit_seconds(unit)
        return seconds // unit_seconds

    @staticmethod
    def _humanize_unit_seconds(unit: String) raises -> Int:
        if unit == "second":
            return 1
        elif unit == "minute":
            return 60
        elif unit == "hour":
            return 3600
        elif unit == "day":
            return 86400
        elif unit == "week":
            return 604800
        elif unit == "month":
            return _HUMANIZE_SECONDS_PER_MONTH
        elif unit == "quarter":
            return _HUMANIZE_SECONDS_PER_QUARTER
        elif unit == "year":
            return 31536000
        else:
            raise Error("unsupported granularity")

    @staticmethod
    def _normalize_dehumanize_unit(
        count_word: String, count: Int, raw_unit: String
    ) raises -> String:
        var unit = raw_unit
        if unit.byte_length() > 0 and unit[byte=unit.byte_length() - 1] == ",":
            unit = String(unit[byte = 0 : unit.byte_length() - 1])

        if count_word == "a" or count_word == "an":
            if not Self._is_singular_humanize_unit(
                unit
            ) and not Self._is_plural_humanize_unit(unit):
                raise Error("humanized distance is invalid")
            var normalized = Self._normalize_humanize_unit(unit)
            if count_word == "an":
                if normalized != "hour":
                    raise Error("humanized distance is invalid")
            elif normalized == "hour":
                raise Error("humanized distance is invalid")
            return normalized

        if not Self._is_plural_humanize_unit(unit):
            raise Error("humanized distance is invalid")
        return Self._normalize_humanize_unit(unit)

    @staticmethod
    def _is_singular_humanize_unit(unit: String) -> Bool:
        return (
            unit == "second"
            or unit == "minute"
            or unit == "hour"
            or unit == "day"
            or unit == "week"
            or unit == "month"
            or unit == "quarter"
            or unit == "year"
        )

    @staticmethod
    def _is_plural_humanize_unit(unit: String) -> Bool:
        return (
            unit == "seconds"
            or unit == "minutes"
            or unit == "hours"
            or unit == "days"
            or unit == "weeks"
            or unit == "months"
            or unit == "quarters"
            or unit == "years"
        )

    @staticmethod
    def _normalize_humanize_granularity_list(
        granularity: List[String],
    ) raises -> List[String]:
        var has_year = False
        var has_quarter = False
        var has_month = False
        var has_week = False
        var has_day = False
        var has_hour = False
        var has_minute = False
        var has_second = False

        for i in range(len(granularity)):
            var unit = granularity[i]
            _ = Self._humanize_unit_seconds(unit)
            if unit == "year":
                if has_year:
                    raise Error("unsupported granularity")
                has_year = True
            elif unit == "quarter":
                if has_quarter:
                    raise Error("unsupported granularity")
                has_quarter = True
            elif unit == "month":
                if has_month:
                    raise Error("unsupported granularity")
                has_month = True
            elif unit == "week":
                if has_week:
                    raise Error("unsupported granularity")
                has_week = True
            elif unit == "day":
                if has_day:
                    raise Error("unsupported granularity")
                has_day = True
            elif unit == "hour":
                if has_hour:
                    raise Error("unsupported granularity")
                has_hour = True
            elif unit == "minute":
                if has_minute:
                    raise Error("unsupported granularity")
                has_minute = True
            elif unit == "second":
                if has_second:
                    raise Error("unsupported granularity")
                has_second = True

        var ordered = List[String]()
        if has_year:
            ordered.append("year")
        if has_quarter:
            ordered.append("quarter")
        if has_month:
            ordered.append("month")
        if has_week:
            ordered.append("week")
        if has_day:
            ordered.append("day")
        if has_hour:
            ordered.append("hour")
        if has_minute:
            ordered.append("minute")
        if has_second:
            ordered.append("second")
        return ordered^

    @staticmethod
    def _format_humanize_distance(count: Int, unit: String) raises -> String:
        var unit_ = Self._normalize_humanize_unit(unit)
        if count == 1:
            if unit_ == "hour":
                return "an hour"
            return "a " + unit_
        return String(count) + " " + Self._plural_humanize_unit(unit_)

    @staticmethod
    def _normalize_humanize_unit(unit: String) raises -> String:
        if unit == "second" or unit == "seconds":
            return "second"
        elif unit == "minute" or unit == "minutes":
            return "minute"
        elif unit == "hour" or unit == "hours":
            return "hour"
        elif unit == "day" or unit == "days":
            return "day"
        elif unit == "week" or unit == "weeks":
            return "week"
        elif unit == "month" or unit == "months":
            return "month"
        elif unit == "quarter" or unit == "quarters":
            return "quarter"
        elif unit == "year" or unit == "years":
            return "year"
        else:
            raise Error("unsupported granularity")

    @staticmethod
    def _plural_humanize_unit(unit: String) raises -> String:
        if unit == "quarter":
            return "quarters"
        return unit + "s"

    @staticmethod
    def _find_byte(s: String, c: Int) -> Int:
        for i in range(s.byte_length()):
            if ord(s[byte=i]) == c:
                return i
        return -1

    def _shift_humanize_unit(self, unit: String, count: Int) raises -> Self:
        if unit == "second":
            return self.shift(seconds=count)
        elif unit == "minute":
            return self.shift(minutes=count)
        elif unit == "hour":
            return self.shift(hours=count)
        elif unit == "day":
            return self.shift(days=count)
        elif unit == "week":
            return self.shift(weeks=count)
        elif unit == "month":
            return self.shift(months=count)
        elif unit == "quarter":
            return self.shift(months=count * 3)
        elif unit == "year":
            return self.shift(years=count)
        else:
            raise Error("unsupported granularity")

    def _utc_microseconds(self) raises -> Int:
        var seconds = (
            (self.toordinal() - _UNIX_EPOCH_ORDINAL) * 86400
            + self.hour * 3600
            + self.minute * 60
            + self.second
            - self.tz.offset
        )
        return seconds * _US_PER_SECOND + self.microsecond

    def _time_tuple(self) raises -> MorrowTimeTuple:
        return MorrowTimeTuple(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.weekday(),
            self.toordinal() - _ymd2ord(self.year, 1, 1) + 1,
            0,
        )

    def format(self, fmt: String = "YYYY-MM-DD HH:mm:ssZZ") raises -> String:
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

    def strftime(self, fmt: String) raises -> String:
        """
        Format using Python ``datetime.strftime`` directives.
        """
        return format_strftime(
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

    def isoformat(
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
        if sep.byte_length() != 1:
            raise Error("isoformat separator must be one character")

        var date_str = self._date_string()
        var time_str: String
        if timespec == "auto":
            if self.microsecond == 0:
                time_str = (
                    String(self.hour).ascii_rjust(2, "0")
                    + ":"
                    + String(self.minute).ascii_rjust(2, "0")
                    + ":"
                    + String(self.second).ascii_rjust(2, "0")
                )
            else:
                time_str = self._time_string_microseconds()
        elif timespec == "microseconds":
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

    def _date_string(self) -> String:
        return (
            String(self.year).ascii_rjust(4, "0")
            + "-"
            + String(self.month).ascii_rjust(2, "0")
            + "-"
            + String(self.day).ascii_rjust(2, "0")
        )

    def _time_string_microseconds(self) -> String:
        return (
            String(self.hour).ascii_rjust(2, "0")
            + ":"
            + String(self.minute).ascii_rjust(2, "0")
            + ":"
            + String(self.second).ascii_rjust(2, "0")
            + "."
            + String(self.microsecond).ascii_rjust(6, "0")
        )

    def _isoformat_auto(self) -> String:
        var result = (
            self._date_string() + "T" + self._time_string_microseconds()
        )
        if not self.tz.is_none():
            result += self.tz.format()
        return result

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self._isoformat_auto())

    def toordinal(self) raises -> Int:
        """
        Return the proleptic Gregorian ordinal of the date, where January 1 of year 1 has ordinal 1.
        """
        return _ymd2ord(self.year, self.month, self.day)

    @staticmethod
    def fromordinal(ordinal: Int) raises -> Self:
        """
        Construct a Morrow object from a proleptic Gregorian ordinal.

        January 1 of year 1 is day 1. Only the year, month and day are non-zero in the result.
        """
        if ordinal < 1 or ordinal > MAX_ORDINAL:
            raise Error("ordinal is out of range")

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
            if month > 2 and leapyear:
                preceding = days_before_month(month) + 1
            else:
                preceding = days_before_month(month)
        n -= preceding

        # Now the year and month are correct, and n is the offset from the
        # start of that month:  we're done!
        return Self(year, month, n + 1)

    @staticmethod
    def fromisocalendar(
        iso_year: Int, iso_week: Int, iso_weekday: Int
    ) raises -> Self:
        """
        Construct a UTC Morrow from ISO year, week, and weekday fields.
        """
        if iso_weekday < 1 or iso_weekday > 7:
            raise Error("iso_weekday must be in 1..7")
        var week1 = Self._iso_week1_monday(iso_year)
        var next_week1 = Self._iso_week1_monday(iso_year + 1)
        var max_week = (next_week1 - week1) // 7
        if iso_week < 1 or iso_week > max_week:
            raise Error("iso_week is out of range for iso_year")
        var ordinal = week1 + (iso_week - 1) * 7 + iso_weekday - 1
        var date = Self.fromordinal(ordinal)
        return date.replace(tzinfo=Self._utc_timezone())

    def isoweekday(self) raises -> Int:
        """
        Return the day of the week as an integer, where Monday is 1 and Sunday is 7.
        """
        # 1-Jan-0001 is a Monday
        return self.toordinal() % 7 or 7

    def isocalendar(self) raises -> MorrowIsoCalendar:
        """
        Return the ISO year, week number, and ISO weekday.
        """
        var ordinal = self.toordinal()
        var iso_year = self.year
        var week1 = Self._iso_week1_monday(iso_year)
        if ordinal < week1:
            iso_year -= 1
            week1 = Self._iso_week1_monday(iso_year)
        else:
            var next_week1 = Self._iso_week1_monday(iso_year + 1)
            if ordinal >= next_week1:
                iso_year += 1
                week1 = next_week1

        return MorrowIsoCalendar(
            iso_year, (ordinal - week1) // 7 + 1, self.isoweekday()
        )

    @staticmethod
    def _iso_week1_monday(year: Int) raises -> Int:
        var fourth_jan = _ymd2ord(year, 1, 4)
        var weekday = fourth_jan % 7 or 7
        return fourth_jan - weekday + 1

    def weekday(self) raises -> Int:
        """
        Return the day of the week as an integer, where Monday is 0 and Sunday is 6.
        """
        return self.isoweekday() - 1

    def __str__(self) raises -> String:
        return self.isoformat()

    def __eq__(self, other: Self) raises -> Bool:
        return self._utc_microseconds() == other._utc_microseconds()

    def __le__(self, other: Self) raises -> Bool:
        return self._utc_microseconds() <= other._utc_microseconds()

    def __lt__(self, other: Self) raises -> Bool:
        return self._utc_microseconds() < other._utc_microseconds()

    def __ge__(self, other: Self) raises -> Bool:
        return self._utc_microseconds() >= other._utc_microseconds()

    def __gt__(self, other: Self) raises -> Bool:
        return self._utc_microseconds() > other._utc_microseconds()

    def __add__(self, delta: TimeDelta) raises -> Self:
        return self._shift_day_time(
            delta.days, 0, 0, delta.seconds, delta.microseconds
        )

    def __radd__(self, delta: TimeDelta) raises -> Self:
        return self + delta

    def __sub__(self, delta: TimeDelta) raises -> Self:
        return self._shift_day_time(
            -delta.days, 0, 0, -delta.seconds, -delta.microseconds
        )

    def __sub__(self, other: Self) raises -> TimeDelta:
        return TimeDelta(
            microseconds=self._utc_microseconds() - other._utc_microseconds()
        )


struct MorrowSpan(Copyable, ImplicitlyCopyable, Movable):
    var start: Morrow
    var end: Morrow

    def __init__(out self, start: Morrow, end: Morrow):
        self.start = start
        self.end = end

    def __init__(out self, *, copy: Self):
        self.start = copy.start
        self.end = copy.end

    def __init__(out self, *, deinit take: Self):
        self.start = take.start^
        self.end = take.end^


struct MorrowIsoCalendar(Copyable, ImplicitlyCopyable, Movable):
    var year: Int
    var week: Int
    var weekday: Int

    def __init__(out self, year: Int, week: Int, weekday: Int):
        self.year = year
        self.week = week
        self.weekday = weekday


struct MorrowDate(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var month: Int
    var day: Int

    def __init__(out self, year: Int, month: Int, day: Int):
        self.year = year
        self.month = month
        self.day = day

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            String(self.year).ascii_rjust(4, "0")
            + "-"
            + String(self.month).ascii_rjust(2, "0")
            + "-"
            + String(self.day).ascii_rjust(2, "0")
        )


struct MorrowTime(Copyable, ImplicitlyCopyable, Movable, Writable):
    var hour: Int
    var minute: Int
    var second: Int
    var microsecond: Int
    var tz: TimeZone

    def __init__(
        out self,
        hour: Int,
        minute: Int,
        second: Int,
        microsecond: Int,
        tz: TimeZone = TimeZone.none(),
    ):
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
        self.tz = tz

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        var result = (
            String(self.hour).ascii_rjust(2, "0")
            + ":"
            + String(self.minute).ascii_rjust(2, "0")
            + ":"
            + String(self.second).ascii_rjust(2, "0")
            + "."
            + String(self.microsecond).ascii_rjust(6, "0")
        )
        if not self.tz.is_none():
            result += self.tz.format()
        return result


struct MorrowTimeTuple(Copyable, ImplicitlyCopyable, Movable):
    var year: Int
    var mon: Int
    var mday: Int
    var hour: Int
    var min: Int
    var sec: Int
    var wday: Int
    var yday: Int
    var isdst: Int

    def __init__(
        out self,
        year: Int,
        mon: Int,
        mday: Int,
        hour: Int,
        min: Int,
        sec: Int,
        wday: Int,
        yday: Int,
        isdst: Int,
    ):
        self.year = year
        self.mon = mon
        self.mday = mday
        self.hour = hour
        self.min = min
        self.sec = sec
        self.wday = wday
        self.yday = yday
        self.isdst = isdst


struct MorrowParseInt(Copyable, ImplicitlyCopyable, Movable):
    var value: Int
    var pos: Int

    def __init__(out self, value: Int, pos: Int):
        self.value = value
        self.pos = pos


struct MorrowParseIsoWeek(Copyable, ImplicitlyCopyable, Movable):
    var year: Int
    var week: Int
    var weekday: Int
    var pos: Int

    def __init__(out self, year: Int, week: Int, weekday: Int, pos: Int):
        self.year = year
        self.week = week
        self.weekday = weekday
        self.pos = pos


struct MorrowParseTimeZone(Copyable, ImplicitlyCopyable, Movable):
    var tz: TimeZone
    var pos: Int

    def __init__(out self, tz: TimeZone, pos: Int):
        self.tz = tz
        self.pos = pos

    def __init__(out self, *, copy: Self):
        self.tz = copy.tz
        self.pos = copy.pos

    def __init__(out self, *, deinit take: Self):
        self.tz = take.tz^
        self.pos = take.pos
