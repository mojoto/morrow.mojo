from .util import (
    normalize_timestamp,
    _ymd2ord,
    _days_before_year,
    _days_in_month,
)
from ._libc import c_gettimeofday, c_localtime, c_gmtime, c_strptime
from ._libc import CTimeval, CTm
from .timezone import TimeZone
from .timedelta import TimeDelta
from .formatter import format_morrow, format_strftime
from .constants import (
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
    def _fromtimestamp(t: CTimeval, utc: Bool) -> Self:
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
    def fromtimestamp(timestamp: Float64) raises -> Self:
        return Self._fromtimestamp(
            Self._timeval_from_timestamp(timestamp), False
        )

    @staticmethod
    def fromtimestamp(timestamp: String) raises -> Self:
        return Self.fromtimestamp(Float64(timestamp))

    @staticmethod
    def fromtimestamp(timestamp: Float64, tz: TimeZone) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def fromtimestamp(timestamp: String, tz: TimeZone) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def fromtimestamp(timestamp: Float64, tz_str: String) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def fromtimestamp(timestamp: String, tz_str: String) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def utcfromtimestamp(timestamp: Float64) raises -> Self:
        return Self._fromtimestamp(
            Self._timeval_from_timestamp(timestamp), True
        )

    @staticmethod
    def utcfromtimestamp(timestamp: String) raises -> Self:
        return Self.utcfromtimestamp(Float64(timestamp))

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
        return Self.get(year, month, day, TimeZone.from_utc(tz_str))

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
            TimeZone.from_utc(tz_str),
        )

    @staticmethod
    def get(timestamp: Float64) raises -> Self:
        """
        Create a UTC Morrow from a POSIX timestamp.
        """
        return Self.utcfromtimestamp(timestamp)

    @staticmethod
    def get(timestamp: Float64, tz: TimeZone) raises -> Self:
        """
        Create a Morrow from a POSIX timestamp converted to a fixed-offset timezone.
        """
        return Self.utcfromtimestamp(timestamp).to(tz)

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
            date_str, formats, TimeZone.from_utc(tz_str)
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
        return Self._parse_arrow(date_str, fmt, TimeZone.from_utc(tz_str))

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
            if (
                separator != ord("T")
                and separator != ord("t")
                and separator != ord(" ")
            ):
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
                    tz = TimeZone.from_utc(String(date_str[byte=pos:]))
                    pos = length
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
        var year = 0
        var month = 1
        var day = 1
        var day_of_year = 0
        var hour = 0
        var minute = 0
        var second = 0
        var microsecond = 0
        var tz = Self._utc_timezone()
        var hour_is_12 = False
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
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "YY"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                year = 2000 + parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "MMMM"):
                var parsed = Self._parse_month_name(date_str, date_pos, False)
                month = parsed.value
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "MMM"):
                var parsed = Self._parse_month_name(date_str, date_pos, True)
                month = parsed.value
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "MM"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                month = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "M"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                month = parsed.value
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "DDDD"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 3)
                day_of_year = parsed.value
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "DDD"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 3)
                day_of_year = parsed.value
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "Do"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                day = parsed.value
                date_pos = parsed.pos
                date_pos = Self._parse_ordinal_suffix(date_str, date_pos)
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "DD"):
                var parsed = Self._parse_fixed_int(date_str, date_pos, 2)
                day = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "D"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                day = parsed.value
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
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "dddd"):
                date_pos = Self._parse_weekday_name(date_str, date_pos, False)
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "ddd"):
                date_pos = Self._parse_weekday_name(date_str, date_pos, True)
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
                hour_is_12 = True
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "h"):
                var parsed = Self._parse_variable_int(date_str, date_pos, 2)
                hour = parsed.value
                hour_is_12 = True
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
            elif Self._starts_with(fmt, fmt_pos, "SSSSSS"):
                var parsed = Self._parse_subsecond(date_str, date_pos, 6)
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos += 6
            elif Self._starts_with(fmt, fmt_pos, "SSSSS"):
                var parsed = Self._parse_subsecond(date_str, date_pos, 5)
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos += 5
            elif Self._starts_with(fmt, fmt_pos, "SSSS"):
                var parsed = Self._parse_subsecond(date_str, date_pos, 4)
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos += 4
            elif Self._starts_with(fmt, fmt_pos, "SSS"):
                var parsed = Self._parse_subsecond(date_str, date_pos, 3)
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos += 3
            elif Self._starts_with(fmt, fmt_pos, "SS"):
                var parsed = Self._parse_subsecond(date_str, date_pos, 2)
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos += 2
            elif Self._starts_with(fmt, fmt_pos, "S"):
                var parsed = Self._parse_subsecond(date_str, date_pos, 1)
                microsecond = parsed.value
                date_pos = parsed.pos
                fmt_pos += 1
            elif Self._starts_with(fmt, fmt_pos, "X"):
                if fmt_pos + 1 != fmt.byte_length():
                    raise Error("timestamp token must be the full format")
                var parsed = Self.utcfromtimestamp(
                    String(date_str[byte=date_pos:])
                )
                if not tzinfo.is_none():
                    return parsed.replace(tzinfo)
                return parsed
            elif Self._starts_with(fmt, fmt_pos, "x"):
                if fmt_pos + 1 != fmt.byte_length():
                    raise Error("timestamp token must be the full format")
                var parsed = Self._from_expanded_timestamp_value(
                    Int(date_str[byte=date_pos:])
                )
                if not tzinfo.is_none():
                    return parsed.replace(tzinfo)
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
        if hour_is_12:
            if hour < 1 or hour > 12:
                raise Error("12-hour clock hour must be in 1..12")
            if am_pm == 1 and hour == 12:
                hour = 0
            elif am_pm == 2 and hour != 12:
                hour += 12
        if day_of_year != 0:
            var date = Self.fromordinal(_ymd2ord(year, 1, 1) + day_of_year - 1)
            month = date.month
            day = date.day
        if microsecond >= _US_PER_SECOND:
            second += microsecond // _US_PER_SECOND
            microsecond = microsecond % _US_PER_SECOND
        var midnight_end_of_day = False
        if not hour_is_12 and hour == 24:
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
        return Self.fromdate(date, TimeZone.from_utc(tz_str))

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
        return Self.fromdatetime(dt, TimeZone.from_utc(tz_str))

    @staticmethod
    def strptime(
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
    def strptime(date_str: String, fmt: String, tz_str: String) raises -> Self:
        """
        Create a Morrow instance by time_zone_string with utc format.

        Usage::

        >>> Morrow.strptime('20-01-2019 15:49:10', '%d-%m-%Y %H:%M:%S', '+08:00')
            <Morrow [2019-01-20T15:49:10+08:00]>
        """
        var tzinfo = TimeZone.from_utc(tz_str)
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
        return self._utc_microseconds() // _US_PER_SECOND

    def for_json(self) raises -> String:
        """
        Return an ISO 8601 string for JSON serialization.
        """
        return self.isoformat()

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
        if delta_us == 0:
            return "just now"

        var seconds = abs(delta_us) // _US_PER_SECOND
        var unit = granularity
        if unit == "auto":
            unit = Self._auto_humanize_unit(seconds)
        var count = Self._humanize_count(seconds, unit)
        var distance = Self._format_humanize_distance(count, unit)

        if only_distance:
            return distance
        if delta_us > 0:
            return "in " + distance
        return distance + " ago"

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

        var delta_us = self._utc_microseconds() - other._utc_microseconds()
        if delta_us == 0:
            return "just now"

        var remaining = abs(delta_us) // _US_PER_SECOND
        var distance = ""
        for i in range(len(granularity)):
            var unit = granularity[i]
            var unit_seconds = Self._humanize_unit_seconds(unit)
            var count = remaining // unit_seconds
            if count > 0 or (
                distance.byte_length() == 0 and i == len(granularity) - 1
            ):
                if count < 1:
                    count = 1
                var part = Self._format_humanize_distance(count, unit)
                if distance.byte_length() == 0:
                    distance = part
                else:
                    distance += " and " + part
            remaining = remaining % unit_seconds

        if only_distance:
            return distance
        if delta_us > 0:
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

        var count: Int
        var unit: String
        if phrase.byte_length() > 2 and phrase[byte=0:2] == "a ":
            count = 1
            unit = String(phrase[byte=2:])
        elif phrase.byte_length() > 3 and phrase[byte=0:3] == "an ":
            count = 1
            unit = String(phrase[byte=3:])
        else:
            var separator = Self._find_byte(phrase, ord(" "))
            if separator <= 0:
                raise Error("humanized distance is invalid")
            count = Int(phrase[byte=0:separator])
            unit = String(phrase[byte = separator + 1 :])

        unit = Self._normalize_humanize_unit(unit)
        if not future:
            count = -count
        return self._shift_humanize_unit(unit, count)

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
        if tz_str == "local":
            return self.to(TimeZone.local())
        return self.to(TimeZone.from_utc(tz_str))

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
        Self._validate_fields(
            year_, month_, day_, hour_, minute_, second_, microsecond_
        )
        return Self(
            year_, month_, day_, hour_, minute_, second_, microsecond_, self.tz
        )

    def replace(self, tzinfo: TimeZone) -> Self:
        """
        Return a new Morrow with timezone replaced without conversion.
        """
        return Self(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.microsecond,
            tzinfo,
        )

    def replace(self, tzinfo: String) raises -> Self:
        """
        Return a new Morrow with timezone parsed and replaced without conversion.
        """
        return self.replace(TimeZone.from_utc(tzinfo))

    def shift(
        self,
        years: Int = 0,
        months: Int = 0,
        weeks: Int = 0,
        days: Int = 0,
        hours: Int = 0,
        minutes: Int = 0,
        seconds: Int = 0,
        microseconds: Int = 0,
        weekday: Int = -1,
    ) raises -> Self:
        """
        Return a new Morrow shifted by relative date and time offsets.
        """
        if weekday < -1 or weekday > 6:
            raise Error("weekday must be in 0..6")
        var total_months = (
            self.year * 12 + (self.month - 1) + years * 12 + months
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
        if weekday != -1:
            var current_weekday = shifted.weekday()
            var weekday_offset = weekday - current_weekday
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
        if count < 1:
            raise Error("count must be greater than 0")
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
        frame: String, start: Self, end: Self, limit: Int = -1
    ) raises -> List[Self]:
        """
        Return points in time between start and end, stepping by frame.
        """
        var items = List[Self]()
        var current = start
        var emitted = 0
        while current._utc_microseconds() <= end._utc_microseconds():
            if limit >= 0 and emitted >= limit:
                break
            items.append(current)
            current = current._shift_frame(frame, 1)
            emitted += 1
        return items^

    @staticmethod
    def range(frame: String, start: Self, limit: Int) raises -> List[Self]:
        """
        Return a limited number of points starting at start.
        """
        if limit < 0:
            raise Error("limit must be non-negative")
        var items = List[Self]()
        var current = start
        var emitted = 0
        while emitted < limit:
            items.append(current)
            current = current._shift_frame(frame, 1)
            emitted += 1
        return items^

    @staticmethod
    def range(
        frame: String,
        start: Self,
        end: Self,
        tz: TimeZone,
        limit: Int = -1,
    ) raises -> List[Self]:
        """
        Return points after replacing start and end timezones.
        """
        return Self.range(frame, start.replace(tz), end.replace(tz), limit)

    @staticmethod
    def range(
        frame: String,
        start: Self,
        end: Self,
        tz_str: String,
        limit: Int = -1,
    ) raises -> List[Self]:
        """
        Return points after replacing start and end with a parsed timezone.
        """
        return Self.range(frame, start, end, TimeZone.from_utc(tz_str), limit)

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
        return Self.range(frame, start.replace(tz), limit)

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
        return Self.range(frame, start, TimeZone.from_utc(tz_str), limit)

    @staticmethod
    def span_range(
        frame: String,
        start: Self,
        end: Self,
        limit: Int = -1,
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
        limit: Int = -1,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return spans after replacing start and end timezones.
        """
        return Self.span_range(
            frame,
            start.replace(tz),
            end.replace(tz),
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
        limit: Int = -1,
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
            TimeZone.from_utc(tz_str),
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
        limit: Int = -1,
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
        limit: Int = -1,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> List[MorrowSpan]:
        """
        Return grouped spans after replacing start and end timezones.
        """
        return Self.interval(
            frame,
            start.replace(tz),
            end.replace(tz),
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
        limit: Int = -1,
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
            TimeZone.from_utc(tz_str),
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

        while current._utc_microseconds() <= end_key:
            if limit >= 0 and emitted >= limit:
                break

            if exact:
                var next = current._shift_frame(frame, interval)
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
        if month < 1 or month > 12:
            raise Error("month must be in 1..12")
        if day < 1 or day > _days_in_month(year, month):
            raise Error("day is out of range for month")
        if hour < 0 or hour > 23:
            raise Error("hour must be in 0..23")
        if minute < 0 or minute > 59:
            raise Error("minute must be in 0..59")
        if second < 0 or second > 60:
            raise Error("second must be in 0..60")
        if microsecond < 0 or microsecond >= _US_PER_SECOND:
            raise Error("microsecond must be in 0..999999")

    @staticmethod
    def _utc_timezone() -> TimeZone:
        return TimeZone(0, "utc")

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
    def _parse_ordinal_suffix(date_str: String, date_pos: Int) raises -> Int:
        if date_pos + 2 > date_str.byte_length():
            raise Error("ordinal suffix is missing")
        var suffix = String(date_str[byte = date_pos : date_pos + 2])
        if suffix == "st" or suffix == "nd" or suffix == "rd" or suffix == "th":
            return date_pos + 2
        raise Error("ordinal suffix is invalid")

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
    ) raises -> Int:
        for value in range(1, 8):
            var name = day_abbreviation(value) if abbreviated else day_name(
                value
            )
            if Self._starts_with_ascii_case_insensitive(
                date_str, date_pos, name
            ):
                return date_pos + name.byte_length()
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
            return MorrowParseTimeZone(Self._utc_timezone(), date_pos + 3)
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

    @staticmethod
    def _auto_humanize_unit(seconds: Int) raises -> String:
        if seconds < 60:
            return "second"
        elif seconds < 3600:
            return "minute"
        elif seconds < 86400:
            return "hour"
        elif seconds < 604800:
            return "day"
        elif seconds < 2592000:
            return "week"
        elif seconds < 7776000:
            return "month"
        elif seconds < 31536000:
            return "quarter"
        else:
            return "year"

    @staticmethod
    def _humanize_count(seconds: Int, unit: String) raises -> Int:
        var unit_seconds = Self._humanize_unit_seconds(unit)
        var count = seconds // unit_seconds
        if count < 1:
            return 1
        return count

    @staticmethod
    def _humanize_unit_seconds(unit: String) raises -> Int:
        if unit == "second" or unit == "seconds":
            return 1
        elif unit == "minute" or unit == "minutes":
            return 60
        elif unit == "hour" or unit == "hours":
            return 3600
        elif unit == "day" or unit == "days":
            return 86400
        elif unit == "week" or unit == "weeks":
            return 604800
        elif unit == "month" or unit == "months":
            return 2592000
        elif unit == "quarter" or unit == "quarters":
            return 7776000
        elif unit == "year" or unit == "years":
            return 31536000
        else:
            raise Error("unsupported granularity")

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

    def format(self, fmt: String = "YYYY-MM-DD HH:mm:ss ZZ") raises -> String:
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
        return date.replace(Self._utc_timezone())

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

    def __sub__(self, other: Self) raises -> TimeDelta:
        var days1 = self.toordinal()
        var days2 = other.toordinal()
        var secs1 = self.second + self.minute * 60 + self.hour * 3600
        var secs2 = other.second + other.minute * 60 + other.hour * 3600
        var base = TimeDelta(
            days1 - days2, secs1 - secs2, self.microsecond - other.microsecond
        )
        return base


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
