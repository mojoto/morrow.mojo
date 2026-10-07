"""Arrow-style token formatting and Python strftime directives."""

from ._text import utf8_width, pad
from ._calendar import (
    US_PER_SECOND,
    day_of_year,
    epoch_seconds,
    iso_calendar,
    month_name,
    month_abbreviation,
    day_name,
    day_abbreviation,
)
from .timezone import format_offset
from .morrow import Morrow


def format_morrow(value: Morrow, fmt: String) raises -> String:
    """Format with Arrow tokens; text in [brackets] is copied literally."""
    var weekday = value.isoweekday()
    var result = String("")
    var in_bracket = False
    var start = 0
    for i in range(fmt.byte_length()):
        var c = Int(fmt.as_bytes()[i])
        if c == ord("["):
            if in_bracket:
                result += "["
            result += _format_tokens(value, weekday, String(fmt[byte=start:i]))
            in_bracket = True
            start = i + 1
        elif c == ord("]"):
            if in_bracket:
                result += fmt[byte=start:i]
                in_bracket = False
            else:
                result += _format_tokens(
                    value, weekday, String(fmt[byte=start:i])
                )
                result += "]"
            start = i + 1
    if in_bracket:
        result += "["
    if start < fmt.byte_length():
        result += _format_tokens(value, weekday, String(fmt[byte=start:]))
    return result


def format_strftime(value: Morrow, fmt: String) raises -> String:
    """Format with the common Python `datetime.strftime` directives."""
    var weekday = value.isoweekday()
    var result = String("")
    var i = 0
    while i < fmt.byte_length():
        if Int(fmt.as_bytes()[i]) != ord("%"):
            var width = utf8_width(fmt, i)
            result += fmt[byte = i : i + width]
            i += width
            continue
        i += 1
        if i >= fmt.byte_length():
            result += "%"
            break
        var modifier = Int(fmt.as_bytes()[i])
        if _is_strftime_modifier(modifier) and i + 1 < fmt.byte_length():
            i += 1
            result += _strftime_modified(
                value, weekday, modifier, String(fmt[byte=i])
            )
        else:
            result += _strftime_directive(value, weekday, String(fmt[byte=i]))
        i += 1
    return result


# Arrow tokens.


def _token_max_length(c: Int) -> Int:
    """Longest run of c that forms one token, or 0 if c is not a token."""
    if c == ord("Y") or c == ord("M") or c == ord("D") or c == ord("d"):
        return 4
    if c == ord("H") or c == ord("h") or c == ord("m") or c == ord("s"):
        return 2
    if c == ord("S"):
        return 6
    if c == ord("Z"):
        return 3
    if (
        c == ord("W")
        or c == ord("X")
        or c == ord("x")
        or c == ord("A")
        or c == ord("a")
    ):
        return 1
    return 0


def _format_tokens(value: Morrow, weekday: Int, s: String) raises -> String:
    """Replace runs of token characters in s; other text is kept."""
    var result = String("")
    var token = 0
    var count = 0
    var i = 0
    while i < s.byte_length():
        var c = Int(s.as_bytes()[i])
        if (
            c == ord("D")
            and token != ord("D")
            and i + 1 < s.byte_length()
            and Int(s.as_bytes()[i + 1]) == ord("o")
        ):
            # "Do" is the ordinal day, e.g. "1st".
            result += _format_token(value, weekday, token, count)
            token = 0
            result += _ordinal(value.day)
            i += 2
            continue
        if c < 128 and _token_max_length(c) > 0:
            if c == token:
                count += 1
            else:
                result += _format_token(value, weekday, token, count)
                token = c
                count = 1
            if count == _token_max_length(c):
                result += _format_token(value, weekday, token, count)
                token = 0
            i += 1
            continue
        result += _format_token(value, weekday, token, count)
        token = 0
        var width = utf8_width(s, i)
        result += s[byte = i : i + width]
        i += width
    result += _format_token(value, weekday, token, count)
    return result


def _format_token(
    value: Morrow, weekday: Int, token: Int, count: Int
) raises -> String:
    """Text for count repetitions of token; empty for no or unknown runs."""
    if token == ord("Y"):
        if count == 1:
            return "Y"
        if count == 2:
            return _two_digit_year(value.year)
        if count == 4:
            return pad(value.year, 4)
    elif token == ord("M"):
        if count == 1:
            return String(value.month)
        if count == 2:
            return pad(value.month, 2)
        if count == 3:
            return month_abbreviation(value.month)
        if count == 4:
            return month_name(value.month)
    elif token == ord("D"):
        if count == 1:
            return String(value.day)
        if count == 2:
            return pad(value.day, 2)
        if count == 3:
            return String(day_of_year(value.year, value.month, value.day))
        if count == 4:
            return pad(day_of_year(value.year, value.month, value.day), 3)
    elif token == ord("H"):
        return _number(value.hour, count)
    elif token == ord("h"):
        return _number(_hour_12(value.hour), count)
    elif token == ord("m"):
        return _number(value.minute, count)
    elif token == ord("s"):
        return _number(value.second, count)
    elif token == ord("S"):
        # S..SSSSSS: the leading count digits of the microseconds.
        var divisor = 1
        for _ in range(6 - count):
            divisor *= 10
        return pad(value.microsecond // divisor, count)
    elif token == ord("d"):
        if count == 1:
            return String(weekday)
        if count == 3:
            return day_abbreviation(weekday)
        if count == 4:
            return day_name(weekday)
    elif token == ord("Z"):
        if count == 3:
            return _zone_name(value)
        var offset = 0 if value.tz.is_none() else value.tz.offset
        return format_offset(offset, "" if count == 1 else ":", False)
    elif token == ord("W"):
        var iso = iso_calendar(value.year, value.month, value.day)
        return pad(iso[0], 4) + "-W" + pad(iso[1], 2) + "-" + String(weekday)
    elif token == ord("X"):
        return _timestamp_text(_utc_seconds(value), value.microsecond)
    elif token == ord("x"):
        return String(_utc_seconds(value) * US_PER_SECOND + value.microsecond)
    elif token == ord("a"):
        return "am" if value.hour < 12 else "pm"
    elif token == ord("A"):
        return "AM" if value.hour < 12 else "PM"
    return ""


def _number(n: Int, count: Int) -> String:
    """A one- or two-character numeric token."""
    if count == 1:
        return String(n)
    if count == 2:
        return pad(n, 2)
    return ""


def _timestamp_text(seconds: Int, microsecond: Int) -> String:
    """Seconds with the shortest fraction, as Arrow's `X` prints them."""
    if microsecond > 0 and seconds <= 0:
        return String(
            Float64(seconds * US_PER_SECOND + microsecond)
            / Float64(US_PER_SECOND)
        )
    var fraction = pad(microsecond, 6)
    var end = fraction.byte_length()
    while end > 1 and Int(fraction.as_bytes()[end - 1]) == ord("0"):
        end -= 1
    return String(seconds) + "." + String(fraction[byte=0:end])


# strftime.


def _is_strftime_modifier(c: Int) -> Bool:
    """A glibc flag (-, _, 0) or POSIX alternative (E, O) before a directive."""
    return (
        c == ord("-")
        or c == ord("_")
        or c == ord("0")
        or c == ord("E")
        or c == ord("O")
    )


def _strftime_modified(
    value: Morrow, weekday: Int, modifier: Int, directive: String
) raises -> String:
    """A directive after a modifier; flags change numeric padding only."""
    if modifier == ord("E") or modifier == ord("O"):
        return _strftime_directive(value, weekday, directive)
    var d = Int(directive.as_bytes()[0])
    var number = -1
    var width = 2
    if d == ord("d"):
        number = value.day
    elif d == ord("m"):
        number = value.month
    elif d == ord("H"):
        number = value.hour
    elif d == ord("I"):
        number = _hour_12(value.hour)
    elif d == ord("M"):
        number = value.minute
    elif d == ord("S"):
        number = value.second
    elif d == ord("j"):
        number = day_of_year(value.year, value.month, value.day)
        width = 3
    elif d == ord("U"):
        number = _week_number(value, 0 if weekday == 7 else weekday)
    elif d == ord("W"):
        number = _week_number(value, weekday - 1)
    elif d == ord("V"):
        number = iso_calendar(value.year, value.month, value.day)[1]
    if number >= 0:
        if modifier == ord("-"):
            return String(number)
        if modifier == ord("_"):
            return pad(number, width, " ")
        return pad(number, width)
    if (
        d == ord("y")
        or d == ord("Y")
        or d == ord("C")
        or d == ord("h")
        or d == ord("r")
        or d == ord("v")
    ):
        return _strftime_directive(value, weekday, directive)
    if d == ord("z") or d == ord("Z"):
        return ""
    return chr(modifier) + directive


def _strftime_directive(
    value: Morrow, weekday: Int, directive: String
) raises -> String:
    var d = Int(directive.as_bytes()[0])
    if d == ord("%"):
        return "%"
    if d == ord("a"):
        return day_abbreviation(weekday)
    if d == ord("A"):
        return day_name(weekday)
    if d == ord("w"):
        return "0" if weekday == 7 else String(weekday)
    if d == ord("u"):
        return String(weekday)
    if d == ord("d"):
        return pad(value.day, 2)
    if d == ord("e"):
        return pad(value.day, 2, " ")
    if d == ord("b") or d == ord("h"):
        return month_abbreviation(value.month)
    if d == ord("B"):
        return month_name(value.month)
    if d == ord("m"):
        return pad(value.month, 2)
    if d == ord("y"):
        return _two_digit_year(value.year)
    if d == ord("Y"):
        return pad(value.year, 4)
    if d == ord("C"):
        return pad(value.year // 100, 2)
    if d == ord("H"):
        return pad(value.hour, 2)
    if d == ord("k"):
        return pad(value.hour, 2, " ")
    if d == ord("I"):
        return pad(_hour_12(value.hour), 2)
    if d == ord("l"):
        return pad(_hour_12(value.hour), 2, " ")
    if d == ord("r"):
        return (
            pad(_hour_12(value.hour), 2)
            + ":"
            + pad(value.minute, 2)
            + ":"
            + pad(value.second, 2)
            + " "
            + ("AM" if value.hour < 12 else "PM")
        )
    if d == ord("p"):
        return "AM" if value.hour < 12 else "PM"
    if d == ord("M"):
        return pad(value.minute, 2)
    if d == ord("S"):
        return pad(value.second, 2)
    if d == ord("f"):
        return pad(value.microsecond, 6)
    if d == ord("z"):
        return format_offset(0 if value.tz.is_none() else value.tz.offset, "")
    if d == ord("Z"):
        return _zone_name(value)
    if d == ord("j"):
        return pad(day_of_year(value.year, value.month, value.day), 3)
    if d == ord("U"):
        return pad(_week_number(value, 0 if weekday == 7 else weekday), 2)
    if d == ord("W"):
        return pad(_week_number(value, weekday - 1), 2)
    if d == ord("G"):
        return pad(iso_calendar(value.year, value.month, value.day)[0], 4)
    if d == ord("g"):
        return _two_digit_year(
            iso_calendar(value.year, value.month, value.day)[0]
        )
    if d == ord("V"):
        return pad(iso_calendar(value.year, value.month, value.day)[1], 2)
    if d == ord("F"):
        return value.date().to_string()
    if d == ord("T") or d == ord("X"):
        return _clock(value)
    if d == ord("R"):
        return pad(value.hour, 2) + ":" + pad(value.minute, 2)
    if d == ord("D") or d == ord("x"):
        return (
            pad(value.month, 2)
            + "/"
            + pad(value.day, 2)
            + "/"
            + _two_digit_year(value.year)
        )
    if d == ord("v"):
        return (
            pad(value.day, 2, " ")
            + "-"
            + month_abbreviation(value.month)
            + "-"
            + pad(value.year, 4)
        )
    if d == ord("c"):
        return (
            day_abbreviation(weekday)
            + " "
            + month_abbreviation(value.month)
            + " "
            + pad(value.day, 2, " ")
            + " "
            + _clock(value)
            + " "
            + pad(value.year, 4)
        )
    if d == ord("s"):
        return String(_utc_seconds(value))
    if d == ord("n"):
        return "\n"
    if d == ord("t"):
        return "\t"
    return directive


# Shared pieces.


def _hour_12(hour: Int) -> Int:
    return hour % 12 or 12


def _two_digit_year(year: Int) -> String:
    return String(pad(year, 4)[byte=2:4])


def _clock(value: Morrow) -> String:
    return (
        pad(value.hour, 2)
        + ":"
        + pad(value.minute, 2)
        + ":"
        + pad(value.second, 2)
    )


def _zone_name(value: Morrow) -> String:
    """`ZZZ` and `%Z`: the zone name, or "UTC" with any offset it carries."""
    var name = value.tz.name
    if value.tz.is_none() or name == "utc" or name == "UTC":
        return "UTC"
    if name.byte_length() > 0:
        return name
    if value.tz.offset == 0:
        return "UTC"
    return "UTC" + format_offset(value.tz.offset)


def _utc_seconds(value: Morrow) -> Int:
    """Whole POSIX seconds of the instant."""
    return (
        epoch_seconds(
            value.year,
            value.month,
            value.day,
            value.hour,
            value.minute,
            value.second,
        )
        - value.tz.offset
    )


def _week_number(value: Morrow, weekday_zero_based: Int) -> Int:
    """`%U`/`%W` week of the year counting from the first such weekday."""
    var yday = day_of_year(value.year, value.month, value.day) - 1
    return (yday + 7 - weekday_zero_based) // 7


def _ordinal(n: Int) -> String:
    """English ordinal such as "1st", "12th" or "23rd"."""
    var suffix = "th"
    if n % 100 < 11 or n % 100 > 13:
        if n % 10 == 1:
            suffix = "st"
        elif n % 10 == 2:
            suffix = "nd"
        elif n % 10 == 3:
            suffix = "rd"
    return String(n) + suffix
