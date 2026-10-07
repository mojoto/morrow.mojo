from ._text import is_digit, pad
from ._calendar import (
    US_PER_SECOND,
    US_PER_MINUTE,
    US_PER_HOUR,
    US_PER_DAY,
    SECONDS_PER_DAY,
    UNIX_EPOCH_ORDINAL,
    MAX_ORDINAL,
    MAX_TIMESTAMP,
    MAX_TIMESTAMP_MS,
    MAX_TIMESTAMP_US,
    days_in_month,
    ymd2ord,
    ord2ymd,
    isoweekday_of,
    day_of_year,
    iso_week1_monday,
    iso_calendar,
    epoch_seconds,
    normalize_timestamp,
    month_abbreviation,
    day_abbreviation,
)
from .locale import Locale, english_relative, is_english_locale, locale_grammar
from ._libc import (
    c_gettimeofday,
    c_gmtime,
    c_strptime,
    c_strptime_consumed,
    CTimeval,
)
from .timezone import TimeZone
from ._icu import Calendar
from .timedelta import TimeDelta
from .formatter import format_morrow, format_strftime
from std.iter import StopIteration
from std.collections import List
from std.format import Writable, Writer
from std.hashlib import Hasher
from ._parser import (
    _parse_iso_auto,
    _parse_arrow,
    _parse_arrow_formats,
    _from_strptime_tm,
    _find_strptime_extension_directive,
    _parse_strptime_timezone_name,
    _parse_strptime_timezone_offset,
    is_digit,
    _normalize_whitespace,
    _parse_isoformat,
)
from ._humanize import (
    _relative_locale,
    _humanize_text,
    _humanize_frame,
    _dehumanize_en,
    _rounded_seconds,
    _humanize_unit_seconds,
    _normalize_humanize_granularity_list,
)

comptime _UNBOUNDED_LIMIT = -2147483648


struct Morrow(
    Copyable, Equatable, Hashable, ImplicitlyCopyable, Movable, Writable
):
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
        tz: TimeZone = TimeZone(0, "UTC"),
        fold: Int = -1,
    ) raises:
        Self._validate_fields(
            year, month, day, hour, minute, second, microsecond
        )
        if tz.offset <= -86400 or tz.offset >= 86400:
            raise Error("UTC offset must be within 24 hours")
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
        self.tz = tz.resolve(year, month, day, hour, minute, second, fold)

    def __init__(out self, *, copy: Self):
        self.year = copy.year
        self.month = copy.month
        self.day = copy.day
        self.hour = copy.hour
        self.minute = copy.minute
        self.second = copy.second
        self.microsecond = copy.microsecond
        self.tz = copy.tz

    def __init__(out self, *, deinit move: Self):
        self.year = move.year
        self.month = move.month
        self.day = move.day
        self.hour = move.hour
        self.minute = move.minute
        self.second = move.second
        self.microsecond = move.microsecond
        self.tz = move.tz^

    @staticmethod
    def now() raises -> Self:
        """
        Return a Morrow object representing the current local date and time.
        """
        var t = c_gettimeofday()
        return Self._fromtimestamp(t, False)

    @staticmethod
    def now(tz: TimeZone) raises -> Self:
        """
        Return the current time converted to the target timezone.
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
    def utcnow() raises -> Self:
        """
        Return a Morrow object representing the current UTC date and time.
        """
        var t = c_gettimeofday()
        return Self._fromtimestamp(t, True)

    @staticmethod
    def min() raises -> Self:
        """
        Return the minimum supported UTC Morrow value.
        """
        return Self(1, 1, 1, 0, 0, 0, 0, Self._utc_timezone())

    @staticmethod
    def max() raises -> Self:
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
    def _fromtimestamp(t: CTimeval, utc: Bool) raises -> Self:
        var tm = c_gmtime(t.tv_sec)
        var result = Self(
            Int(tm.tm_year) + 1900,
            Int(tm.tm_mon) + 1,
            Int(tm.tm_mday),
            Int(tm.tm_hour),
            Int(tm.tm_min),
            Int(tm.tm_sec),
            t.tv_usec,
        )
        if utc:
            return result
        return result.to("local")

    @staticmethod
    def _fromtimestamp_checked(t: CTimeval, utc: Bool) raises -> Self:
        if t.tv_sec < -62135596800 or t.tv_sec > 253402300799:
            raise Error("timestamp exceeds supported years 1..9999")
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
                seconds = timestamp // US_PER_SECOND
                microseconds = timestamp % US_PER_SECOND
            else:
                raise Error("timestamp is too large")
        return CTimeval(seconds, microseconds)

    @staticmethod
    def _timeval_from_timestamp(timestamp: Float64) raises -> CTimeval:
        var timestamp_ = normalize_timestamp(timestamp)
        if not (timestamp_ >= -62135596800.0 and timestamp_ < 253402300800.0):
            raise Error("timestamp must be finite and within years 1..9999")
        var seconds = Int(timestamp_)
        if Float64(seconds) > timestamp_:
            seconds -= 1
        var microseconds = Int(
            (timestamp_ - Float64(seconds)) * 1000000.0 + 0.5
        )
        if microseconds >= US_PER_SECOND:
            seconds += 1
            microseconds -= US_PER_SECOND
        return CTimeval(seconds, microseconds)

    @staticmethod
    def get() raises -> Self:
        """
        Create a UTC Morrow for the current time.
        """
        return Self.utcnow()

    @staticmethod
    def get(tz: TimeZone) raises -> Self:
        """
        Create a Morrow for the current time converted to the target timezone.
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
        Create a Morrow from date components and a timezone.
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
        Create a Morrow from date and time components with a timezone.
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
        Create a Morrow from a POSIX timestamp converted to the target timezone.
        """
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def get(timestamp: Float64, tz: TimeZone) raises -> Self:
        """
        Create a Morrow from a POSIX timestamp converted to the target timezone.
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
        return _parse_iso_auto(date_str)

    @staticmethod
    def get(date_str: String, normalize_whitespace: Bool) raises -> Self:
        """
        Create a UTC Morrow from an ISO 8601 string, optionally normalizing ASCII whitespace.
        """
        if normalize_whitespace:
            return _parse_iso_auto(_normalize_whitespace(date_str))
        return _parse_iso_auto(date_str)

    @staticmethod
    def get(date_str: String, formats: List[String]) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order.
        """
        return _parse_arrow_formats(date_str, formats)

    @staticmethod
    def get(
        date_str: String, formats: List[String], normalize_whitespace: Bool
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order, optionally normalizing ASCII whitespace.
        """
        if not normalize_whitespace:
            return _parse_arrow_formats(date_str, formats)

        var normalized_formats = List[String]()
        for i in range(len(formats)):
            normalized_formats.append(_normalize_whitespace(formats[i]))
        return _parse_arrow_formats(
            _normalize_whitespace(date_str), normalized_formats
        )

    @staticmethod
    def get(
        date_str: String, formats: List[String], tz: TimeZone
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order and replacing timezone.
        """
        return _parse_arrow_formats(date_str, formats, tz)

    @staticmethod
    def get(
        date_str: String,
        formats: List[String],
        tz: TimeZone,
        normalize_whitespace: Bool,
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order with replacement timezone, optionally normalizing ASCII whitespace.
        """
        if not normalize_whitespace:
            return _parse_arrow_formats(date_str, formats, tz)

        var normalized_formats = List[String]()
        for i in range(len(formats)):
            normalized_formats.append(_normalize_whitespace(formats[i]))
        return _parse_arrow_formats(
            _normalize_whitespace(date_str), normalized_formats, tz
        )

    @staticmethod
    def get(
        date_str: String, formats: List[String], tz_str: String
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order and parsed replacement timezone.
        """
        return _parse_arrow_formats(
            date_str, formats, Self._parse_timezone_argument(tz_str)
        )

    @staticmethod
    def get(
        date_str: String,
        formats: List[String],
        tz_str: String,
        normalize_whitespace: Bool,
    ) raises -> Self:
        """
        Create a Morrow by trying Arrow format tokens in order with parsed replacement timezone, optionally normalizing ASCII whitespace.
        """
        return Self.get(
            date_str,
            formats,
            Self._parse_timezone_argument(tz_str),
            normalize_whitespace,
        )

    @staticmethod
    def get(date_str: String, fmt: String) raises -> Self:
        """
        Create a Morrow by parsing a string with Arrow format tokens.
        """
        return _parse_arrow(date_str, fmt)

    @staticmethod
    def get(
        date_str: String, fmt: String, normalize_whitespace: Bool
    ) raises -> Self:
        """
        Create a Morrow by parsing Arrow tokens, optionally normalizing ASCII whitespace.
        """
        if normalize_whitespace:
            return _parse_arrow(
                _normalize_whitespace(date_str),
                _normalize_whitespace(fmt),
            )
        return _parse_arrow(date_str, fmt)

    @staticmethod
    def get(date_str: String, fmt: String, tz: TimeZone) raises -> Self:
        """
        Create a Morrow by parsing a string with Arrow format tokens and replacement timezone.
        """
        return _parse_arrow(date_str, fmt, tz)

    @staticmethod
    def get(
        date_str: String,
        fmt: String,
        tz: TimeZone,
        normalize_whitespace: Bool,
    ) raises -> Self:
        """
        Create a Morrow by parsing Arrow tokens with replacement timezone, optionally normalizing ASCII whitespace.
        """
        if normalize_whitespace:
            return _parse_arrow(
                _normalize_whitespace(date_str),
                _normalize_whitespace(fmt),
                tz,
            )
        return _parse_arrow(date_str, fmt, tz)

    @staticmethod
    def get(date_str: String, fmt: String, tz_str: String) raises -> Self:
        """
        Create a Morrow by parsing a string with Arrow format tokens and parsed replacement timezone.
        """
        return _parse_arrow(
            date_str, fmt, Self._parse_timezone_argument(tz_str)
        )

    @staticmethod
    def get(
        date_str: String,
        fmt: String,
        tz_str: String,
        normalize_whitespace: Bool,
    ) raises -> Self:
        """
        Create a Morrow by parsing Arrow tokens with parsed replacement timezone, optionally normalizing ASCII whitespace.
        """
        return Self.get(
            date_str,
            fmt,
            Self._parse_timezone_argument(tz_str),
            normalize_whitespace,
        )

    @staticmethod
    def get(date: MorrowDate) raises -> Self:
        """
        Create a UTC Morrow from a date view.
        """
        return Self.fromdate(date)

    @staticmethod
    def get(date: MorrowDate, tz: TimeZone) raises -> Self:
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
    def get(dt: Self) raises -> Self:
        """
        Create a Morrow from another Morrow object.
        """
        return Self.fromdatetime(dt)

    @staticmethod
    def get(dt: Self, tz: TimeZone) raises -> Self:
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
    def get(value: MorrowTimeTuple) raises -> Self:
        """
        Create a UTC Morrow from time tuple fields, like Arrow's `struct_time`.
        """
        return Self(
            value.year, value.mon, value.mday, value.hour, value.min, value.sec
        )

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
        return _parse_isoformat(date_str)

    @staticmethod
    def _locale_for(name: String) raises -> Locale:
        """Resolve a locale name, keeping English on the built-in fast path."""
        if is_english_locale(name):
            return Locale._fast_english()
        return Locale(name, _names=True, _relative=False)

    @staticmethod
    def get(
        date_str: String,
        fmt: String,
        *,
        locale: String,
        tz: TimeZone = TimeZone.none(),
        normalize_whitespace: Bool = False,
    ) raises -> Self:
        return Self.get(
            date_str,
            fmt,
            locale=Self._locale_for(locale),
            tz=tz,
            normalize_whitespace=normalize_whitespace,
        )

    @staticmethod
    def get(
        date_str: String,
        fmt: String,
        *,
        locale: Locale,
        tz: TimeZone = TimeZone.none(),
        normalize_whitespace: Bool = False,
    ) raises -> Self:
        var value = _normalize_whitespace(
            date_str
        ) if normalize_whitespace else date_str
        var pattern = _normalize_whitespace(
            fmt
        ) if normalize_whitespace else fmt
        return _parse_arrow(value, pattern, tz, locale)

    @staticmethod
    def get(
        date_str: String,
        formats: List[String],
        *,
        locale: String,
        tz: TimeZone = TimeZone.none(),
        normalize_whitespace: Bool = False,
    ) raises -> Self:
        return Self.get(
            date_str,
            formats,
            locale=Self._locale_for(locale),
            tz=tz,
            normalize_whitespace=normalize_whitespace,
        )

    @staticmethod
    def get(
        date_str: String,
        formats: List[String],
        *,
        locale: Locale,
        tz: TimeZone = TimeZone.none(),
        normalize_whitespace: Bool = False,
    ) raises -> Self:
        for fmt in formats:
            try:
                return Self.get(
                    date_str,
                    fmt,
                    locale=locale,
                    tz=tz,
                    normalize_whitespace=normalize_whitespace,
                )
            except e:
                pass
        raise Error("date string does not match any format")

    @staticmethod
    def fromdate(date: MorrowDate) raises -> Self:
        """
        Construct a Morrow from a date view. Time fields are set to zero.
        """
        return Self.fromdate(date, Self._utc_timezone())

    @staticmethod
    def fromdate(date: MorrowDate, tz: TimeZone) raises -> Self:
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
    def fromdatetime(dt: Self) raises -> Self:
        """
        Construct a Morrow from another Morrow object.
        """
        if dt.tz.is_none():
            return Self.fromdatetime(dt, Self._utc_timezone())
        return dt.clone()

    @staticmethod
    def fromdatetime(dt: Self, tz: TimeZone) raises -> Self:
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
        date_str: String,
        fmt: String,
        tzinfo: TimeZone = TimeZone.none(),
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
            var directive = _find_strptime_extension_directive(normalized_fmt)
            if directive.pos == -1:
                break

            var prefix_fmt = String(normalized_fmt[byte = 0 : directive.pos])
            var value_start = c_strptime_consumed(normalized_date, prefix_fmt)
            var value_end: Int
            if directive.value == ord("f"):
                value_end = value_start
                while (
                    value_end < normalized_date.byte_length()
                    and is_digit(Int(normalized_date.as_bytes()[value_end]))
                    and value_end - value_start < 6
                ):
                    value_end += 1
                if value_end == value_start:
                    raise Error("microsecond is missing")
                if value_end < normalized_date.byte_length() and is_digit(
                    Int(normalized_date.as_bytes()[value_end])
                ):
                    raise Error("unconverted data remains")

                var digits = String(normalized_date[byte=value_start:value_end])
                while digits.byte_length() < 6:
                    digits += "0"
                microsecond = Int(digits)
            elif directive.value == ord("z"):
                var parsed = _parse_strptime_timezone_offset(
                    normalized_date, value_start
                )
                value_end = parsed.pos
                parsed_tz = parsed.tz
            else:
                var parsed = _parse_strptime_timezone_name(
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
        return _from_strptime_tm(tm, microsecond, tzinfo, parsed_tz)

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

    def clone(self) raises -> Self:
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

    def datetime(self) raises -> Self:
        """
        Return a datetime representation of this Morrow.
        """
        return self.clone()

    def naive(self) raises -> Self:
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
            return -((-total_us) // US_PER_SECOND)
        return total_us // US_PER_SECOND

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
            + pad(self.day, 2, " ")
            + " "
            + pad(self.hour, 2)
            + ":"
            + pad(self.minute, 2)
            + ":"
            + pad(self.second, 2)
            + " "
            + pad(self.year, 4)
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

    def tz_abbreviation(self) -> String:
        """
        Return the timezone abbreviation in effect, such as "EDT" or "CST".

        Named zones read the system tzdata abbreviation, matching Python's
        zoneinfo and Arrow's `ZZZ`; tzdata writes zones without letters as
        numeric offsets such as "+08". Fixed offsets return `tzname()`, and
        naive values return an empty string.
        """
        if self.tz.is_none():
            return ""
        if self.tz.zone == "":
            return self.tzname()
        if self.tz._data:
            return self.tz._data.value()[].abbreviation(
                self._utc_microseconds() // US_PER_SECOND
            )
        var offset = abs(self.tz.offset)
        var result = String("-" if self.tz.offset < 0 else "+")
        result += pad(offset // 3600, 2)
        if offset % 3600 != 0:
            result += pad((offset % 3600) // 60, 2)
        return result

    def utcoffset(self) -> TimeDelta:
        """
        Return this Morrow's resolved UTC offset.
        """
        return TimeDelta(seconds=self.tz.offset)

    def dst(self) -> TimeDelta:
        """
        Return daylight-saving offset. Fixed-offset timezones have none.
        """
        return TimeDelta(seconds=self.tz.dst_seconds)

    def fold(self) -> Int:
        """
        Return the fold value. Fixed-offset timezones do not repeat wall times.
        """
        return self.tz.fold_value

    def ambiguous(self) -> Bool:
        """
        Return whether this wall time is ambiguous in its timezone.
        """
        return self.tz.is_ambiguous

    def imaginary(self) -> Bool:
        """
        Return whether this wall time is nonexistent in its timezone.
        """
        return self.tz.is_imaginary

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

    def humanize(self, *, locale: String = "en") raises -> String:
        return self.humanize(locale=_relative_locale(locale))

    def humanize(self, *, locale: Locale) raises -> String:
        return _humanize_text(self, Self.utcnow(), False, "auto", locale)

    def humanize(
        self, only_distance: Bool, *, locale: String = "en"
    ) raises -> String:
        return self.humanize(only_distance, locale=_relative_locale(locale))

    def humanize(self, only_distance: Bool, *, locale: Locale) raises -> String:
        return _humanize_text(
            self, Self.utcnow(), only_distance, "auto", locale
        )

    def humanize(
        self,
        other: Self,
        only_distance: Bool = False,
        granularity: String = "auto",
        *,
        locale: String = "en",
    ) raises -> String:
        return self.humanize(
            other,
            only_distance,
            granularity,
            locale=_relative_locale(locale),
        )

    def humanize(
        self,
        other: Self,
        only_distance: Bool = False,
        granularity: String = "auto",
        *,
        locale: Locale,
    ) raises -> String:
        return _humanize_text(self, other, only_distance, granularity, locale)

    def humanize(
        self, other: Self, granularity: List[String], *, locale: String = "en"
    ) raises -> String:
        return self.humanize(
            other, False, granularity, locale=_relative_locale(locale)
        )

    def humanize(
        self, other: Self, granularity: List[String], *, locale: Locale
    ) raises -> String:
        return self.humanize(other, False, granularity, locale=locale)

    def humanize(
        self,
        other: Self,
        only_distance: Bool,
        granularity: List[String],
        *,
        locale: String = "en",
    ) raises -> String:
        return self.humanize(
            other,
            only_distance,
            granularity,
            locale=_relative_locale(locale),
        )

    def humanize(
        self,
        other: Self,
        only_distance: Bool,
        granularity: List[String],
        *,
        locale: Locale,
    ) raises -> String:
        if len(granularity) == 0:
            raise Error("granularity cannot be empty")
        if len(granularity) == 1 and granularity[0] == "auto":
            return _humanize_text(self, other, only_distance, "auto", locale)

        var ordered_granularity = _normalize_humanize_granularity_list(
            granularity
        )
        self._check_awareness(other)
        var delta_us = self._utc_microseconds() - other._utc_microseconds()
        var rounded_delta_seconds = _rounded_seconds(delta_us)
        var remaining = abs(rounded_delta_seconds)
        if (
            len(ordered_granularity) == 1
            and ordered_granularity[0] == "second"
            and remaining < 2
        ):
            return locale._describe(0, 0, False, only_distance)

        var negative = rounded_delta_seconds < 0
        var frames = List[Int]()
        var deltas = List[Int]()
        for i in range(len(ordered_granularity)):
            var unit = ordered_granularity[i]
            var unit_seconds = _humanize_unit_seconds(unit)
            var count = remaining // unit_seconds
            frames.append(_humanize_frame(unit, count))
            deltas.append(-count if negative else count)
            remaining = remaining % unit_seconds
        if len(frames) == 1:
            return locale._describe(
                frames[0], deltas[0], negative, only_distance
            )
        return locale._describe_multi(frames, deltas, negative, only_distance)

    def dehumanize(
        self, input_string: String, *, locale: String = "en"
    ) raises -> Self:
        var grammar = locale_grammar(locale)
        if grammar == 1:
            return _dehumanize_en(self, input_string)
        if grammar == 2:
            return _dehumanize_en(self, english_relative(input_string))
        return self.dehumanize(input_string, locale=_relative_locale(locale))

    def dehumanize(
        self, input_string: String, *, locale: Locale
    ) raises -> Self:
        """
        Shift this Morrow by relative text in the grammar of locale.
        """
        var parts = locale._parse_relative(input_string)
        if len(parts.units) == 0:
            return self
        return self.shift(
            years=parts.count("years"),
            quarters=parts.count("quarters"),
            months=parts.count("months"),
            weeks=parts.count("weeks"),
            days=parts.count("days"),
            hours=parts.count("hours"),
            minutes=parts.count("minutes"),
            seconds=parts.count("seconds"),
        )

    def to(self, tz: TimeZone) raises -> Self:
        """Convert an instant using the target zone's rules at that instant."""
        return Self._from_instant_microseconds(self._utc_microseconds(), tz)

    @staticmethod
    def _from_instant_microseconds(stamp: Int, tz: TimeZone) raises -> Self:
        var seconds = stamp // US_PER_SECOND
        if stamp % US_PER_SECOND < 0:
            seconds -= 1
        if tz._data:
            ref data = tz._data.value()[]
            var info = data.info_at(seconds)
            var local = Self._from_utc_microseconds_value(
                stamp + info.offset * US_PER_SECOND
            )
            var wall = epoch_seconds(
                local.year,
                local.month,
                local.day,
                local.hour,
                local.minute,
                local.second,
            )
            var resolved = data.resolve_wall(wall, 0)
            var zone = tz
            zone.offset = info.offset
            zone.dst_seconds = info.dst
            zone.fold_value = 1 if (
                resolved.ambiguous and resolved.offset != info.offset
            ) else 0
            zone.is_ambiguous = resolved.ambiguous
            zone.is_imaginary = False
            local.tz = zone^
            return local
        if tz.zone != "":
            # One calendar serves the instant lookup and the wall resolution.
            var calendar = Calendar(tz.zone)
            var info = calendar.at(seconds)
            var local = Self._from_utc_microseconds_value(
                stamp + info.offset * US_PER_SECOND
            )
            var zone = tz
            zone.fold_value = 0
            var resolved = zone._resolve_with(
                calendar,
                local.year,
                local.month,
                local.day,
                local.hour,
                local.minute,
                local.second,
            )
            if resolved.offset != info.offset and resolved.is_ambiguous:
                zone.fold_value = 1
                resolved = zone._resolve_with(
                    calendar,
                    local.year,
                    local.month,
                    local.day,
                    local.hour,
                    local.minute,
                    local.second,
                )
            local.tz = resolved
            return local
        var target = tz.at(seconds)
        var wall = Self._from_utc_microseconds_value(
            stamp + target.offset * US_PER_SECOND
        )
        var candidate = Self(
            wall.year,
            wall.month,
            wall.day,
            wall.hour,
            wall.minute,
            wall.second,
            wall.microsecond,
            target,
            fold=0,
        )
        if candidate._utc_microseconds() != stamp and candidate.ambiguous():
            return candidate.replace(fold=1)
        return candidate

    def to(self, tz_str: String) raises -> Self:
        """
        Return this instant converted to a timezone parsed from a UTC offset string.
        """
        return self.to(Self._parse_timezone_argument(tz_str))

    def astimezone(self, tz: TimeZone) raises -> Self:
        """
        Return this instant converted to the target timezone.
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
        fold: Int = -1,
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
            year_,
            month_,
            day_,
            hour_,
            minute_,
            second_,
            microsecond_,
            tzinfo_,
            fold,
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
        fold: Int = -1,
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
            fold,
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
        check_imaginary: Bool = True,
    ) raises -> Self:
        """
        Return a new Morrow shifted by relative date and time offsets.
        """
        if (
            years < -9999
            or years > 9999
            or months < -119988
            or months > 119988
            or quarters < -39996
            or quarters > 39996
            or weeks < -521723
            or weeks > 521723
        ):
            raise Error("calendar shift exceeds supported years 1..9999")
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
        var max_day = days_in_month(year, month)
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
        var result = shifted._shift_day_time(day_offset, 0, 0, 0, 0)
        if result.imaginary() and check_imaginary:
            result = result.to(result.tz)
        if hours != 0 or minutes != 0 or seconds != 0 or microseconds != 0:
            # Validate before TimeDelta multiplies user-supplied values.
            Self._validate_day_time_args(
                0, hours, minutes, seconds, microseconds
            )
            return result + TimeDelta(
                hours=hours,
                minutes=minutes,
                seconds=seconds,
                microseconds=microseconds,
            )
        return result

    def shift_weekday(self, weekday: Int, nth: Int = 1) raises -> Self:
        """Move to the nth weekday on/after (positive) or on/before (negative) self.

        Monday is 0. nth=1 or -1 includes today when it matches.
        """
        if (
            weekday < 0
            or weekday > 6
            or nth == 0
            or nth < -520000
            or nth > 520000
        ):
            raise Error(
                "weekday must be 0..6 and nth must be nonzero within +/-520000"
            )
        var delta = weekday - self.weekday()
        if nth > 0:
            return self.shift(days=(delta + 7) % 7 + 7 * (nth - 1))
        return self.shift(days=-((7 - delta) % 7) + 7 * (nth + 1))

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
        for item in Self.iter_range(frame, start, end, limit):
            items.append(item)
        return items^

    @staticmethod
    def range(frame: String, start: Self, limit: Int) raises -> List[Self]:
        """
        Return a limited number of points starting at start.
        """
        return Self.range(
            frame,
            start,
            Self.max()
            .replace(tzinfo=start.tz) if not start.tz.is_none() else Self.max()
            .naive(),
            limit,
        )

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
        return Self._interval_range(
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
        var result = List[MorrowSpan]()
        for span in MorrowSpanIterator(
            frame, start, end, interval, limit, bounds, exact, week_start
        ):
            result.append(span)
        return result^

    @staticmethod
    def _interval_range(
        frame: String,
        start: Self,
        end: Self,
        interval: Int,
        limit: Int,
        bounds: String,
        exact: Bool,
        week_start: Int,
    ) raises -> List[MorrowSpan]:
        var result = List[MorrowSpan]()
        for span in Self.iter_interval(
            frame, start, end, interval, limit, bounds, exact, week_start
        ):
            result.append(span)
        return result^

    @staticmethod
    def iter_range(
        frame: String, start: Self, end: Self, limit: Int = _UNBOUNDED_LIMIT
    ) raises -> MorrowIterator:
        return MorrowIterator(frame, start, end, limit)

    @staticmethod
    def iter_range(
        frame: String, start: Self, limit: Int
    ) raises -> MorrowIterator:
        return MorrowIterator(
            frame,
            start,
            Self.max()
            .replace(tzinfo=start.tz) if not start.tz.is_none() else Self.max()
            .naive(),
            limit,
        )

    @staticmethod
    def iter_span_range(
        frame: String,
        start: Self,
        end: Self,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> MorrowSpanIterator:
        return MorrowSpanIterator(
            frame, start, end, 1, limit, bounds, exact, week_start
        )

    @staticmethod
    def iter_interval(
        frame: String,
        start: Self,
        end: Self,
        interval: Int = 1,
        limit: Int = _UNBOUNDED_LIMIT,
        bounds: String = "[)",
        exact: Bool = False,
        week_start: Int = 1,
    ) raises -> MorrowIntervalIterator:
        return MorrowIntervalIterator(
            frame, start, end, interval, limit, bounds, exact, week_start
        )

    @staticmethod
    def _span_from_bounds(
        start: Self, end: Self, bounds: String
    ) raises -> MorrowSpan:
        var start_ = start
        var end_ = end
        if Int(bounds.as_bytes()[0]) == 40:  # (
            start_ = start_.shift(microseconds=1)
        if Int(bounds.as_bytes()[1]) == 41:  # )
            end_ = end_.shift(microseconds=-1)
        return MorrowSpan(start_, end_)

    def is_between(
        self, start: Self, end: Self, bounds: String = "()"
    ) raises -> Bool:
        """
        Return True when this Morrow is between start and end.
        """
        Self._validate_bounds(bounds)
        self._check_awareness(start)
        self._check_awareness(end)
        var value = self._utc_microseconds()
        var low = start._utc_microseconds()
        var high = end._utc_microseconds()

        var left: Bool
        if Int(bounds.as_bytes()[0]) == 91:  # [
            left = value >= low
        else:
            left = value > low

        var right: Bool
        if Int(bounds.as_bytes()[1]) == 93:  # ]
            right = value <= high
        else:
            right = value < high

        return left and right

    @staticmethod
    def _validate_bounds(bounds: String) raises:
        if bounds.byte_length() != 2:
            raise Error("bounds must be one of [), [], (), (]")
        var left = Int(bounds.as_bytes()[0])
        var right = Int(bounds.as_bytes()[1])
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
            if shifted.day < original_day and original_day <= days_in_month(
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
        if day < 1 or day > days_in_month(year, month):
            raise Error("day is out of range for month")
        if hour < 0 or hour > 23:
            raise Error("hour must be in 0..23")
        if minute < 0 or minute > 59:
            raise Error("minute must be in 0..59")
        if second < 0 or second > 59:
            raise Error("second must be in 0..59")
        if microsecond < 0 or microsecond >= US_PER_SECOND:
            raise Error("microsecond must be in 0..999999")

    @staticmethod
    def _utc_timezone() -> TimeZone:
        return TimeZone(0, "utc")

    @staticmethod
    def _parse_timezone_argument(tz_str: String) raises -> TimeZone:
        if tz_str == "local":
            return TimeZone.local()
        try:
            return TimeZone.from_utc(tz_str)
        except e:
            return TimeZone.from_name(tz_str)

    @staticmethod
    def _from_utc_microseconds_value(total_us: Int) raises -> Self:
        var seconds = total_us // US_PER_SECOND
        var microsecond = total_us % US_PER_SECOND
        if microsecond < 0:
            seconds -= 1
            microsecond += US_PER_SECOND

        var days = seconds // SECONDS_PER_DAY
        var seconds_in_day = seconds % SECONDS_PER_DAY
        if seconds_in_day < 0:
            days -= 1
            seconds_in_day += SECONDS_PER_DAY

        var date = Self.fromordinal(UNIX_EPOCH_ORDINAL + days)
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
        return Self.utcfromtimestamp(normalize_timestamp(Float64(timestamp)))

    @staticmethod
    def _validate_day_time_args(
        days: Int, hours: Int, minutes: Int, seconds: Int, microseconds: Int
    ) raises:
        if (
            days < -3652059
            or days > 3652059
            or hours < -87649416
            or hours > 87649416
            or minutes < -5258964960
            or minutes > 5258964960
            or seconds < -315537897600
            or seconds > 315537897600
            or microseconds < -315537897600000000
            or microseconds > 315537897600000000
        ):
            raise Error("time shift exceeds supported years 1..9999")

    def _shift_day_time(
        self,
        days: Int,
        hours: Int,
        minutes: Int,
        seconds: Int,
        microseconds: Int,
    ) raises -> Self:
        Self._validate_day_time_args(
            days, hours, minutes, seconds, microseconds
        )
        var total_us = (
            (self.hour * 3600 + self.minute * 60 + self.second) * US_PER_SECOND
            + self.microsecond
            + hours * US_PER_HOUR
            + minutes * US_PER_MINUTE
            + seconds * US_PER_SECOND
            + microseconds
        )
        var extra_days = total_us // US_PER_DAY
        var remaining_us = total_us % US_PER_DAY
        var date = Self.fromordinal(self.toordinal() + days + extra_days)
        var hour = remaining_us // US_PER_HOUR
        remaining_us = remaining_us % US_PER_HOUR
        var minute = remaining_us // US_PER_MINUTE
        remaining_us = remaining_us % US_PER_MINUTE
        var second = remaining_us // US_PER_SECOND
        var microsecond = remaining_us % US_PER_SECOND
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

    def _check_awareness(self, other: Self) raises:
        if self.tz.is_none() != other.tz.is_none():
            raise Error("cannot mix naive and timezone-aware dates")

    def _utc_microseconds(self) -> Int:
        var seconds = epoch_seconds(
            self.year, self.month, self.day, self.hour, self.minute, self.second
        )
        return (seconds - self.tz.offset) * US_PER_SECOND + self.microsecond

    def _time_tuple(self) raises -> MorrowTimeTuple:
        return MorrowTimeTuple(
            self.year,
            self.month,
            self.day,
            self.hour,
            self.minute,
            self.second,
            self.weekday(),
            day_of_year(self.year, self.month, self.day),
            1 if self.tz.dst_seconds != 0 else 0,
        )

    def format(
        self, fmt: String = "YYYY-MM-DD HH:mm:ssZZ", *, locale: String = "en"
    ) raises -> String:
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
        if is_english_locale(locale):
            return self._format_tokens(fmt)
        return self.format(
            fmt, locale=Locale(locale, _names=True, _relative=False)
        )

    def format(self, fmt: String, *, locale: Locale) raises -> String:
        """Format with month, weekday, ordinal and AM/PM text from locale."""
        if locale.is_fast_english():
            return self._format_tokens(fmt)
        return self._format_tokens(
            locale._localize_format(
                fmt,
                self.year,
                self.month,
                self.day,
                self.isoweekday(),
                self.hour,
            )
        )

    def _format_tokens(self, fmt: String) raises -> String:
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
                    pad(self.hour, 2)
                    + ":"
                    + pad(self.minute, 2)
                    + ":"
                    + pad(self.second, 2)
                )
            else:
                time_str = self._time_string_microseconds()
        elif timespec == "microseconds":
            time_str = self._time_string_microseconds()
        elif timespec == "milliseconds":
            time_str = (
                pad(self.hour, 2)
                + ":"
                + pad(self.minute, 2)
                + ":"
                + pad(self.second, 2)
                + "."
                + pad(self.microsecond // 1000, 3)
            )
        elif timespec == "seconds":
            time_str = (
                pad(self.hour, 2)
                + ":"
                + pad(self.minute, 2)
                + ":"
                + pad(self.second, 2)
            )
        elif timespec == "minutes":
            time_str = pad(self.hour, 2) + ":" + pad(self.minute, 2)
        elif timespec == "hours":
            time_str = pad(self.hour, 2)
        else:
            raise Error()
        if self.tz.is_none():
            return date_str + sep + time_str
        else:
            return date_str + sep + time_str + self.tz.format()

    def _date_string(self) -> String:
        return (
            pad(self.year, 4)
            + "-"
            + pad(self.month, 2)
            + "-"
            + pad(self.day, 2)
        )

    def _time_string_microseconds(self) -> String:
        return (
            pad(self.hour, 2)
            + ":"
            + pad(self.minute, 2)
            + ":"
            + pad(self.second, 2)
            + "."
            + pad(self.microsecond, 6)
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

    def toordinal(self) -> Int:
        """
        Return the proleptic Gregorian ordinal of the date, where January 1 of year 1 has ordinal 1.
        """
        return ymd2ord(self.year, self.month, self.day)

    @staticmethod
    def fromordinal(ordinal: Int) raises -> Self:
        """
        Construct a Morrow object from a proleptic Gregorian ordinal.

        January 1 of year 1 is day 1. Only the year, month and day are non-zero in the result.
        """
        if ordinal < 1 or ordinal > MAX_ORDINAL:
            raise Error("ordinal is out of range")
        var ymd = ord2ymd(ordinal)
        return Self(ymd[0], ymd[1], ymd[2])

    @staticmethod
    def fromisocalendar(
        iso_year: Int, iso_week: Int, iso_weekday: Int
    ) raises -> Self:
        """
        Construct a UTC Morrow from ISO year, week, and weekday fields.
        """
        if iso_weekday < 1 or iso_weekday > 7:
            raise Error("iso_weekday must be in 1..7")
        var week1 = iso_week1_monday(iso_year)
        var next_week1 = iso_week1_monday(iso_year + 1)
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
        return isoweekday_of(self.toordinal())

    def isocalendar(self) raises -> MorrowIsoCalendar:
        """
        Return the ISO year, week number, and ISO weekday.
        """
        var iso = iso_calendar(self.year, self.month, self.day)
        return MorrowIsoCalendar(iso[0], iso[1], iso[2])

    def weekday(self) raises -> Int:
        """
        Return the day of the week as an integer, where Monday is 0 and Sunday is 6.
        """
        return self.isoweekday() - 1

    def __str__(self) raises -> String:
        return self.isoformat()

    def __eq__(self, other: Self) -> Bool:
        """Equal instants; naive and aware values are never equal."""
        if self.tz.is_none() != other.tz.is_none():
            return False
        return self._utc_microseconds() == other._utc_microseconds()

    def __ne__(self, other: Self) -> Bool:
        return not self == other

    def __hash__[H: Hasher](self, mut hasher: H):
        """Hash consistently with `==`: equal instants hash equally."""
        self.tz.is_none().__hash__(hasher)
        self._utc_microseconds().__hash__(hasher)

    def __le__(self, other: Self) raises -> Bool:
        self._check_awareness(other)
        return self._utc_microseconds() <= other._utc_microseconds()

    def __lt__(self, other: Self) raises -> Bool:
        self._check_awareness(other)
        return self._utc_microseconds() < other._utc_microseconds()

    def __ge__(self, other: Self) raises -> Bool:
        self._check_awareness(other)
        return self._utc_microseconds() >= other._utc_microseconds()

    def __gt__(self, other: Self) raises -> Bool:
        self._check_awareness(other)
        return self._utc_microseconds() > other._utc_microseconds()

    def __add__(self, delta: TimeDelta) raises -> Self:
        if not self.tz.is_none():
            if delta.days < -3652059 or delta.days > 3652059:
                raise Error("duration exceeds supported calendar")
            return Self._from_instant_microseconds(
                self._utc_microseconds() + delta._to_microseconds(), self.tz
            )
        return self._shift_day_time(
            delta.days, 0, 0, delta.seconds, delta.microseconds
        )

    def __radd__(self, delta: TimeDelta) raises -> Self:
        return self + delta

    def __sub__(self, delta: TimeDelta) raises -> Self:
        return self + (-delta)

    def __sub__(self, other: Self) raises -> TimeDelta:
        self._check_awareness(other)
        return TimeDelta(
            microseconds=self._utc_microseconds() - other._utc_microseconds()
        )


struct MorrowSpan(Copyable, ImplicitlyCopyable, Movable, Writable):
    var start: Morrow
    var end: Morrow

    def __init__(out self, start: Morrow, end: Morrow):
        self.start = start
        self.end = end

    def __init__(out self, *, copy: Self):
        self.start = copy.start
        self.end = copy.end

    def __init__(out self, *, deinit move: Self):
        self.start = move.start^
        self.end = move.end^

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            "MorrowSpan(start="
            + self.start._isoformat_auto()
            + ", end="
            + self.end._isoformat_auto()
            + ")"
        )


struct MorrowIsoCalendar(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var week: Int
    var weekday: Int

    def __init__(out self, year: Int, week: Int, weekday: Int):
        self.year = year
        self.week = week
        self.weekday = weekday

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            "MorrowIsoCalendar(year="
            + String(self.year)
            + ", week="
            + String(self.week)
            + ", weekday="
            + String(self.weekday)
            + ")"
        )


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
            pad(self.year, 4)
            + "-"
            + pad(self.month, 2)
            + "-"
            + pad(self.day, 2)
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
            pad(self.hour, 2)
            + ":"
            + pad(self.minute, 2)
            + ":"
            + pad(self.second, 2)
            + "."
            + pad(self.microsecond, 6)
        )
        if not self.tz.is_none():
            result += self.tz.format()
        return result


struct MorrowTimeTuple(Copyable, ImplicitlyCopyable, Movable, Writable):
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

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            "MorrowTimeTuple(year="
            + String(self.year)
            + ", mon="
            + String(self.mon)
            + ", mday="
            + String(self.mday)
            + ", hour="
            + String(self.hour)
            + ", min="
            + String(self.min)
            + ", sec="
            + String(self.sec)
            + ", wday="
            + String(self.wday)
            + ", yday="
            + String(self.yday)
            + ", isdst="
            + String(self.isdst)
            + ")"
        )


struct MorrowIterator(Copyable, ImplicitlyCopyable, Movable):
    """A constant-memory iterator over calendar points."""

    var frame: String
    var current: Morrow
    var end: Morrow
    var remaining: Int
    var original_day: Int
    var started: Bool

    def __init__(
        out self, frame: String, start: Morrow, end: Morrow, limit: Int
    ) raises:
        start._check_awareness(end)
        _ = start._floor_frame(frame)
        self.frame = frame
        self.current = start
        self.end = end
        self.remaining = limit
        self.original_day = start.day
        self.started = False

    def __iter__(self) -> Self:
        return self

    def __next__(mut self) raises -> Morrow:
        if self.remaining != _UNBOUNDED_LIMIT and self.remaining <= 0:
            raise StopIteration()
        if self.started:
            if self.current >= self.end:
                raise StopIteration()
            self.current = self.current._shift_frame_preserving_day(
                self.frame, 1, self.original_day
            )
        if self.current > self.end:
            raise StopIteration()
        self.started = True
        if self.remaining != _UNBOUNDED_LIMIT:
            self.remaining -= 1
        return self.current


struct MorrowSpanIterator(Copyable, ImplicitlyCopyable, Movable):
    """A constant-memory iterator over bounded calendar spans."""

    var frame: String
    var current: Morrow
    var end: Morrow
    var step: Int
    var remaining: Int
    var bounds: String
    var exact: Bool
    var week_start: Int
    var original_day: Int
    var started: Bool

    def __init__(
        out self,
        frame: String,
        start: Morrow,
        end: Morrow,
        step: Int,
        limit: Int,
        bounds: String,
        exact: Bool,
        week_start: Int,
    ) raises:
        if step < 1:
            raise Error("interval must be greater than 0")
        Morrow._validate_bounds(bounds)
        start._check_awareness(end)
        var floor = start._floor_frame(frame, week_start)
        self.frame = frame
        self.current = start if exact else floor
        self.end = end
        self.step = step
        self.remaining = 0 if start > end else limit
        self.bounds = bounds
        self.exact = exact
        self.week_start = week_start
        self.original_day = start.day
        self.started = False

    def __iter__(self) -> Self:
        return self

    def __next__(mut self) raises -> MorrowSpan:
        if self.remaining != _UNBOUNDED_LIMIT and self.remaining <= 0:
            raise StopIteration()
        if self.started:
            if self.exact:
                self.current = self.current._shift_frame_preserving_day(
                    self.frame, self.step, self.original_day
                )
            else:
                self.current = self.current._shift_frame(self.frame, self.step)
        var end_key = self.end._utc_microseconds()
        var key = self.current._utc_microseconds()
        if key > end_key or (self.exact and key == end_key):
            raise StopIteration()
        var span = self.current.span(
            self.frame,
            count=self.step,
            bounds=self.bounds,
            exact=self.exact,
            week_start=self.week_start,
        )
        if self.exact:
            var start_key = span.start._utc_microseconds()
            if start_key == end_key or start_key - 1 == end_key:
                raise StopIteration()
            if span.end._utc_microseconds() > end_key:
                span.end = self.end
                if self.bounds.as_bytes()[1] == 41:
                    span.end = span.end.shift(microseconds=-1)
        self.started = True
        if self.remaining != _UNBOUNDED_LIMIT:
            self.remaining -= 1
        return span


struct MorrowIntervalIterator(Copyable, ImplicitlyCopyable, Movable):
    """Group spans without materializing the underlying range."""

    var spans: MorrowSpanIterator
    var group: Int
    var remaining: Int

    def __init__(
        out self,
        frame: String,
        start: Morrow,
        end: Morrow,
        interval: Int,
        limit: Int,
        bounds: String,
        exact: Bool,
        week_start: Int,
    ) raises:
        if interval < 1:
            raise Error("interval must be greater than 0")
        self.spans = MorrowSpanIterator(
            frame,
            start,
            end,
            1 if exact else interval,
            _UNBOUNDED_LIMIT,
            bounds,
            exact,
            week_start,
        )
        self.group = interval if exact else 1
        self.remaining = limit

    def __iter__(self) -> Self:
        return self

    def __next__(mut self) raises -> MorrowSpan:
        if self.remaining != _UNBOUNDED_LIMIT and self.remaining <= 0:
            raise StopIteration()
        var span = self.spans.__next__()
        for _ in range(1, self.group):
            try:
                span.end = self.spans.__next__().end
            except StopIteration:
                break
        if self.remaining != _UNBOUNDED_LIMIT:
            self.remaining -= 1
        return span
