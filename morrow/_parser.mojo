"""Parsing behind Morrow.get, Morrow.strptime and Morrow.fromisoformat.

Three grammars live here: ISO 8601 (`_parse_isoformat`, plus the lenient
`_parse_iso_auto` used by `Morrow.get(str)`), Arrow format tokens
(`_parse_arrow`), and libc strptime extended with %f, %z and %Z
(`_parse_strptime`). Positions are byte offsets into the input.
"""

from std.collections import List

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
from ._libc import CTm, c_strptime, c_strptime_consumed
from .locale import Locale
from .morrow import Morrow
from .timezone import TimeZone


struct _ParsedInt(Copyable, ImplicitlyCopyable, Movable):
    var value: Int
    var pos: Int

    def __init__(out self, value: Int, pos: Int):
        self.value = value
        self.pos = pos


struct _ParsedIsoWeek(Copyable, ImplicitlyCopyable, Movable):
    var year: Int
    var week: Int
    var weekday: Int
    var pos: Int

    def __init__(out self, year: Int, week: Int, weekday: Int, pos: Int):
        self.year = year
        self.week = week
        self.weekday = weekday
        self.pos = pos


struct _ParsedZone(Copyable, ImplicitlyCopyable, Movable):
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


# ISO 8601.


def _parse_iso_auto(date_str: String) raises -> Morrow:
    """ISO text, also accepted with one punctuation mark on either side."""
    try:
        return _parse_isoformat(date_str)
    except e:
        pass

    var length = date_str.byte_length()
    if length == 0:
        raise Error("isoformat string is too short")
    var leading = _is_parse_punctuation(_byte(date_str, 0))
    var trailing = _is_parse_punctuation(_byte(date_str, length - 1))
    if leading:
        try:
            return _parse_isoformat(String(date_str[byte=1:]))
        except e:
            pass
    if trailing:
        try:
            return _parse_isoformat(String(date_str[byte = 0 : length - 1]))
        except e:
            pass
    if length > 1 and leading and trailing:
        try:
            return _parse_isoformat(String(date_str[byte = 1 : length - 1]))
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
    var s = date_str
    var length = s.byte_length()
    if length < 4:
        raise Error("isoformat string is too short")

    var year: Int
    var month: Int
    var day: Int
    var pos: Int
    if length == 4:  # YYYY
        year = Int(s[byte=0:4])
        month = 1
        day = 1
        pos = 4
    elif (
        length >= 7
        and _byte(s, 4) == ord("-")
        and _digits(s, 5, 7)
        and _is_date_end(s, 7)
    ):  # YYYY-MM
        year = Int(s[byte=0:4])
        month = Int(s[byte=5:7])
        day = 1
        pos = 7
    elif length >= 7 and (
        (_byte(s, 4) == ord("-") and _byte(s, 5) == ord("W"))
        or _byte(s, 4) == ord("W")
    ):  # YYYY-Www-D, YYYYWwwD
        var iso_week = _parse_iso_week_date(s, 0)
        var date = Morrow.fromisocalendar(
            iso_week.year, iso_week.week, iso_week.weekday
        )
        year = date.year
        month = date.month
        day = date.day
        pos = iso_week.pos
    elif (length >= 8 and _byte(s, 4) == ord("-") and _digits(s, 5, 8)) or (
        length >= 7 and _digits(s, 0, 7) and _is_date_end(s, 7)
    ):  # YYYY-DDD, YYYYDDD
        year = Int(s[byte=0:4])
        var start = 5 if _byte(s, 4) == ord("-") else 4
        pos = start + 3
        var day_of_year = Int(s[byte=start:pos])
        if day_of_year < 1 or day_of_year > 366:
            raise Error("isoformat day of year is invalid")
        var date = Morrow.fromordinal(ymd2ord(year, 1, 1) + day_of_year - 1)
        year = date.year
        month = date.month
        day = date.day
    elif (
        length >= 6
        and _digits(s, 0, 4)
        and (
            _byte(s, 4) == ord("-")
            or _byte(s, 4) == ord("/")
            or _byte(s, 4) == ord(".")
        )
        and _digits(s, 5, 6)
    ):  # YYYY-M[-D] with -, / or . separators
        year = Int(s[byte=0:4])
        var separator = _byte(s, 4)
        var month_parsed = _parse_variable_int(s, 5, 2)
        month = month_parsed.value
        pos = month_parsed.pos
        if _is_date_end(s, pos):
            if pos != 7:
                raise Error("isoformat month is invalid")
            day = 1
        elif _byte(s, pos) == separator:
            var day_parsed = _parse_variable_int(s, pos + 1, 2)
            day = day_parsed.value
            pos = day_parsed.pos
        else:
            raise Error("isoformat date separator is invalid")
    elif (
        length >= 10 and _byte(s, 4) == ord("-") and _byte(s, 7) == ord("-")
    ):  # YYYY-MM-DD
        year = Int(s[byte=0:4])
        month = Int(s[byte=5:7])
        day = Int(s[byte=8:10])
        pos = 10
    else:  # YYYYMMDD
        if length < 8:
            raise Error("isoformat date is invalid")
        year = Int(s[byte=0:4])
        month = Int(s[byte=4:6])
        day = Int(s[byte=6:8])
        pos = 8

    var hour = 0
    var minute = 0
    var second = 0
    var microsecond = 0
    var tz = TimeZone.from_utc("UTC")

    if pos < length:
        var separator = _byte(s, pos)
        if separator != ord("T") and separator != ord(" "):
            raise Error("isoformat date/time separator is invalid")
        pos += 1
        if length < pos + 2:
            raise Error("isoformat time is invalid")
        hour = Int(s[byte = pos : pos + 2])
        pos += 2

        # hh:mm:ss or hhmmss; the separator style must stay consistent.
        var has_second = False
        var colon = pos < length and _byte(s, pos) == ord(":")
        if colon or (pos < length and is_digit(_byte(s, pos))):
            if colon:
                pos += 1
            if length < pos + 2:
                raise Error("isoformat minute is invalid")
            minute = Int(s[byte = pos : pos + 2])
            pos += 2
            var more = False
            if pos < length:
                more = _byte(s, pos) == ord(":") if colon else is_digit(
                    _byte(s, pos)
                )
            if more:
                if colon:
                    pos += 1
                if length < pos + 2:
                    raise Error("isoformat second is invalid")
                second = Int(s[byte = pos : pos + 2])
                pos += 2
                has_second = True

        if pos < length and (
            _byte(s, pos) == ord(".") or _byte(s, pos) == ord(",")
        ):
            if not has_second:
                raise Error("isoformat subsecond requires seconds")
            var parsed = _parse_subsecond(s, pos + 1, 6)
            microsecond = parsed.value
            pos = parsed.pos

        if pos < length:
            if _byte(s, pos) == ord("Z"):
                pos += 1
            elif _byte(s, pos) == ord("+") or _byte(s, pos) == ord("-"):
                var parsed = _parse_iso_timezone_offset(s, pos)
                tz = parsed.tz
                pos = parsed.pos
            else:
                raise Error("isoformat timezone is invalid")

    if pos != length:
        raise Error("isoformat string has trailing data")
    if microsecond >= US_PER_SECOND:
        # A rounded-up fraction carries into the seconds, possibly past :59.
        second += microsecond // US_PER_SECOND
        microsecond = microsecond % US_PER_SECOND
        if second >= 60:
            return Morrow(
                year, month, day, hour, minute, 0, microsecond, tz
            ).shift(seconds=second)
    if hour == 24:
        if minute != 0 or second != 0 or microsecond != 0:
            raise Error("midnight at the end of day must be exactly 24:00")
        return Morrow(year, month, day, 0, 0, 0, 0, tz).shift(days=1)
    return Morrow(year, month, day, hour, minute, second, microsecond, tz)


def _parse_iso_timezone_offset(
    date_str: String, date_pos: Int
) raises -> _ParsedZone:
    """An ISO offset: +hh, +hh:, +hh:mm or +hhmm ending the string."""
    var sign = _byte(date_str, date_pos)
    if sign != ord("+") and sign != ord("-"):
        raise Error("isoformat timezone must be a fixed offset")

    var pos = date_pos + 1
    if not _two_digits(date_str, pos):
        raise Error("isoformat timezone hour is invalid")
    pos += 2

    var length = date_str.byte_length()
    if pos == length:
        return _ParsedZone(_utc_offset(date_str, date_pos, pos), pos)
    if _byte(date_str, pos) == ord(":"):
        if pos + 1 == length:
            return _ParsedZone(_utc_offset(date_str, date_pos, pos), pos + 1)
        if not _two_digits(date_str, pos + 1):
            raise Error("isoformat timezone minute is invalid")
        pos += 3
    elif _two_digits(date_str, pos):
        pos += 2
    else:
        raise Error("isoformat timezone minute is invalid")

    if pos != length:
        raise Error("isoformat timezone has trailing data")
    return _ParsedZone(_utc_offset(date_str, date_pos, pos), pos)


# Arrow format tokens.


struct _Fields:
    """Fields collected while matching Arrow tokens, and the input position."""

    var pos: Int
    var year: Int
    var has_year: Bool
    var month: Int
    var has_month: Bool
    var day: Int
    var has_day: Bool
    var day_of_year: Int
    """-1 unless a DDD/DDDD token matched."""
    var weekday: Int
    """ISO weekday from a weekday name, or 0."""
    var hour: Int
    var minute: Int
    var second: Int
    var microsecond: Int
    var tz: TimeZone
    var meridian: Int
    """1 for AM, 2 for PM, 0 when absent."""

    def __init__(out self, pos: Int):
        self.pos = pos
        self.year = 1
        self.has_year = False
        self.month = 1
        self.has_month = False
        self.day = 1
        self.has_day = False
        self.day_of_year = -1
        self.weekday = 0
        self.hour = 0
        self.minute = 0
        self.second = 0
        self.microsecond = 0
        self.tz = Morrow._utc_timezone()
        self.meridian = 0


def _parse_arrow(
    date_str: String,
    fmt: String,
    tzinfo: TimeZone = TimeZone.none(),
    locale: Locale = Locale._fast_english(),
) raises -> Morrow:
    """Match fmt against the whole string, else at a word boundary inside it."""
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


def _parse_arrow_at(
    date_str: String,
    fmt: String,
    tzinfo: TimeZone,
    date_start: Int,
    allow_trailing_text: Bool,
    locale: Locale,
) raises -> Morrow:
    var fields = _Fields(date_start)
    var fmt_pos = 0
    while fmt_pos < fmt.byte_length():
        var c = _byte(fmt, fmt_pos)
        if c == ord("X") or c == ord("x"):
            # Timestamps stand alone and carry their own instant.
            if fmt_pos + 1 != fmt.byte_length():
                raise Error("timestamp token must be the full format")
            var parsed = _parse_timestamp_token(
                String(date_str[byte = fields.pos :]), c == ord("X")
            )
            if not tzinfo.is_none():
                return parsed.replace(tzinfo=tzinfo)
            return parsed
        fmt_pos = _parse_token(fields, date_str, fmt, fmt_pos, locale)

    if allow_trailing_text:
        if not _has_right_parse_boundary(date_str, fields.pos):
            raise Error("date string does not match format boundary")
    elif fields.pos != date_str.byte_length():
        raise Error("date string has trailing data")
    return _resolve(fields, tzinfo)


def _parse_token(
    mut f: _Fields, s: String, fmt: String, fmt_pos: Int, locale: Locale
) raises -> Int:
    """Match the token at fmt_pos against s at f.pos; return the next fmt_pos.

    Longer tokens win: "MMMM" is tried before "MMM", "MM" and "M".
    """
    var c = _byte(fmt, fmt_pos)
    if c >= 128:
        var width = utf8_width(fmt, fmt_pos)
        for j in range(width):
            _parse_literal_char(s, f.pos + j, fmt, fmt_pos + j)
        f.pos += width
        return fmt_pos + width
    if c == ord("["):
        return _parse_bracket(f, s, fmt, fmt_pos)

    if c == ord("Y"):
        if starts_at(fmt, fmt_pos, "YYYY"):
            f.year = _take_int(f, s, 4, True) - locale.year_offset
            f.has_year = True
            return fmt_pos + 4
        if starts_at(fmt, fmt_pos, "YY"):
            var yy = _take_int(f, s, 2, True)
            if locale.year_offset != 0:
                # Buddhist-era years: 00..99 map to 2500..2599 BE.
                f.year = 2500 + yy - locale.year_offset
            else:
                f.year = 1900 + yy if yy >= 69 else 2000 + yy
            f.has_year = True
            return fmt_pos + 2
    elif c == ord("M"):
        var length = _run_length(fmt, fmt_pos, 4)
        if length >= 3:
            var parsed = _parse_month_name(s, f.pos, length == 3, locale)
            f.month = parsed.value
            f.pos = parsed.pos
        else:
            f.month = _take_int(f, s, 2, length == 2)
        f.has_month = True
        return fmt_pos + length
    elif c == ord("D"):
        f.has_day = True
        if starts_at(fmt, fmt_pos, "DDD"):
            var fixed = starts_at(fmt, fmt_pos, "DDDD")
            f.day_of_year = _take_int(f, s, 3, fixed)
            return fmt_pos + (4 if fixed else 3)
        if starts_at(fmt, fmt_pos, "Do"):
            f.day = _parse_ordinal_day(f, s, locale)
            return fmt_pos + 2
        var fixed = starts_at(fmt, fmt_pos, "DD")
        f.day = _take_int(f, s, 2, fixed)
        return fmt_pos + (2 if fixed else 1)
    elif c == ord("W"):
        var parsed = _parse_iso_week_date(s, f.pos)
        var date = Morrow.fromisocalendar(
            parsed.year, parsed.week, parsed.weekday
        )
        f.year = date.year
        f.month = date.month
        f.day = date.day
        f.has_year = True
        f.has_month = True
        f.has_day = True
        f.pos = parsed.pos
        return fmt_pos + 1
    elif c == ord("d"):
        var length = _run_length(fmt, fmt_pos, 4)
        if length >= 3:
            var parsed = _parse_weekday_name(s, f.pos, length == 3, locale)
            f.weekday = parsed.value
            f.pos = parsed.pos
            return fmt_pos + length
        # A numeric weekday is checked but, as in Arrow, not used.
        var weekday = _take_int(f, s, 1, True)
        if weekday < 1 or weekday > 7:
            raise Error("weekday must be in 1..7")
        return fmt_pos + 1
    elif c == ord("H") or c == ord("h"):
        var fixed = _run_length(fmt, fmt_pos, 2) == 2
        f.hour = _take_int(f, s, 2, fixed)
        return fmt_pos + (2 if fixed else 1)
    elif c == ord("m"):
        var fixed = _run_length(fmt, fmt_pos, 2) == 2
        f.minute = _take_int(f, s, 2, fixed)
        return fmt_pos + (2 if fixed else 1)
    elif c == ord("s"):
        var fixed = _run_length(fmt, fmt_pos, 2) == 2
        f.second = _take_int(f, s, 2, fixed)
        return fmt_pos + (2 if fixed else 1)
    elif c == ord("S"):
        var length = _run_length(fmt, fmt_pos, fmt.byte_length())
        var parsed = _parse_subsecond(s, f.pos, length)
        f.microsecond = parsed.value
        f.pos = parsed.pos
        return fmt_pos + length
    elif c == ord("Z"):
        var length = _run_length(fmt, fmt_pos, 3)
        var parsed: _ParsedZone
        if length == 3:
            parsed = _parse_timezone_name(s, f.pos)
        else:
            parsed = _parse_timezone_offset(s, f.pos, length == 2)
        f.tz = parsed.tz
        f.pos = parsed.pos
        return fmt_pos + length
    elif c == ord("A") or c == ord("a"):
        var parsed = _parse_am_pm(s, f.pos, locale)
        f.meridian = parsed.value
        f.pos = parsed.pos
        return fmt_pos + 1

    _parse_literal_char(s, f.pos, fmt, fmt_pos)
    f.pos += 1
    return fmt_pos + 1


def _resolve(mut f: _Fields, tzinfo: TimeZone) raises -> Morrow:
    """Build the Morrow the matched fields describe."""
    if f.meridian == 1:
        if f.hour > 12:
            raise Error("hour must be in 0..12 for AM")
        if f.hour == 12:
            f.hour = 0
    elif f.meridian == 2:
        if f.hour < 12:
            f.hour += 12
    if f.day_of_year != -1:
        if not f.has_year:
            raise Error("year component is required with day of year")
        if f.has_month:
            raise Error("month component is not allowed with day of year")
        if f.day_of_year < 1 or f.day_of_year > 366:
            raise Error("day of year is invalid")
        var date = Morrow.fromordinal(ymd2ord(f.year, 1, 1) + f.day_of_year - 1)
        f.year = date.year
        f.month = date.month
        f.day = date.day
    elif f.weekday != 0 and not f.has_day:
        # A weekday name alone picks the first such day of the month.
        if not f.has_year:
            f.year = 1970
        if not f.has_month:
            f.month = 1
        var first_day = Morrow(f.year, f.month, 1)
        var offset = f.weekday - first_day.isoweekday()
        if offset < 0:
            offset += 7
        var date = first_day.shift(days=offset)
        f.year = date.year
        f.month = date.month
        f.day = date.day
    if f.microsecond >= US_PER_SECOND:
        f.second += f.microsecond // US_PER_SECOND
        f.microsecond = f.microsecond % US_PER_SECOND
    var end_of_day = f.hour == 24
    if end_of_day:
        if f.minute != 0:
            raise Error("midnight at the end of day must not contain minutes")
        if f.second != 0:
            raise Error("midnight at the end of day must not contain seconds")
        if f.microsecond != 0:
            raise Error(
                "midnight at the end of day must not contain microseconds"
            )
        f.hour = 0
    var result = Morrow(
        f.year,
        f.month,
        f.day,
        f.hour,
        f.minute,
        f.second,
        f.microsecond,
        f.tz if tzinfo.is_none() else tzinfo,
    )
    if end_of_day:
        return result.shift(days=1)
    return result


def _run_length(fmt: String, pos: Int, limit: Int) -> Int:
    """How many copies of fmt[pos] start at pos, up to limit."""
    var c = fmt.as_bytes()[pos]
    var end = pos + 1
    while (
        end < fmt.byte_length()
        and end - pos < limit
        and fmt.as_bytes()[end] == c
    ):
        end += 1
    return end - pos


def _take_int(
    mut f: _Fields, s: String, digits: Int, fixed: Bool
) raises -> Int:
    """Read exactly (fixed) or up to digits digits at f.pos and advance."""
    var parsed = _parse_fixed_int(s, f.pos, digits) if fixed else (
        _parse_variable_int(s, f.pos, digits)
    )
    f.pos = parsed.pos
    return parsed.value


def _parse_bracket(
    mut f: _Fields, s: String, fmt: String, fmt_pos: Int
) raises -> Int:
    """[text] matches text literally; [\\s+], [\\s*] and [\\s?] whitespace.

    An unclosed "[" is an ordinary literal character.
    """
    var start = fmt_pos + 1
    var end = start
    while end < fmt.byte_length() and _byte(fmt, end) != ord("]"):
        end += 1
    if end >= fmt.byte_length():
        _parse_literal_char(s, f.pos, fmt, fmt_pos)
        f.pos += 1
        return fmt_pos + 1

    var quantifier = 0
    if (
        end - start == 3
        and _byte(fmt, start) == ord("\\")
        and _byte(fmt, start + 1) == ord("s")
    ):
        quantifier = _byte(fmt, start + 2)
    if (
        quantifier == ord("+")
        or quantifier == ord("*")
        or quantifier == ord("?")
    ):
        var limit = 1 if quantifier == ord("?") else s.byte_length()
        var skipped = 0
        while (
            f.pos < s.byte_length()
            and skipped < limit
            and is_space(_byte(s, f.pos))
        ):
            f.pos += 1
            skipped += 1
        if quantifier == ord("+") and skipped == 0:
            raise Error("whitespace is missing")
    else:
        for literal_pos in range(start, end):
            _parse_literal_char(s, f.pos, fmt, literal_pos)
            f.pos += 1
    return end + 1


def _parse_ordinal_day(mut f: _Fields, s: String, locale: Locale) raises -> Int:
    """The Do token: "1st" in English, the locale's ordinals otherwise."""
    if not locale.is_fast_english():
        var matched = locale._match_ordinal(s, f.pos)
        f.pos = matched.pos
        return matched.value
    var start = f.pos
    var day = _take_int(f, s, 2, False)
    if f.pos - start > 1 and _byte(s, start) == ord("0"):
        raise Error("ordinal day must not contain a leading zero")
    f.pos = _parse_ordinal_suffix(s, f.pos, day)
    return day


def _parse_timestamp_token(text: String, seconds: Bool) raises -> Morrow:
    """X reads float seconds; x reads integer seconds, ms or µs."""
    var length = text.byte_length()
    if length == 0:
        raise Error("timestamp token is missing")
    var pos = 0
    if _byte(text, 0) == ord("-"):
        pos += 1
        if pos == length:
            raise Error("timestamp token is missing")
    var digit_start = pos
    while pos < length and is_digit(_byte(text, pos)):
        pos += 1
    if not seconds:
        if pos != length:
            raise Error("timestamp token has invalid characters")
        return Morrow._from_expanded_timestamp_value(Int(text))

    var digit_count = pos - digit_start
    if digit_count == 0:
        raise Error("timestamp token must start with digits")
    var has_fraction = False
    if pos < length and _byte(text, pos) == ord("."):
        has_fraction = True
        pos += 1
        var fraction_start = pos
        while pos < length and is_digit(_byte(text, pos)):
            pos += 1
        if pos == fraction_start:
            raise Error("timestamp token fraction is missing")
    if pos != length:
        raise Error("timestamp token has invalid characters")
    if not has_fraction and digit_count < 2:
        raise Error("timestamp token integer is too short")
    return Morrow.utcfromtimestamp(text)


def _parse_literal_char(
    date_str: String, date_pos: Int, fmt: String, fmt_pos: Int
) raises:
    if date_pos >= date_str.byte_length():
        raise Error("date string is shorter than format")
    if _byte(date_str, date_pos) != _byte(fmt, fmt_pos):
        raise Error("date string does not match format literal")


def _parse_fixed_int(
    date_str: String, date_pos: Int, count: Int
) raises -> _ParsedInt:
    if date_pos + count > date_str.byte_length():
        raise Error("date string is shorter than numeric token")
    if not _digits(date_str, date_pos, date_pos + count):
        raise Error("numeric token contains non-digit data")
    return _ParsedInt(
        Int(date_str[byte = date_pos : date_pos + count]), date_pos + count
    )


def _parse_variable_int(
    date_str: String, date_pos: Int, max_count: Int
) raises -> _ParsedInt:
    var pos = date_pos
    var end = min(date_pos + max_count, date_str.byte_length())
    while pos < end and is_digit(_byte(date_str, pos)):
        pos += 1
    if pos == date_pos:
        raise Error("numeric token is missing")
    return _ParsedInt(Int(date_str[byte=date_pos:pos]), pos)


def _parse_subsecond(
    date_str: String, date_pos: Int, count: Int
) raises -> _ParsedInt:
    """Fraction digits as microseconds, rounding half to even past six.

    Like Arrow, the token length does not limit how many digits are read.
    """
    var pos = date_pos
    while pos < date_str.byte_length() and is_digit(_byte(date_str, pos)):
        pos += 1
    if pos == date_pos:
        raise Error("subsecond token is missing")

    if pos - date_pos <= 6:
        var digits = String(date_str[byte=date_pos:pos])
        while digits.byte_length() < 6:
            digits += "0"
        return _ParsedInt(Int(digits), pos)

    var value = Int(date_str[byte = date_pos : date_pos + 6])
    var round_digit = _byte(date_str, date_pos + 6) - ord("0")
    var should_round = round_digit > 5
    if round_digit == 5:
        var has_remaining = False
        for i in range(date_pos + 7, pos):
            if _byte(date_str, i) != ord("0"):
                has_remaining = True
        should_round = has_remaining or value % 2 == 1
    if should_round:
        value += 1
    return _ParsedInt(value, pos)


def _parse_ordinal_suffix(
    date_str: String, date_pos: Int, value: Int
) raises -> Int:
    if date_pos + 2 > date_str.byte_length():
        raise Error("ordinal suffix is missing")
    var expected = "th"
    if value % 100 < 11 or value % 100 > 13:
        if value % 10 == 1:
            expected = "st"
        elif value % 10 == 2:
            expected = "nd"
        elif value % 10 == 3:
            expected = "rd"
    if starts_at_ascii_ignore_case(date_str, date_pos, expected):
        return date_pos + 2
    raise Error("ordinal suffix is invalid")


def _parse_month_name(
    date_str: String,
    date_pos: Int,
    abbreviated: Bool,
    locale: Locale,
) raises -> _ParsedInt:
    if not locale.is_fast_english():
        var matched = locale._match_month(date_str, date_pos, abbreviated)
        return _ParsedInt(matched.value, matched.pos)
    for value in range(1, 13):
        var name = month_abbreviation(value) if abbreviated else month_name(
            value
        )
        if starts_at_ascii_ignore_case(date_str, date_pos, name):
            return _ParsedInt(value, date_pos + name.byte_length())
    raise Error("month name is invalid")


def _parse_weekday_name(
    date_str: String,
    date_pos: Int,
    abbreviated: Bool,
    locale: Locale,
) raises -> _ParsedInt:
    if not locale.is_fast_english():
        var matched = locale._match_weekday(date_str, date_pos, abbreviated)
        return _ParsedInt(matched.value, matched.pos)
    for value in range(1, 8):
        var name = day_abbreviation(value) if abbreviated else day_name(value)
        if starts_at_ascii_ignore_case(date_str, date_pos, name):
            return _ParsedInt(value, date_pos + name.byte_length())
    raise Error("weekday name is invalid")


def _parse_iso_week_date(
    date_str: String, date_pos: Int
) raises -> _ParsedIsoWeek:
    """YYYY-Www[-D] or YYYYWww[D]; the weekday defaults to Monday."""
    var year_parsed = _parse_fixed_int(date_str, date_pos, 4)
    var pos = year_parsed.pos
    if pos < date_str.byte_length() and _byte(date_str, pos) == ord("-"):
        pos += 1
    if pos >= date_str.byte_length() or _byte(date_str, pos) != ord("W"):
        raise Error("ISO week date is missing W marker")
    var week_parsed = _parse_fixed_int(date_str, pos + 1, 2)
    pos = week_parsed.pos

    var weekday = 1
    var length = date_str.byte_length()
    if pos < length and _byte(date_str, pos) == ord("-"):
        if pos + 1 < length and is_digit(_byte(date_str, pos + 1)):
            var weekday_parsed = _parse_fixed_int(date_str, pos + 1, 1)
            weekday = weekday_parsed.value
            pos = weekday_parsed.pos
    elif pos < length and is_digit(_byte(date_str, pos)):
        var weekday_parsed = _parse_fixed_int(date_str, pos, 1)
        weekday = weekday_parsed.value
        pos = weekday_parsed.pos
    return _ParsedIsoWeek(year_parsed.value, week_parsed.value, weekday, pos)


def _parse_timezone_name(date_str: String, date_pos: Int) raises -> _ParsedZone:
    """An IANA name such as "Europe/Paris", or UTC/GMT in any case."""
    if date_pos >= date_str.byte_length():
        raise Error("timezone is missing")
    var end = date_pos
    while end < date_str.byte_length():
        var c = _byte(date_str, end)
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
        return _ParsedZone(Morrow._utc_timezone(), end)
    if name.byte_length() == 3 and starts_at_ascii_ignore_case(name, 0, "GMT"):
        return _ParsedZone(TimeZone(0, "GMT"), end)
    return _ParsedZone(TimeZone.from_name(name), end)


def _parse_timezone_offset(
    date_str: String, date_pos: Int, colon: Bool
) raises -> _ParsedZone:
    """Arrow's Z (+hhmm) and ZZ (+hh:mm) tokens; minutes are optional."""
    if starts_at(date_str, date_pos, "Z"):
        return _ParsedZone(Morrow._utc_timezone(), date_pos + 1)
    if date_pos >= date_str.byte_length():
        raise Error("timezone is missing")
    var sign = _byte(date_str, date_pos)
    if sign != ord("+") and sign != ord("-"):
        raise Error("timezone must be Z or a fixed offset")
    var pos = date_pos + 1
    if not _two_digits(date_str, pos):
        raise Error("timezone hour is invalid")
    pos += 2

    if pos < date_str.byte_length() and _byte(date_str, pos) == ord(":"):
        if not colon:
            raise Error("timezone offset must not contain a colon")
        if not _two_digits(date_str, pos + 1):
            # "+05:" stops before the colon, which the format may match.
            return _ParsedZone(_utc_offset(date_str, date_pos, pos), pos)
        pos += 3
    elif _two_digits(date_str, pos):
        if colon:
            raise Error("timezone offset minutes must contain a colon")
        pos += 2
    return _ParsedZone(_utc_offset(date_str, date_pos, pos), pos)


def _parse_am_pm(
    date_str: String, date_pos: Int, locale: Locale
) raises -> _ParsedInt:
    """Return 1 for AM or 2 for PM and the position after the marker."""
    if not locale.is_fast_english():
        var matched = locale._match_meridian(date_str, date_pos)
        return _ParsedInt(matched.value, matched.pos)
    if starts_at(date_str, date_pos, "AM") or starts_at(
        date_str, date_pos, "am"
    ):
        return _ParsedInt(1, date_pos + 2)
    if starts_at(date_str, date_pos, "PM") or starts_at(
        date_str, date_pos, "pm"
    ):
        return _ParsedInt(2, date_pos + 2)
    # Mixed-case markers are accepted without changing the hour (1.0).
    if starts_at_ascii_ignore_case(
        date_str, date_pos, "AM"
    ) or starts_at_ascii_ignore_case(date_str, date_pos, "PM"):
        return _ParsedInt(0, date_pos + 2)
    raise Error("AM/PM marker is invalid")


def _has_left_parse_boundary(s: String, pos: Int) -> Bool:
    """Whether a match may start at pos inside a longer string."""
    if pos == 0:
        return True
    var c = _byte(s, pos - 1)
    if is_space(c):
        return True
    if _is_parse_punctuation(c):
        return pos == 1 or is_space(_byte(s, pos - 2))
    return False


def _has_right_parse_boundary(s: String, pos: Int) -> Bool:
    """Whether a match may end at pos inside a longer string."""
    if pos == s.byte_length():
        return True
    var c = _byte(s, pos)
    if is_space(c):
        return True
    if _is_parse_punctuation(c):
        return pos + 1 == s.byte_length() or is_space(_byte(s, pos + 1))
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
    """Trim ASCII whitespace and collapse each inner run to one space."""
    var result = ""
    var pending_space = False
    var i = 0
    while i < s.byte_length():
        var width = utf8_width(s, i)
        if is_space(_byte(s, i)):
            if result.byte_length() > 0:
                pending_space = True
        else:
            if pending_space:
                result += " "
                pending_space = False
            result += s[byte = i : i + width]
        i += width
    return result


# strptime.


def _parse_strptime(
    date_str: String, fmt: String, tzinfo: TimeZone
) raises -> Morrow:
    """Parse with libc strptime, handling %f, %z and %Z in Mojo.

    Each extension directive is cut from the format, and its value from the
    input, after measuring with strptime where the value starts.
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
                and is_digit(_byte(normalized_date, value_end))
                and value_end - value_start < 6
            ):
                value_end += 1
            if value_end == value_start:
                raise Error("microsecond is missing")
            if value_end < normalized_date.byte_length() and is_digit(
                _byte(normalized_date, value_end)
            ):
                raise Error("unconverted data remains")

            var digits = String(normalized_date[byte=value_start:value_end])
            while digits.byte_length() < 6:
                digits += "0"
            microsecond = Int(digits)
        else:
            var parsed: _ParsedZone
            if directive.value == ord("z"):
                parsed = _parse_strptime_timezone_offset(
                    normalized_date, value_start
                )
            else:
                parsed = _parse_timezone_name(normalized_date, value_start)
            value_end = parsed.pos
            parsed_tz = parsed.tz

        normalized_date = String(normalized_date[byte=0:value_start]) + String(
            normalized_date[byte=value_end:]
        )
        normalized_fmt = prefix_fmt + String(
            normalized_fmt[byte = directive.pos + 2 :]
        )

    var tm = c_strptime(normalized_date, normalized_fmt)
    var tz: TimeZone
    if not tzinfo.is_none():
        tz = tzinfo
    elif not parsed_tz.is_none():
        tz = parsed_tz
    else:
        tz = TimeZone(Int(tm.tm_gmtoff))
    return Morrow(
        Int(tm.tm_year) + 1900,
        Int(tm.tm_mon) + 1,
        Int(tm.tm_mday),
        Int(tm.tm_hour),
        Int(tm.tm_min),
        Int(tm.tm_sec),
        microsecond,
        tz,
    )


def _find_strptime_extension_directive(fmt: String) -> _ParsedInt:
    """The first %f, %z or %Z: its letter and position, or position -1."""
    var pos = 0
    while pos + 1 < fmt.byte_length():
        if _byte(fmt, pos) != ord("%"):
            pos += 1
            continue
        var letter = _byte(fmt, pos + 1)
        if letter == ord("f") or letter == ord("z") or letter == ord("Z"):
            return _ParsedInt(letter, pos)
        pos += 2  # Also skips "%%".
    return _ParsedInt(0, -1)


def _parse_strptime_timezone_offset(
    date_str: String, date_pos: Int
) raises -> _ParsedZone:
    """%z: Z, +hh[:]mm or +hh[:]mm[:]ss, like Python's strptime."""
    if date_pos >= date_str.byte_length():
        raise Error("timezone is missing")
    if _byte(date_str, date_pos) == ord("Z"):
        return _ParsedZone(TimeZone.from_utc("UTC"), date_pos + 1)

    var sign = 1
    if _byte(date_str, date_pos) == ord("-"):
        sign = -1
    elif _byte(date_str, date_pos) != ord("+"):
        raise Error("timezone must be Z or a fixed offset")

    var pos = date_pos + 1
    if not _two_digits(date_str, pos):
        raise Error("timezone hour is invalid")
    var hours = Int(date_str[byte = pos : pos + 2])
    pos += 2

    var colon = pos < date_str.byte_length() and _byte(date_str, pos) == ord(
        ":"
    )
    if colon:
        pos += 1
    if not _two_digits(date_str, pos):
        raise Error("timezone minute is invalid")
    var minutes = Int(date_str[byte = pos : pos + 2])
    pos += 2
    var seconds = 0
    if colon:
        if pos < date_str.byte_length() and _byte(date_str, pos) == ord(":"):
            if not _two_digits(date_str, pos + 1):
                raise Error("timezone second is invalid")
            seconds = Int(date_str[byte = pos + 1 : pos + 3])
            pos += 3
    elif _two_digits(date_str, pos):
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
    return _ParsedZone(TimeZone(offset), pos)


# Byte helpers.


@always_inline
def _byte(s: String, pos: Int) -> Int:
    return Int(s.as_bytes()[pos])


def _digits(s: String, start: Int, end: Int) -> Bool:
    """Whether s[start:end] exists and holds only ASCII digits."""
    if end > s.byte_length():
        return False
    for i in range(start, end):
        if not is_digit(_byte(s, i)):
            return False
    return True


def _two_digits(s: String, pos: Int) -> Bool:
    return _digits(s, pos, pos + 2)


def _is_date_end(s: String, pos: Int) -> Bool:
    """Whether an ISO date may end at pos: end of text, "T", "t" or space."""
    if pos == s.byte_length():
        return True
    var c = _byte(s, pos)
    return c == ord("T") or c == ord("t") or c == ord(" ")


def _utc_offset(s: String, start: Int, end: Int) raises -> TimeZone:
    return TimeZone.from_utc(String(s[byte=start:end]))
