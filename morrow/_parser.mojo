"""Parsing helpers behind Morrow.get, Morrow.strptime and Morrow.fromisoformat."""
from ._text import (
    utf8_width,
    is_digit,
    is_alnum,
    is_space,
    starts_at,
    starts_at_ascii_ignore_case,
)
from ._calendar import (
    US_PER_SECOND,
    ymd2ord,
    month_name,
    month_abbreviation,
    day_name,
    day_abbreviation,
)

from .locale import Locale
from ._libc import CTm
from .timezone import TimeZone
from std.collections import List
from .morrow import Morrow, US_PER_SECOND


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

    def __init__(out self, *, deinit move: Self):
        self.tz = move.tz^
        self.pos = move.pos


def _parse_iso_auto(date_str: String) raises -> Morrow:
    try:
        return Morrow.fromisoformat(date_str)
    except e:
        pass

    var length = date_str.byte_length()
    if length == 0:
        raise Error("isoformat string is too short")

    if _is_parse_punctuation(Int(date_str.as_bytes()[0])):
        try:
            return Morrow.fromisoformat(String(date_str[byte=1:]))
        except e:
            pass

    if _is_parse_punctuation(Int(date_str.as_bytes()[length - 1])):
        try:
            return Morrow.fromisoformat(String(date_str[byte = 0 : length - 1]))
        except e:
            pass

    if (
        length > 1
        and _is_parse_punctuation(Int(date_str.as_bytes()[0]))
        and _is_parse_punctuation(Int(date_str.as_bytes()[length - 1]))
    ):
        try:
            return Morrow.fromisoformat(String(date_str[byte = 1 : length - 1]))
        except e:
            pass

    raise Error("date string does not match ISO format")


def _parse_isoformat(date_str: String) raises -> Morrow:
    """
    Create a Morrow from an ISO 8601 string.
    """
    for byte in date_str.as_bytes():
        if byte > 127:
            raise Error("ISO date text must contain ASCII characters")
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
        and date_str.as_bytes()[4] == 45
        and is_digit(Int(date_str.as_bytes()[5]))
        and is_digit(Int(date_str.as_bytes()[6]))
        and (
            length == 7
            or date_str.as_bytes()[7] == 84
            or date_str.as_bytes()[7] == 116
            or date_str.as_bytes()[7] == 32
        )
    ):
        year = Int(date_str[byte=0:4])
        month = Int(date_str[byte=5:7])
        day = 1
        pos = 7
    elif length >= 7 and (
        (date_str.as_bytes()[4] == 45 and date_str.as_bytes()[5] == 87)
        or date_str.as_bytes()[4] == 87
    ):
        var iso_week = _parse_iso_week_date(date_str, 0)
        var date = Morrow.fromisocalendar(
            iso_week.year, iso_week.week, iso_week.weekday
        )
        year = date.year
        month = date.month
        day = date.day
        pos = iso_week.pos
    elif (
        length >= 8
        and date_str.as_bytes()[4] == 45
        and is_digit(Int(date_str.as_bytes()[5]))
        and is_digit(Int(date_str.as_bytes()[6]))
        and is_digit(Int(date_str.as_bytes()[7]))
    ):
        year = Int(date_str[byte=0:4])
        var day_of_year = Int(date_str[byte=5:8])
        if day_of_year < 1 or day_of_year > 366:
            raise Error("isoformat day of year is invalid")
        var date = Morrow.fromordinal(ymd2ord(year, 1, 1) + day_of_year - 1)
        year = date.year
        month = date.month
        day = date.day
        pos = 8
    elif (
        length >= 7
        and is_digit(Int(date_str.as_bytes()[0]))
        and is_digit(Int(date_str.as_bytes()[1]))
        and is_digit(Int(date_str.as_bytes()[2]))
        and is_digit(Int(date_str.as_bytes()[3]))
        and is_digit(Int(date_str.as_bytes()[4]))
        and is_digit(Int(date_str.as_bytes()[5]))
        and is_digit(Int(date_str.as_bytes()[6]))
        and (
            length == 7
            or date_str.as_bytes()[7] == 84
            or date_str.as_bytes()[7] == 116
            or date_str.as_bytes()[7] == 32
        )
    ):
        year = Int(date_str[byte=0:4])
        var day_of_year = Int(date_str[byte=4:7])
        if day_of_year < 1 or day_of_year > 366:
            raise Error("isoformat day of year is invalid")
        var date = Morrow.fromordinal(ymd2ord(year, 1, 1) + day_of_year - 1)
        year = date.year
        month = date.month
        day = date.day
        pos = 7
    elif (
        length >= 6
        and is_digit(Int(date_str.as_bytes()[0]))
        and is_digit(Int(date_str.as_bytes()[1]))
        and is_digit(Int(date_str.as_bytes()[2]))
        and is_digit(Int(date_str.as_bytes()[3]))
        and (
            date_str.as_bytes()[4] == 45
            or date_str.as_bytes()[4] == 47
            or date_str.as_bytes()[4] == 46
        )
        and is_digit(Int(date_str.as_bytes()[5]))
    ):
        year = Int(date_str[byte=0:4])
        var date_separator = Int(date_str.as_bytes()[4])
        var month_parsed = _parse_variable_int(date_str, 5, 2)
        month = month_parsed.value
        pos = month_parsed.pos
        if (
            pos == length
            or date_str.as_bytes()[pos] == 84
            or date_str.as_bytes()[pos] == 116
            or date_str.as_bytes()[pos] == 32
        ):
            if pos != 7:
                raise Error("isoformat month is invalid")
            day = 1
        elif Int(date_str.as_bytes()[pos]) == date_separator:
            pos += 1
            var day_parsed = _parse_variable_int(date_str, pos, 2)
            day = day_parsed.value
            pos = day_parsed.pos
        else:
            raise Error("isoformat date separator is invalid")
    elif (
        length >= 10
        and date_str.as_bytes()[4] == 45
        and date_str.as_bytes()[7] == 45
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
    var has_second = False
    var tz = TimeZone.from_utc("UTC")

    if pos < length:
        var separator = Int(date_str.as_bytes()[pos])
        if separator != ord("T") and separator != ord(" "):
            raise Error("isoformat date/time separator is invalid")
        pos += 1
        if length < pos + 2:
            raise Error("isoformat time is invalid")

        hour = Int(date_str[byte = pos : pos + 2])
        pos += 2

        if pos < length and date_str.as_bytes()[pos] == 58:
            pos += 1
            if length < pos + 2:
                raise Error("isoformat minute is invalid")
            minute = Int(date_str[byte = pos : pos + 2])
            pos += 2
            if pos < length and date_str.as_bytes()[pos] == 58:
                pos += 1
                if length < pos + 2:
                    raise Error("isoformat second is invalid")
                second = Int(date_str[byte = pos : pos + 2])
                pos += 2
                has_second = True
        else:
            if pos < length and is_digit(Int(date_str.as_bytes()[pos])):
                if length < pos + 2:
                    raise Error("isoformat minute is invalid")
                minute = Int(date_str[byte = pos : pos + 2])
                pos += 2
                if pos < length and is_digit(Int(date_str.as_bytes()[pos])):
                    if length < pos + 2:
                        raise Error("isoformat second is invalid")
                    second = Int(date_str[byte = pos : pos + 2])
                    pos += 2
                    has_second = True

        if pos < length and (
            date_str.as_bytes()[pos] == 46 or date_str.as_bytes()[pos] == 44
        ):
            if not has_second:
                raise Error("isoformat subsecond requires seconds")
            pos += 1
            var parsed = _parse_subsecond(date_str, pos, 6)
            microsecond = parsed.value
            pos = parsed.pos

        if pos < length:
            if date_str.as_bytes()[pos] == 90:
                tz = TimeZone.from_utc("UTC")
                pos += 1
            elif (
                date_str.as_bytes()[pos] == 43 or date_str.as_bytes()[pos] == 45
            ):
                var parsed = _parse_iso_timezone_offset(date_str, pos)
                tz = parsed.tz
                pos = parsed.pos
            else:
                raise Error("isoformat timezone is invalid")

    if pos != length:
        raise Error("isoformat string has trailing data")
    var carried_fraction = False
    if microsecond >= US_PER_SECOND:
        second += microsecond // US_PER_SECOND
        microsecond = microsecond % US_PER_SECOND
        carried_fraction = True
    if carried_fraction and second >= 60:
        Morrow._validate_fields(year, month, day, hour, minute, 0, microsecond)
        return Morrow(year, month, day, hour, minute, 0, microsecond, tz).shift(
            seconds=second
        )
    if hour == 24:
        if minute != 0 or second != 0 or microsecond != 0:
            raise Error("midnight at the end of day must be exactly 24:00")
        Morrow._validate_fields(year, month, day, 0, 0, 0, 0)
        return Morrow(year, month, day, 0, 0, 0, 0, tz).shift(days=1)
    Morrow._validate_fields(year, month, day, hour, minute, second, microsecond)
    return Morrow(year, month, day, hour, minute, second, microsecond, tz)


def _parse_arrow(
    date_str: String,
    fmt: String,
    tzinfo: TimeZone = TimeZone.none(),
    locale: Locale = Locale._fast_english(),
) raises -> Morrow:
    try:
        return _parse_arrow_at(date_str, fmt, tzinfo, 0, False, locale)
    except e:
        pass

    for date_start in range(date_str.byte_length()):
        if not _has_left_parse_boundary(date_str, date_start):
            continue
        try:
            return _parse_arrow_at(
                date_str, fmt, tzinfo, date_start, True, locale
            )
        except e:
            pass
    raise Error("date string does not match format")


def _parse_arrow_at(
    date_str: String,
    fmt: String,
    tzinfo: TimeZone,
    date_start: Int,
    allow_trailing_text: Bool,
    locale: Locale,
) raises -> Morrow:
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
    var tz = Morrow._utc_timezone()
    var am_pm = 0

    var date_pos = date_start
    var fmt_pos = 0
    while fmt_pos < fmt.byte_length():
        if fmt.as_bytes()[fmt_pos] >= 128:
            var width = utf8_width(fmt, fmt_pos)
            for j in range(width):
                _parse_literal_char(date_str, date_pos + j, fmt, fmt_pos + j)
            date_pos += width
            fmt_pos += width
            continue
        if fmt.as_bytes()[fmt_pos] == 91:
            var literal_start = fmt_pos + 1
            var literal_end = literal_start
            while literal_end < fmt.byte_length() and Int(
                fmt.as_bytes()[literal_end]
            ) != ord("]"):
                literal_end += 1
            if literal_end >= fmt.byte_length():
                _parse_literal_char(date_str, date_pos, fmt, fmt_pos)
                date_pos += 1
                fmt_pos += 1
                continue

            if _is_whitespace_regex_literal(fmt, literal_start, literal_end):
                date_pos = _parse_whitespace_regex(date_str, date_pos)
            elif _is_optional_whitespace_regex_literal(
                fmt, literal_start, literal_end
            ):
                date_pos = _parse_optional_whitespace_regex(date_str, date_pos)
            elif _is_single_optional_whitespace_regex_literal(
                fmt, literal_start, literal_end
            ):
                date_pos = _parse_single_optional_whitespace_regex(
                    date_str, date_pos
                )
            else:
                var literal_pos = literal_start
                while literal_pos < literal_end:
                    _parse_literal_char(date_str, date_pos, fmt, literal_pos)
                    date_pos += 1
                    literal_pos += 1
            fmt_pos = literal_end + 1
        elif starts_at(fmt, fmt_pos, "YYYY"):
            var parsed = _parse_fixed_int(date_str, date_pos, 4)
            year = parsed.value - locale.year_offset
            has_year = True
            date_pos = parsed.pos
            fmt_pos += 4
        elif starts_at(fmt, fmt_pos, "YY"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            if locale.year_offset != 0:
                # Buddhist-era years: 00..99 map to 2500..2599 BE.
                year = 2500 + parsed.value - locale.year_offset
            else:
                year = _parse_two_digit_year(parsed.value)
            has_year = True
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "MMMM"):
            var parsed = _parse_month_name(date_str, date_pos, False, locale)
            month = parsed.value
            has_month = True
            date_pos = parsed.pos
            fmt_pos += 4
        elif starts_at(fmt, fmt_pos, "MMM"):
            var parsed = _parse_month_name(date_str, date_pos, True, locale)
            month = parsed.value
            has_month = True
            date_pos = parsed.pos
            fmt_pos += 3
        elif starts_at(fmt, fmt_pos, "MM"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            month = parsed.value
            has_month = True
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "M"):
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            month = parsed.value
            has_month = True
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "DDDD"):
            var parsed = _parse_fixed_int(date_str, date_pos, 3)
            day_of_year = parsed.value
            has_day = True
            date_pos = parsed.pos
            fmt_pos += 4
        elif starts_at(fmt, fmt_pos, "DDD"):
            var parsed = _parse_variable_int(date_str, date_pos, 3)
            day_of_year = parsed.value
            has_day = True
            date_pos = parsed.pos
            fmt_pos += 3
        elif starts_at(fmt, fmt_pos, "Do") and not (locale.is_fast_english()):
            var parsed = locale._match_ordinal(date_str, date_pos)
            day = parsed.value
            has_day = True
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "Do"):
            var ordinal_start = date_pos
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            if (
                parsed.pos - ordinal_start > 1
                and date_str.as_bytes()[ordinal_start] == 48
            ):
                raise Error("ordinal day must not contain a leading zero")
            day = parsed.value
            has_day = True
            date_pos = parsed.pos
            date_pos = _parse_ordinal_suffix(date_str, date_pos, day)
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "DD"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            day = parsed.value
            has_day = True
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "D"):
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            day = parsed.value
            has_day = True
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "W"):
            var parsed = _parse_iso_week_date(date_str, date_pos)
            var date = Morrow.fromisocalendar(
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
        elif starts_at(fmt, fmt_pos, "dddd"):
            var parsed = _parse_weekday_name(date_str, date_pos, False, locale)
            parsed_weekday_name = parsed.value
            date_pos = parsed.pos
            fmt_pos += 4
        elif starts_at(fmt, fmt_pos, "ddd"):
            var parsed = _parse_weekday_name(date_str, date_pos, True, locale)
            parsed_weekday_name = parsed.value
            date_pos = parsed.pos
            fmt_pos += 3
        elif starts_at(fmt, fmt_pos, "d"):
            var parsed = _parse_fixed_int(date_str, date_pos, 1)
            if parsed.value < 1 or parsed.value > 7:
                raise Error("weekday must be in 1..7")
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "HH"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            hour = parsed.value
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "H"):
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            hour = parsed.value
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "hh"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            hour = parsed.value
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "h"):
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            hour = parsed.value
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "mm"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            minute = parsed.value
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "m"):
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            minute = parsed.value
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "ss"):
            var parsed = _parse_fixed_int(date_str, date_pos, 2)
            second = parsed.value
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "s"):
            var parsed = _parse_variable_int(date_str, date_pos, 2)
            second = parsed.value
            date_pos = parsed.pos
            fmt_pos += 1
        elif fmt.as_bytes()[fmt_pos] == 83:
            var token_end = fmt_pos
            while (
                token_end < fmt.byte_length()
                and fmt.as_bytes()[token_end] == 83
            ):
                token_end += 1
            var parsed = _parse_subsecond(
                date_str, date_pos, token_end - fmt_pos
            )
            microsecond = parsed.value
            date_pos = parsed.pos
            fmt_pos = token_end
        elif starts_at(fmt, fmt_pos, "X"):
            if fmt_pos + 1 != fmt.byte_length():
                raise Error("timestamp token must be the full format")
            var timestamp_str = String(date_str[byte=date_pos:])
            _validate_timestamp_seconds_token(timestamp_str)
            var parsed = Morrow.utcfromtimestamp(timestamp_str)
            if not tzinfo.is_none():
                return parsed.replace(tzinfo=tzinfo)
            return parsed
        elif starts_at(fmt, fmt_pos, "x"):
            if fmt_pos + 1 != fmt.byte_length():
                raise Error("timestamp token must be the full format")
            var timestamp_str = String(date_str[byte=date_pos:])
            _validate_expanded_timestamp_token(timestamp_str)
            var parsed = Morrow._from_expanded_timestamp_value(
                Int(timestamp_str)
            )
            if not tzinfo.is_none():
                return parsed.replace(tzinfo=tzinfo)
            return parsed
        elif starts_at(fmt, fmt_pos, "ZZZ"):
            var parsed = _parse_timezone_name(date_str, date_pos)
            tz = parsed.tz
            date_pos = parsed.pos
            fmt_pos += 3
        elif starts_at(fmt, fmt_pos, "ZZ"):
            var parsed = _parse_timezone_offset(date_str, date_pos, True)
            tz = parsed.tz
            date_pos = parsed.pos
            fmt_pos += 2
        elif starts_at(fmt, fmt_pos, "Z"):
            var parsed = _parse_timezone_offset(date_str, date_pos, False)
            tz = parsed.tz
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "A"):
            var parsed = _parse_am_pm(date_str, date_pos, locale)
            am_pm = parsed.value
            date_pos = parsed.pos
            fmt_pos += 1
        elif starts_at(fmt, fmt_pos, "a"):
            var parsed = _parse_am_pm(date_str, date_pos, locale)
            am_pm = parsed.value
            date_pos = parsed.pos
            fmt_pos += 1
        else:
            _parse_literal_char(date_str, date_pos, fmt, fmt_pos)
            date_pos += 1
            fmt_pos += 1

    if allow_trailing_text:
        if not _has_right_parse_boundary(date_str, date_pos):
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
        if has_month:
            raise Error("month component is not allowed with day of year")
        if day_of_year < 1 or day_of_year > 366:
            raise Error("day of year is invalid")
        var date = Morrow.fromordinal(ymd2ord(year, 1, 1) + day_of_year - 1)
        year = date.year
        month = date.month
        day = date.day
    elif parsed_weekday_name != 0 and not has_day:
        if not has_year:
            year = 1970
        if not has_month:
            month = 1
        Morrow._validate_fields(year, month, 1, 0, 0, 0, 0)
        var first_day = Morrow(year, month, 1)
        var weekday_offset = parsed_weekday_name - first_day.isoweekday()
        if weekday_offset < 0:
            weekday_offset += 7
        var date = first_day.shift(days=weekday_offset)
        year = date.year
        month = date.month
        day = date.day
    if microsecond >= US_PER_SECOND:
        second += microsecond // US_PER_SECOND
        microsecond = microsecond % US_PER_SECOND
    var midnight_end_of_day = False
    if hour == 24:
        if minute != 0:
            raise Error("midnight at the end of day must not contain minutes")
        if second != 0:
            raise Error("midnight at the end of day must not contain seconds")
        if microsecond != 0:
            raise Error(
                "midnight at the end of day must not contain microseconds"
            )
        hour = 0
        midnight_end_of_day = True
    if not tzinfo.is_none():
        tz = tzinfo
    Morrow._validate_fields(year, month, day, hour, minute, second, microsecond)
    var parsed = Morrow(year, month, day, hour, minute, second, microsecond, tz)
    if midnight_end_of_day:
        return parsed.shift(days=1)
    return parsed


def _parse_arrow_formats(
    date_str: String,
    formats: List[String],
    tzinfo: TimeZone = TimeZone.none(),
) raises -> Morrow:
    for i in range(len(formats)):
        try:
            return _parse_arrow(date_str, formats[i], tzinfo)
        except e:
            pass
    raise Error("date string does not match any format")


def _from_strptime_tm(
    tm: CTm,
    microsecond: Int,
    tzinfo: TimeZone,
    parsed_tz: TimeZone = TimeZone.none(),
) raises -> Morrow:
    var tz: TimeZone
    if not tzinfo.is_none():
        tz = tzinfo
    elif not parsed_tz.is_none():
        tz = parsed_tz
    else:
        tz = TimeZone(Int(tm.tm_gmtoff))
    return Morrow._from_components(
        Int(tm.tm_year) + 1900,
        Int(tm.tm_mon) + 1,
        Int(tm.tm_mday),
        Int(tm.tm_hour),
        Int(tm.tm_min),
        Int(tm.tm_sec),
        microsecond,
        tz,
    )


def _find_strptime_extension_directive(fmt: String) -> MorrowParseInt:
    var pos = 0
    while pos + 1 < fmt.byte_length():
        if fmt.as_bytes()[pos] == 37:
            if fmt.as_bytes()[pos + 1] == 37:
                pos += 2
                continue
            if (
                fmt.as_bytes()[pos + 1] == 102
                or fmt.as_bytes()[pos + 1] == 122
                or fmt.as_bytes()[pos + 1] == 90
            ):
                return MorrowParseInt(Int(fmt.as_bytes()[pos + 1]), pos)
            pos += 2
        else:
            pos += 1
    return MorrowParseInt(0, -1)


def _parse_strptime_timezone_name(
    date_str: String, date_pos: Int
) raises -> MorrowParseTimeZone:
    return _parse_timezone_name(date_str, date_pos)


def _parse_strptime_timezone_offset(
    date_str: String, date_pos: Int
) raises -> MorrowParseTimeZone:
    if date_pos >= date_str.byte_length():
        raise Error("timezone is missing")
    if date_str.as_bytes()[date_pos] == 90:
        return MorrowParseTimeZone(TimeZone.from_utc("UTC"), date_pos + 1)

    var sign = 1
    if date_str.as_bytes()[date_pos] == 45:
        sign = -1
    elif not date_str.as_bytes()[date_pos] == 43:
        raise Error("timezone must be Z or a fixed offset")

    var pos = date_pos + 1
    if (
        pos + 2 > date_str.byte_length()
        or not is_digit(Int(date_str.as_bytes()[pos]))
        or not is_digit(Int(date_str.as_bytes()[pos + 1]))
    ):
        raise Error("timezone hour is invalid")
    var hours = Int(date_str[byte = pos : pos + 2])
    pos += 2

    var minutes: Int
    var seconds = 0
    if pos < date_str.byte_length() and date_str.as_bytes()[pos] == 58:
        pos += 1
        if (
            pos + 2 > date_str.byte_length()
            or not is_digit(Int(date_str.as_bytes()[pos]))
            or not is_digit(Int(date_str.as_bytes()[pos + 1]))
        ):
            raise Error("timezone minute is invalid")
        minutes = Int(date_str[byte = pos : pos + 2])
        pos += 2
        if pos < date_str.byte_length() and date_str.as_bytes()[pos] == 58:
            pos += 1
            if (
                pos + 2 > date_str.byte_length()
                or not is_digit(Int(date_str.as_bytes()[pos]))
                or not is_digit(Int(date_str.as_bytes()[pos + 1]))
            ):
                raise Error("timezone second is invalid")
            seconds = Int(date_str[byte = pos : pos + 2])
            pos += 2
    else:
        if (
            pos + 2 > date_str.byte_length()
            or not is_digit(Int(date_str.as_bytes()[pos]))
            or not is_digit(Int(date_str.as_bytes()[pos + 1]))
        ):
            raise Error("timezone minute is invalid")
        minutes = Int(date_str[byte = pos : pos + 2])
        pos += 2
        if (
            pos + 2 <= date_str.byte_length()
            and is_digit(Int(date_str.as_bytes()[pos]))
            and is_digit(Int(date_str.as_bytes()[pos + 1]))
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


def _parse_iso_timezone_offset(
    date_str: String, date_pos: Int
) raises -> MorrowParseTimeZone:
    var sign = Int(date_str.as_bytes()[date_pos])
    if sign != ord("+") and sign != ord("-"):
        raise Error("isoformat timezone must be a fixed offset")

    var pos = date_pos + 1
    if pos + 2 > date_str.byte_length():
        raise Error("isoformat timezone hour is invalid")
    for i in range(2):
        if not is_digit(Int(date_str.as_bytes()[pos + i])):
            raise Error("isoformat timezone hour is invalid")
    pos += 2

    if pos == date_str.byte_length():
        return MorrowParseTimeZone(
            TimeZone.from_utc(String(date_str[byte=date_pos:pos])), pos
        )

    if date_str.as_bytes()[pos] == 58:
        var colon_pos = pos
        pos += 1
        if pos == date_str.byte_length():
            return MorrowParseTimeZone(
                TimeZone.from_utc(String(date_str[byte=date_pos:colon_pos])),
                pos,
            )
        if pos + 2 > date_str.byte_length():
            raise Error("isoformat timezone minute is invalid")
        for i in range(2):
            if not is_digit(Int(date_str.as_bytes()[pos + i])):
                raise Error("isoformat timezone minute is invalid")
        pos += 2
    elif (
        pos + 2 <= date_str.byte_length()
        and is_digit(Int(date_str.as_bytes()[pos]))
        and is_digit(Int(date_str.as_bytes()[pos + 1]))
    ):
        pos += 2
    else:
        raise Error("isoformat timezone minute is invalid")

    if pos != date_str.byte_length():
        raise Error("isoformat timezone has trailing data")
    return MorrowParseTimeZone(
        TimeZone.from_utc(String(date_str[byte=date_pos:pos])), pos
    )


def _has_left_parse_boundary(s: String, pos: Int) -> Bool:
    if pos == 0:
        return True
    var c = Int(s.as_bytes()[pos - 1])
    if is_space(c):
        return True
    if _is_parse_punctuation(c):
        return pos == 1 or is_space(Int(s.as_bytes()[pos - 2]))
    return False


def _has_right_parse_boundary(s: String, pos: Int) -> Bool:
    if pos == s.byte_length():
        return True
    var c = Int(s.as_bytes()[pos])
    if is_space(c):
        return True
    if _is_parse_punctuation(c):
        return pos + 1 == s.byte_length() or is_space(
            Int(s.as_bytes()[pos + 1])
        )
    return False


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


def _normalize_whitespace(s: String) -> String:
    var result = ""
    var pending_space = False
    var i = 0
    while i < s.byte_length():
        var width = utf8_width(s, i)
        if is_space(Int(s.as_bytes()[i])):
            if result.byte_length() > 0:
                pending_space = True
        else:
            if pending_space:
                result += " "
                pending_space = False
            result += s[byte = i : i + width]
        i += width
    return result


def _is_whitespace_regex_literal(fmt: String, start: Int, end: Int) -> Bool:
    return (
        end - start == 3
        and Int(fmt.as_bytes()[start]) == 92
        and Int(fmt.as_bytes()[start + 1]) == ord("s")
        and Int(fmt.as_bytes()[start + 2]) == ord("+")
    )


def _is_optional_whitespace_regex_literal(
    fmt: String, start: Int, end: Int
) -> Bool:
    return (
        end - start == 3
        and Int(fmt.as_bytes()[start]) == 92
        and Int(fmt.as_bytes()[start + 1]) == ord("s")
        and Int(fmt.as_bytes()[start + 2]) == ord("*")
    )


def _is_single_optional_whitespace_regex_literal(
    fmt: String, start: Int, end: Int
) -> Bool:
    return (
        end - start == 3
        and Int(fmt.as_bytes()[start]) == 92
        and Int(fmt.as_bytes()[start + 1]) == ord("s")
        and Int(fmt.as_bytes()[start + 2]) == ord("?")
    )


def _parse_whitespace_regex(date_str: String, date_pos: Int) raises -> Int:
    var pos = date_pos
    while pos < date_str.byte_length() and is_space(
        Int(date_str.as_bytes()[pos])
    ):
        pos += 1
    if pos == date_pos:
        raise Error("whitespace is missing")
    return pos


def _parse_optional_whitespace_regex(date_str: String, date_pos: Int) -> Int:
    var pos = date_pos
    while pos < date_str.byte_length() and is_space(
        Int(date_str.as_bytes()[pos])
    ):
        pos += 1
    return pos


def _parse_single_optional_whitespace_regex(
    date_str: String, date_pos: Int
) -> Int:
    if date_pos < date_str.byte_length() and is_space(
        Int(date_str.as_bytes()[date_pos])
    ):
        return date_pos + 1
    return date_pos


def _parse_literal_char(
    date_str: String, date_pos: Int, fmt: String, fmt_pos: Int
) raises:
    if date_pos >= date_str.byte_length():
        raise Error("date string is shorter than format")
    if Int(date_str.as_bytes()[date_pos]) != Int(fmt.as_bytes()[fmt_pos]):
        raise Error("date string does not match format literal")


def _parse_fixed_int(
    date_str: String, date_pos: Int, count: Int
) raises -> MorrowParseInt:
    if date_pos + count > date_str.byte_length():
        raise Error("date string is shorter than numeric token")
    for i in range(count):
        if not is_digit(Int(date_str.as_bytes()[date_pos + i])):
            raise Error("numeric token contains non-digit data")
    return MorrowParseInt(
        Int(date_str[byte = date_pos : date_pos + count]), date_pos + count
    )


def _parse_variable_int(
    date_str: String, date_pos: Int, max_count: Int
) raises -> MorrowParseInt:
    var pos = date_pos
    var end = date_pos + max_count
    if end > date_str.byte_length():
        end = date_str.byte_length()
    while pos < end and is_digit(Int(date_str.as_bytes()[pos])):
        pos += 1
    if pos == date_pos:
        raise Error("numeric token is missing")
    return MorrowParseInt(Int(date_str[byte=date_pos:pos]), pos)


def _parse_subsecond(
    date_str: String, date_pos: Int, count: Int
) raises -> MorrowParseInt:
    var pos = date_pos
    while pos < date_str.byte_length() and is_digit(
        Int(date_str.as_bytes()[pos])
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
            if Int(date_str.as_bytes()[i]) != ord("0"):
                has_remaining = True
        should_round = has_remaining or value % 2 == 1
    if should_round:
        value += 1
    return MorrowParseInt(value, pos)


def _validate_timestamp_seconds_token(timestamp_str: String) raises:
    var length = timestamp_str.byte_length()
    if length == 0:
        raise Error("timestamp token is missing")
    var pos = 0
    if timestamp_str.as_bytes()[pos] == 45:
        pos += 1
        if pos == length:
            raise Error("timestamp token is missing")

    var digit_start = pos
    while pos < length and is_digit(Int(timestamp_str.as_bytes()[pos])):
        pos += 1
    var digit_count = pos - digit_start
    if digit_count == 0:
        raise Error("timestamp token must start with digits")

    var has_fraction = False
    if pos < length and timestamp_str.as_bytes()[pos] == 46:
        has_fraction = True
        pos += 1
        var fraction_start = pos
        while pos < length and is_digit(Int(timestamp_str.as_bytes()[pos])):
            pos += 1
        if pos == fraction_start:
            raise Error("timestamp token fraction is missing")

    if pos != length:
        raise Error("timestamp token has invalid characters")
    if not has_fraction and digit_count < 2:
        raise Error("timestamp token integer is too short")


def _validate_expanded_timestamp_token(timestamp_str: String) raises:
    var length = timestamp_str.byte_length()
    if length == 0:
        raise Error("timestamp token is missing")
    var pos = 0
    if timestamp_str.as_bytes()[pos] == 45:
        pos += 1
        if pos == length:
            raise Error("timestamp token is missing")
    while pos < length and is_digit(Int(timestamp_str.as_bytes()[pos])):
        pos += 1
    if pos != length:
        raise Error("timestamp token has invalid characters")


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
    if starts_at_ascii_ignore_case(date_str, date_pos, expected):
        return date_pos + 2
    raise Error("ordinal suffix is invalid")


def _parse_two_digit_year(year: Int) -> Int:
    if year >= 69:
        return 1900 + year
    return 2000 + year


def _parse_month_name(
    date_str: String,
    date_pos: Int,
    abbreviated: Bool,
    locale: Locale,
) raises -> MorrowParseInt:
    if not locale.is_fast_english():
        var matched = locale._match_month(date_str, date_pos, abbreviated)
        return MorrowParseInt(matched.value, matched.pos)
    for value in range(1, 13):
        var name = month_abbreviation(value) if abbreviated else month_name(
            value
        )
        if starts_at_ascii_ignore_case(date_str, date_pos, name):
            return MorrowParseInt(value, date_pos + name.byte_length())
    raise Error("month name is invalid")


def _parse_weekday_name(
    date_str: String,
    date_pos: Int,
    abbreviated: Bool,
    locale: Locale,
) raises -> MorrowParseInt:
    if not locale.is_fast_english():
        var matched = locale._match_weekday(date_str, date_pos, abbreviated)
        return MorrowParseInt(matched.value, matched.pos)
    for value in range(1, 8):
        var name = day_abbreviation(value) if abbreviated else day_name(value)
        if starts_at_ascii_ignore_case(date_str, date_pos, name):
            return MorrowParseInt(value, date_pos + name.byte_length())
    raise Error("weekday name is invalid")


def _parse_iso_week_date(
    date_str: String, date_pos: Int
) raises -> MorrowParseIsoWeek:
    var year_parsed = _parse_fixed_int(date_str, date_pos, 4)
    var pos = year_parsed.pos
    if pos < date_str.byte_length() and date_str.as_bytes()[pos] == 45:
        pos += 1
    if pos >= date_str.byte_length() or Int(date_str.as_bytes()[pos]) != ord(
        "W"
    ):
        raise Error("ISO week date is missing W marker")
    pos += 1
    var week_parsed = _parse_fixed_int(date_str, pos, 2)
    pos = week_parsed.pos

    var weekday = 1
    if pos < date_str.byte_length() and date_str.as_bytes()[pos] == 45:
        if pos + 1 < date_str.byte_length() and is_digit(
            Int(date_str.as_bytes()[pos + 1])
        ):
            pos += 1
            var weekday_parsed = _parse_fixed_int(date_str, pos, 1)
            weekday = weekday_parsed.value
            pos = weekday_parsed.pos
    elif pos < date_str.byte_length() and is_digit(
        Int(date_str.as_bytes()[pos])
    ):
        var weekday_parsed = _parse_fixed_int(date_str, pos, 1)
        weekday = weekday_parsed.value
        pos = weekday_parsed.pos

    return MorrowParseIsoWeek(
        year_parsed.value, week_parsed.value, weekday, pos
    )


def _parse_timezone_name(
    date_str: String, date_pos: Int
) raises -> MorrowParseTimeZone:
    if date_pos >= date_str.byte_length():
        raise Error("timezone is missing")
    var end = date_pos
    while end < date_str.byte_length():
        var c = Int(date_str.as_bytes()[end])
        if not (
            is_alnum(c)
            or c == ord("/")
            or c == ord("_")
            or c == ord("-")
            or c == ord("+")
        ):
            break
        end += 1
    var name = String(date_str[byte=date_pos:end])
    if name.byte_length() == 3 and starts_at_ascii_ignore_case(name, 0, "UTC"):
        return MorrowParseTimeZone(Morrow._utc_timezone(), end)
    if name.byte_length() == 3 and starts_at_ascii_ignore_case(name, 0, "GMT"):
        return MorrowParseTimeZone(TimeZone(0, "GMT"), end)
    return MorrowParseTimeZone(TimeZone.from_name(name), end)


def _parse_timezone_offset(
    date_str: String, date_pos: Int, colon: Bool
) raises -> MorrowParseTimeZone:
    if starts_at(date_str, date_pos, "Z"):
        return MorrowParseTimeZone(Morrow._utc_timezone(), date_pos + 1)
    if date_pos >= date_str.byte_length():
        raise Error("timezone is missing")

    var sign = Int(date_str.as_bytes()[date_pos])
    if sign != ord("+") and sign != ord("-"):
        raise Error("timezone must be Z or a fixed offset")

    var pos = date_pos + 1
    if pos + 2 > date_str.byte_length():
        raise Error("timezone hour is invalid")
    for i in range(2):
        if not is_digit(Int(date_str.as_bytes()[pos + i])):
            raise Error("timezone hour is invalid")
    pos += 2

    if pos < date_str.byte_length() and date_str.as_bytes()[pos] == 58:
        if not colon:
            raise Error("timezone offset must not contain a colon")
        var colon_pos = pos
        pos += 1
        if pos + 2 > date_str.byte_length():
            return MorrowParseTimeZone(
                TimeZone.from_utc(String(date_str[byte=date_pos:colon_pos])),
                colon_pos,
            )
        for i in range(2):
            if not is_digit(Int(date_str.as_bytes()[pos + i])):
                return MorrowParseTimeZone(
                    TimeZone.from_utc(
                        String(date_str[byte=date_pos:colon_pos])
                    ),
                    colon_pos,
                )
        pos += 2
    elif (
        pos + 2 <= date_str.byte_length()
        and is_digit(Int(date_str.as_bytes()[pos]))
        and is_digit(Int(date_str.as_bytes()[pos + 1]))
    ):
        if colon:
            raise Error("timezone offset minutes must contain a colon")
        pos += 2
    return MorrowParseTimeZone(
        TimeZone.from_utc(String(date_str[byte=date_pos:pos])), pos
    )


def _parse_am_pm(
    date_str: String, date_pos: Int, locale: Locale
) raises -> MorrowParseInt:
    """Return 1 for AM or 2 for PM and the position after the marker."""
    if not locale.is_fast_english():
        var matched = locale._match_meridian(date_str, date_pos)
        return MorrowParseInt(matched.value, matched.pos)
    if starts_at(date_str, date_pos, "AM") or starts_at(
        date_str, date_pos, "am"
    ):
        return MorrowParseInt(1, date_pos + 2)
    if starts_at(date_str, date_pos, "PM") or starts_at(
        date_str, date_pos, "pm"
    ):
        return MorrowParseInt(2, date_pos + 2)
    # Mixed-case markers are accepted without changing the hour (1.0).
    if starts_at_ascii_ignore_case(
        date_str, date_pos, "AM"
    ) or starts_at_ascii_ignore_case(date_str, date_pos, "PM"):
        return MorrowParseInt(0, date_pos + 2)
    raise Error("AM/PM marker is invalid")
