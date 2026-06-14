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
from .constants import days_before_month, day_abbreviation, month_abbreviation
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
    def fromtimestamp(timestamp: Float64, tz: TimeZone) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz)

    @staticmethod
    def fromtimestamp(timestamp: Float64, tz_str: String) raises -> Self:
        return Self.utcfromtimestamp(timestamp).to(tz_str)

    @staticmethod
    def utcfromtimestamp(timestamp: Float64) raises -> Self:
        return Self._fromtimestamp(
            Self._timeval_from_timestamp(timestamp), True
        )

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
    def get(date_str: String, fmt: String) -> Self:
        """
        Create a Morrow by parsing a string with a datetime format.
        """
        return Self.strptime(date_str, fmt)

    @staticmethod
    def get(date_str: String, fmt: String, tz: TimeZone) -> Self:
        """
        Create a Morrow by parsing a string with a datetime format and replacement timezone.
        """
        return Self.strptime(date_str, fmt, tz)

    @staticmethod
    def get(date_str: String, fmt: String, tz_str: String) raises -> Self:
        """
        Create a Morrow by parsing a string with a datetime format and parsed replacement timezone.
        """
        return Self.strptime(date_str, fmt, tz_str)

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
    def fromisoformat(date_str: String) raises -> Self:
        """
        Create a Morrow from an ISO 8601 string.
        """
        var length = date_str.byte_length()
        if length < 8:
            raise Error("isoformat string is too short")

        var year: Int
        var month: Int
        var day: Int
        var pos: Int
        if length >= 10 and date_str[byte=4] == "-" and date_str[byte=7] == "-":
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
                if length < pos + 4:
                    raise Error("isoformat basic time is invalid")
                minute = Int(date_str[byte = pos : pos + 2])
                pos += 2
                second = Int(date_str[byte = pos : pos + 2])
                pos += 2

            if pos < length and date_str[byte=pos] == ".":
                pos += 1
                var start = pos
                while pos < length:
                    var c = ord(date_str[byte=pos])
                    if c < ord("0") or c > ord("9"):
                        break
                    pos += 1
                if pos == start:
                    raise Error("isoformat microsecond is invalid")
                var digits = String(date_str[byte=start:pos])
                while digits.byte_length() < 6:
                    digits += "0"
                if digits.byte_length() > 6:
                    digits = String(digits[byte=0:6])
                microsecond = Int(digits)

            if pos < length:
                if date_str[byte=pos] == "Z" or date_str[byte=pos] == "z":
                    tz = TimeZone.from_utc("UTC")
                    pos += 1
                elif date_str[byte=pos] == "+" or date_str[byte=pos] == "-":
                    tz = TimeZone.from_utc(String(date_str[byte=pos:]))
                    pos = length
                else:
                    raise Error("isoformat timezone is invalid")

        if pos != length:
            raise Error("isoformat string has trailing data")
        Self._validate_fields(
            year, month, day, hour, minute, second, microsecond
        )
        return Self(year, month, day, hour, minute, second, microsecond, tz)

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
