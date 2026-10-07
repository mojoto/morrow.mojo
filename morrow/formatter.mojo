from ._text import utf8_width, pad
from .timezone import format_offset
from ._calendar import (
    US_PER_SECOND,
    day_of_year,
    iso_calendar,
    epoch_seconds,
    month_name,
    month_abbreviation,
    day_name,
    day_abbreviation,
)


def format_morrow(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    microsecond: Int,
    tz_offset: Int,
    tz_name: String,
    tz_is_none: Bool,
    weekday: Int,
    fmt: String,
) raises -> String:
    """
    Format the Morrow object fields according to the given format string.

    Handles brackets for literal text: "YYYY[abc]MM" -> replace("YYYY") + "abc" + replace("MM")
    """
    if fmt.byte_length() == 0:
        return ""
    var ret: String = ""
    var in_bracket = False
    var start_idx = 0
    for i in range(fmt.byte_length()):
        if fmt.as_bytes()[i] == 91:
            if in_bracket:
                ret += "["
            else:
                in_bracket = True
            ret += _replace(
                year,
                month,
                day,
                hour,
                minute,
                second,
                microsecond,
                tz_offset,
                tz_name,
                tz_is_none,
                weekday,
                String(fmt[byte=start_idx:i]),
            )
            start_idx = i + 1
        elif fmt.as_bytes()[i] == 93:
            if in_bracket:
                ret += fmt[byte=start_idx:i]
                in_bracket = False
            else:
                ret += _replace(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    String(fmt[byte=start_idx:i]),
                )
                ret += "]"
            start_idx = i + 1
    if in_bracket:
        ret += "["
    if start_idx < fmt.byte_length():
        ret += _replace(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            tz_offset,
            tz_name,
            tz_is_none,
            weekday,
            String(fmt[byte=start_idx:]),
        )
    return ret


def format_strftime(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    microsecond: Int,
    tz_offset: Int,
    tz_name: String,
    tz_is_none: Bool,
    weekday: Int,
    fmt: String,
) raises -> String:
    """
    Format fields using the common Python ``datetime.strftime`` directives.
    """
    var ret = ""
    var i = 0
    while i < fmt.byte_length():
        if fmt.as_bytes()[i] == 37:
            i += 1
            if i >= fmt.byte_length():
                ret += "%"
            elif (
                fmt.as_bytes()[i] == 45
                or fmt.as_bytes()[i] == 95
                or fmt.as_bytes()[i] == 48
                or fmt.as_bytes()[i] == 69
                or fmt.as_bytes()[i] == 79
            ) and i + 1 < fmt.byte_length():
                var modifier = Int(fmt.as_bytes()[i])
                i += 1
                ret += _replace_strftime_modified_directive(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    modifier,
                    Int(fmt.as_bytes()[i]),
                    String(fmt[byte=i]),
                )
            else:
                ret += _replace_strftime_directive(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    Int(fmt.as_bytes()[i]),
                    String(fmt[byte=i]),
                )
        else:
            var width = utf8_width(fmt, i)
            ret += fmt[byte = i : i + width]
            i += width
            continue
        i += 1
    return ret


def _replace(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    microsecond: Int,
    tz_offset: Int,
    tz_name: String,
    tz_is_none: Bool,
    weekday: Int,
    s: String,
) raises -> String:
    """
    Replace formatting tokens in the string with their corresponding values.
    """
    if s.byte_length() == 0:
        return ""
    var ret: String = ""
    var match_chr_ord = 0
    var match_count = 0
    var i = 0
    while i < s.byte_length():
        var c = Int(s.as_bytes()[i])
        if (
            c == _D
            and match_chr_ord != _D
            and i + 1 < s.byte_length()
            and s.as_bytes()[i + 1] == 111
        ):
            if match_chr_ord > 0:
                ret += _replace_token(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    match_chr_ord,
                    match_count,
                )
                match_chr_ord = 0
                match_count = 0
            ret += _format_ordinal(day)
            i += 2
            continue
        if 0 < c and c < 128 and _sub_chr_max(c) > 0:
            if c == match_chr_ord:
                match_count += 1
            else:
                ret += _replace_token(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    match_chr_ord,
                    match_count,
                )
                match_chr_ord = c
                match_count = 1
            if match_count == _sub_chr_max(c):
                ret += _replace_token(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    match_chr_ord,
                    match_count,
                )
                match_chr_ord = 0
        else:
            if match_chr_ord > 0:
                ret += _replace_token(
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                    microsecond,
                    tz_offset,
                    tz_name,
                    tz_is_none,
                    weekday,
                    match_chr_ord,
                    match_count,
                )
                match_chr_ord = 0
            var width = utf8_width(s, i)
            ret += s[byte = i : i + width]
            i += width
            continue
        i += 1
    if match_chr_ord > 0:
        ret += _replace_token(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            tz_offset,
            tz_name,
            tz_is_none,
            weekday,
            match_chr_ord,
            match_count,
        )
    return ret


def _format_modified_number(value: Int, width: Int, modifier: Int) -> String:
    if modifier == ord("-"):
        return String(value)
    if modifier == ord("_"):
        return pad(value, width, " ")
    return pad(value, width)


def _replace_strftime_modified_directive(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    microsecond: Int,
    tz_offset: Int,
    tz_name: String,
    tz_is_none: Bool,
    weekday: Int,
    modifier: Int,
    directive: Int,
    directive_text: String,
) raises -> String:
    var day_of_year = day_of_year(year, month, day)
    var iso_week = _format_iso_week(year, month, day)
    if modifier == ord("E") or modifier == ord("O"):
        return _replace_strftime_directive(
            year,
            month,
            day,
            hour,
            minute,
            second,
            microsecond,
            tz_offset,
            tz_name,
            tz_is_none,
            weekday,
            directive,
            directive_text,
        )
    if directive == ord("d"):
        return _format_modified_number(day, 2, modifier)
    if directive == ord("m"):
        return _format_modified_number(month, 2, modifier)
    if directive == ord("y"):
        return String(pad(year, 4)[byte=2:4])
    if directive == ord("Y"):
        return pad(year, 4)
    if directive == ord("C"):
        return pad(year // 100, 2)
    if directive == ord("h"):
        return month_abbreviation(month)
    if directive == ord("H"):
        return _format_modified_number(hour, 2, modifier)
    if directive == ord("I"):
        var hour_12 = hour % 12
        if hour_12 == 0:
            hour_12 = 12
        return _format_modified_number(hour_12, 2, modifier)
    if directive == ord("r"):
        return _format_strftime_12_hour_time(hour, minute, second)
    if directive == ord("v"):
        return _format_strftime_v(year, month, day)
    if directive == ord("M"):
        return _format_modified_number(minute, 2, modifier)
    if directive == ord("S"):
        return _format_modified_number(second, 2, modifier)
    if directive == ord("j"):
        return _format_modified_number(day_of_year, 3, modifier)
    if directive == ord("U"):
        return _format_modified_number(
            _week_number(day_of_year, 0 if weekday == 7 else weekday),
            2,
            modifier,
        )
    if directive == ord("W"):
        return _format_modified_number(
            _week_number(day_of_year, weekday - 1), 2, modifier
        )
    if directive == ord("V"):
        return _format_modified_number(Int(iso_week[byte=6:8]), 2, modifier)
    if directive == ord("z") or directive == ord("Z"):
        return ""
    if modifier == ord("-"):
        return "-" + directive_text
    if modifier == ord("_"):
        return "_" + directive_text
    return "0" + directive_text


def _replace_strftime_directive(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    microsecond: Int,
    tz_offset: Int,
    tz_name: String,
    tz_is_none: Bool,
    weekday: Int,
    directive: Int,
    directive_text: String,
) raises -> String:
    var day_of_year = day_of_year(year, month, day)
    var iso_week = _format_iso_week(year, month, day)
    if directive == ord("%"):
        return "%"
    if directive == ord("a"):
        return day_abbreviation(weekday)
    if directive == ord("A"):
        return day_name(weekday)
    if directive == ord("w"):
        return "0" if weekday == 7 else String(weekday)
    if directive == ord("u"):
        return String(weekday)
    if directive == ord("d"):
        return pad(day, 2)
    if directive == ord("e"):
        return pad(day, 2, " ")
    if directive == ord("b"):
        return month_abbreviation(month)
    if directive == ord("h"):
        return month_abbreviation(month)
    if directive == ord("B"):
        return month_name(month)
    if directive == ord("m"):
        return pad(month, 2)
    if directive == ord("y"):
        return String(pad(year, 4)[byte=2:4])
    if directive == ord("Y"):
        return pad(year, 4)
    if directive == ord("C"):
        return pad(year // 100, 2)
    if directive == ord("H"):
        return pad(hour, 2)
    if directive == ord("k"):
        return pad(hour, 2, " ")
    if directive == ord("I"):
        var hour_12 = hour % 12
        if hour_12 == 0:
            hour_12 = 12
        return pad(hour_12, 2)
    if directive == ord("l"):
        var hour_12 = hour % 12
        if hour_12 == 0:
            hour_12 = 12
        return pad(hour_12, 2, " ")
    if directive == ord("r"):
        return _format_strftime_12_hour_time(hour, minute, second)
    if directive == ord("p"):
        return "AM" if hour < 12 else "PM"
    if directive == ord("M"):
        return pad(minute, 2)
    if directive == ord("S"):
        return pad(second, 2)
    if directive == ord("f"):
        return pad(microsecond, 6)
    if directive == ord("z"):
        return format_offset(0 if tz_is_none else tz_offset, "")
    if directive == ord("Z"):
        if tz_is_none or tz_name == "utc" or tz_name == "UTC":
            return "UTC"
        if tz_name.byte_length() > 0:
            return tz_name
        if tz_offset == 0:
            return "UTC"
        return "UTC" + format_offset(tz_offset)
    if directive == ord("j"):
        return pad(day_of_year, 3)
    if directive == ord("U"):
        return _format_week_number(day_of_year, 0 if weekday == 7 else weekday)
    if directive == ord("W"):
        return _format_week_number(day_of_year, weekday - 1)
    if directive == ord("G"):
        return String(iso_week[byte=0:4])
    if directive == ord("g"):
        return String(iso_week[byte=2:4])
    if directive == ord("V"):
        return String(iso_week[byte=6:8])
    if directive == ord("F"):
        return pad(year, 4) + "-" + pad(month, 2) + "-" + pad(day, 2)
    if directive == ord("T"):
        return pad(hour, 2) + ":" + pad(minute, 2) + ":" + pad(second, 2)
    if directive == ord("R"):
        return pad(hour, 2) + ":" + pad(minute, 2)
    if directive == ord("D"):
        return (
            pad(month, 2)
            + "/"
            + pad(day, 2)
            + "/"
            + String(pad(year, 4)[byte=2:4])
        )
    if directive == ord("v"):
        return _format_strftime_v(year, month, day)
    if directive == ord("c"):
        return (
            day_abbreviation(weekday)
            + " "
            + month_abbreviation(month)
            + " "
            + pad(day, 2, " ")
            + " "
            + pad(hour, 2)
            + ":"
            + pad(minute, 2)
            + ":"
            + pad(second, 2)
            + " "
            + pad(year, 4)
        )
    if directive == ord("x"):
        return (
            pad(month, 2)
            + "/"
            + pad(day, 2)
            + "/"
            + String(pad(year, 4)[byte=2:4])
        )
    if directive == ord("X"):
        return pad(hour, 2) + ":" + pad(minute, 2) + ":" + pad(second, 2)
    if directive == ord("s"):
        return String(
            _timestamp_seconds(
                year, month, day, hour, minute, second, tz_offset
            )
        )
    if directive == ord("n"):
        return "\n"
    if directive == ord("t"):
        return "\t"
    return directive_text


def _format_strftime_12_hour_time(
    hour: Int, minute: Int, second: Int
) -> String:
    var hour_12 = hour % 12
    if hour_12 == 0:
        hour_12 = 12
    return (
        pad(hour_12, 2)
        + ":"
        + pad(minute, 2)
        + ":"
        + pad(second, 2)
        + " "
        + ("AM" if hour < 12 else "PM")
    )


def _format_strftime_v(year: Int, month: Int, day: Int) -> String:
    return (
        pad(day, 2, " ") + "-" + month_abbreviation(month) + "-" + pad(year, 4)
    )


def _replace_token(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    microsecond: Int,
    tz_offset: Int,
    tz_name: String,
    tz_is_none: Bool,
    weekday: Int,
    token: Int,
    token_count: Int,
) raises -> String:
    # Replace individual formatting tokens based on their type and count.
    if token == _Y:
        if token_count == 1:
            return "Y"
        if token_count == 2:
            return String(pad(year, 4)[byte=2:4])
        if token_count == 4:
            return pad(year, 4)
    elif token == _M:
        if token_count == 1:
            return String(month)
        if token_count == 2:
            return pad(month, 2)
        if token_count == 3:
            return month_abbreviation(month)
        if token_count == 4:
            return month_name(month)
    elif token == _D:
        var day_of_year = day_of_year(year, month, day)
        if token_count == 1:
            return String(day)
        if token_count == 2:
            return pad(day, 2)
        if token_count == 3:
            return String(day_of_year)
        if token_count == 4:
            return pad(day_of_year, 3)
    elif token == _H:
        if token_count == 1:
            return String(hour)
        if token_count == 2:
            return pad(hour, 2)
    elif token == _h:
        var h_12 = hour % 12
        if h_12 == 0:
            h_12 = 12
        if token_count == 1:
            return String(h_12)
        if token_count == 2:
            return pad(h_12, 2)
    elif token == _m:
        if token_count == 1:
            return String(minute)
        if token_count == 2:
            return pad(minute, 2)
    elif token == _s:
        if token_count == 1:
            return String(second)
        if token_count == 2:
            return pad(second, 2)
    elif token == _S:
        if token_count == 1:
            return String(microsecond // 100000)
        if token_count == 2:
            return pad(microsecond // 10000, 2)
        if token_count == 3:
            return pad(microsecond // 1000, 3)
        if token_count == 4:
            return pad(microsecond // 100, 4)
        if token_count == 5:
            return pad(microsecond // 10, 5)
        if token_count == 6:
            return pad(microsecond, 6)
    elif token == _d:
        if token_count == 1:
            return String(weekday)
        if token_count == 3:
            return day_abbreviation(weekday)
        if token_count == 4:
            return day_name(weekday)
    elif token == _Z:
        if token_count == 3:
            if tz_is_none or tz_name == "utc" or tz_name == "UTC":
                return "UTC"
            if tz_name.byte_length() > 0:
                return tz_name
            if tz_offset == 0:
                return "UTC"
            return "UTC" + format_offset(tz_offset)
        var separator = "" if token_count == 1 else ":"
        if tz_is_none:
            return format_offset(0, separator, False)
        else:
            return format_offset(tz_offset, separator, False)

    elif token == _W:
        return _format_iso_week(year, month, day)
    elif token == _X:
        return _format_timestamp_seconds(
            _timestamp_seconds(
                year, month, day, hour, minute, second, tz_offset
            ),
            microsecond,
        )
    elif token == _x:
        return String(
            _timestamp_seconds(
                year, month, day, hour, minute, second, tz_offset
            )
            * US_PER_SECOND
            + microsecond
        )
    elif token == _a:
        return "am" if hour < 12 else "pm"
    elif token == _A:
        return "AM" if hour < 12 else "PM"
    return ""


def _format_ordinal(value: Int) -> String:
    var suffix = "th"
    var last_two = value % 100
    if last_two < 11 or last_two > 13:
        var last = value % 10
        if last == 1:
            suffix = "st"
        elif last == 2:
            suffix = "nd"
        elif last == 3:
            suffix = "rd"
    return String(value) + suffix


def _format_week_number(day_of_year: Int, weekday_zero_based: Int) -> String:
    return pad(_week_number(day_of_year, weekday_zero_based), 2)


def _week_number(day_of_year: Int, weekday_zero_based: Int) -> Int:
    var yday_zero_based = day_of_year - 1
    return (yday_zero_based + 7 - weekday_zero_based) // 7


def _timestamp_seconds(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    tz_offset: Int,
) -> Int:
    return epoch_seconds(year, month, day, hour, minute, second) - tz_offset


def _format_timestamp_seconds(seconds: Int, microsecond: Int) -> String:
    if seconds == 0 and microsecond > 0:
        return String(Float64(microsecond) / Float64(US_PER_SECOND))
    if seconds < 0 and microsecond > 0:
        var total_us = seconds * US_PER_SECOND + microsecond
        return String(Float64(total_us) / Float64(US_PER_SECOND))

    var fraction = pad(microsecond, 6)
    var end = fraction.byte_length()
    while end > 1 and fraction.as_bytes()[end - 1] == 48:
        end -= 1
    return String(seconds) + "." + String(fraction[byte=0:end])


def _format_iso_week(year: Int, month: Int, day: Int) -> String:
    var iso = iso_calendar(year, month, day)
    return pad(iso[0], 4) + "-W" + pad(iso[1], 2) + "-" + String(iso[2])


def _sub_chr_max(c: Int) -> Int:
    if c == _Y:
        return 4
    if c == _M:
        return 4
    if c == _D:
        return 4
    if c == _d:
        return 4
    if c == _H:
        return 2
    if c == _h:
        return 2
    if c == _m:
        return 2
    if c == _s:
        return 2
    if c == _S:
        return 6
    if c == _Z:
        return 3
    if c == _W:
        return 1
    if c == _X:
        return 1
    if c == _x:
        return 1
    if c == _A:
        return 1
    if c == _a:
        return 1
    return 0


# Define constants for formatting characters.
comptime _Y = ord("Y")  # Year
comptime _M = ord("M")  # Month
comptime _D = ord("D")  # Day
comptime _d = ord("d")  # Day of week
comptime _W = ord("W")  # ISO week date
comptime _H = ord("H")  # Hour (24-hour)
comptime _h = ord("h")  # Hour (12-hour)
comptime _m = ord("m")  # Minute
comptime _s = ord("s")  # Second
comptime _S = ord("S")  # Microsecond
comptime _Z = ord("Z")  # Timezone
comptime _X = ord("X")  # Unix timestamp in seconds
comptime _x = ord("x")  # Unix timestamp in microseconds
comptime _A = ord("A")  # AM/PM
comptime _a = ord("a")  # am/pm
