from .constants import (
    month_name,
    month_abbreviation,
    day_name,
    day_abbreviation,
)
from .util import _ymd2ord


comptime _US_PER_SECOND = 1000000
comptime _UNIX_EPOCH_ORDINAL = 719163  # 1970-01-01


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
        if fmt[byte=i] == "[":
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
        elif fmt[byte=i] == "]":
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
        if fmt[byte=i] == "%":
            i += 1
            if i >= fmt.byte_length():
                ret += "%"
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
                    ord(fmt[byte=i]),
                    String(fmt[byte=i]),
                )
        else:
            ret += fmt[byte=i]
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
        var c = ord(s[byte=i])
        if c == _D and i + 1 < s.byte_length() and s[byte=i + 1] == "o":
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
            ret += s[byte=i]
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
    var day_of_year = _day_of_year(year, month, day)
    var iso_week = _format_iso_week(year, month, day, weekday)
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
        return String(day).ascii_rjust(2, "0")
    if directive == ord("b"):
        return month_abbreviation(month)
    if directive == ord("B"):
        return month_name(month)
    if directive == ord("m"):
        return String(month).ascii_rjust(2, "0")
    if directive == ord("y"):
        return String(String(year).ascii_rjust(4, "0")[byte=2:4])
    if directive == ord("Y"):
        return String(year).ascii_rjust(4, "0")
    if directive == ord("H"):
        return String(hour).ascii_rjust(2, "0")
    if directive == ord("I"):
        var hour_12 = hour % 12
        if hour_12 == 0:
            hour_12 = 12
        return String(hour_12).ascii_rjust(2, "0")
    if directive == ord("p"):
        return "AM" if hour < 12 else "PM"
    if directive == ord("M"):
        return String(minute).ascii_rjust(2, "0")
    if directive == ord("S"):
        return String(second).ascii_rjust(2, "0")
    if directive == ord("f"):
        return String(microsecond).ascii_rjust(6, "0")
    if directive == ord("z"):
        return _format_timezone(0 if tz_is_none else tz_offset, "")
    if directive == ord("Z"):
        if tz_is_none:
            return "UTC"
        if tz_name.byte_length() > 0:
            return tz_name
        return _format_timezone(tz_offset)
    if directive == ord("j"):
        return String(day_of_year).ascii_rjust(3, "0")
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
        return (
            String(year).ascii_rjust(4, "0")
            + "-"
            + String(month).ascii_rjust(2, "0")
            + "-"
            + String(day).ascii_rjust(2, "0")
        )
    if directive == ord("T"):
        return (
            String(hour).ascii_rjust(2, "0")
            + ":"
            + String(minute).ascii_rjust(2, "0")
            + ":"
            + String(second).ascii_rjust(2, "0")
        )
    if directive == ord("R"):
        return (
            String(hour).ascii_rjust(2, "0")
            + ":"
            + String(minute).ascii_rjust(2, "0")
        )
    if directive == ord("D"):
        return (
            String(month).ascii_rjust(2, "0")
            + "/"
            + String(day).ascii_rjust(2, "0")
            + "/"
            + String(String(year).ascii_rjust(4, "0")[byte=2:4])
        )
    if directive == ord("c"):
        return (
            day_abbreviation(weekday)
            + " "
            + month_abbreviation(month)
            + " "
            + String(day).ascii_rjust(2, "0")
            + " "
            + String(hour).ascii_rjust(2, "0")
            + ":"
            + String(minute).ascii_rjust(2, "0")
            + ":"
            + String(second).ascii_rjust(2, "0")
            + " "
            + String(year).ascii_rjust(4, "0")
        )
    if directive == ord("x"):
        return (
            String(month).ascii_rjust(2, "0")
            + "/"
            + String(day).ascii_rjust(2, "0")
            + "/"
            + String(String(year).ascii_rjust(4, "0")[byte=2:4])
        )
    if directive == ord("X"):
        return (
            String(hour).ascii_rjust(2, "0")
            + ":"
            + String(minute).ascii_rjust(2, "0")
            + ":"
            + String(second).ascii_rjust(2, "0")
        )
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
    return "%" + directive_text


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
            return String(String(year).ascii_rjust(4, "0")[byte=2:4])
        if token_count == 4:
            return String(year).ascii_rjust(4, "0")
    elif token == _M:
        if token_count == 1:
            return String(month)
        if token_count == 2:
            return String(month).ascii_rjust(2, "0")
        if token_count == 3:
            return month_abbreviation(month)
        if token_count == 4:
            return month_name(month)
    elif token == _D:
        var day_of_year = _day_of_year(year, month, day)
        if token_count == 1:
            return String(day)
        if token_count == 2:
            return String(day).ascii_rjust(2, "0")
        if token_count == 3:
            return String(day_of_year)
        if token_count == 4:
            return String(day_of_year).ascii_rjust(3, "0")
    elif token == _H:
        if token_count == 1:
            return String(hour)
        if token_count == 2:
            return String(hour).ascii_rjust(2, "0")
    elif token == _h:
        var h_12 = hour
        if hour > 12:
            h_12 -= 12
        if token_count == 1:
            return String(h_12)
        if token_count == 2:
            return String(h_12).ascii_rjust(2, "0")
    elif token == _m:
        if token_count == 1:
            return String(minute)
        if token_count == 2:
            return String(minute).ascii_rjust(2, "0")
    elif token == _s:
        if token_count == 1:
            return String(second)
        if token_count == 2:
            return String(second).ascii_rjust(2, "0")
    elif token == _S:
        if token_count == 1:
            return String(microsecond // 100000)
        if token_count == 2:
            return String(microsecond // 10000).ascii_rjust(2, "0")
        if token_count == 3:
            return String(microsecond // 1000).ascii_rjust(3, "0")
        if token_count == 4:
            return String(microsecond // 100).ascii_rjust(4, "0")
        if token_count == 5:
            return String(microsecond // 10).ascii_rjust(5, "0")
        if token_count == 6:
            return String(microsecond).ascii_rjust(6, "0")
    elif token == _d:
        if token_count == 1:
            return String(weekday)
        if token_count == 3:
            return day_abbreviation(weekday)
        if token_count == 4:
            return day_name(weekday)
    elif token == _Z:
        if token_count == 3:
            return "UTC" if tz_is_none else tz_name
        var separator = "" if token_count == 1 else ":"
        if tz_is_none:
            return _format_timezone(0, separator)
        else:
            return _format_timezone(tz_offset, separator)

    elif token == _W:
        return _format_iso_week(year, month, day, weekday)
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
            * _US_PER_SECOND
            + microsecond
        )
    elif token == _a:
        return "am" if hour < 12 else "pm"
    elif token == _A:
        return "AM" if hour < 12 else "PM"
    return ""


def _format_timezone(offset: Int, sep: String = ":") -> String:
    var sign: String
    var offset_abs: Int
    if offset < 0:
        sign = "-"
        offset_abs = -offset
    else:
        sign = "+"
        offset_abs = offset
    var hh = offset_abs // 3600
    var mm = (offset_abs % 3600) // 60
    return (
        sign
        + String(hh).ascii_rjust(2, "0")
        + sep
        + String(mm).ascii_rjust(2, "0")
    )


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
    var yday_zero_based = day_of_year - 1
    return String((yday_zero_based + 7 - weekday_zero_based) // 7).ascii_rjust(
        2, "0"
    )


def _day_of_year(year: Int, month: Int, day: Int) raises -> Int:
    return _ymd2ord(year, month, day) - _ymd2ord(year, 1, 1) + 1


def _timestamp_seconds(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    tz_offset: Int,
) raises -> Int:
    return (
        (_ymd2ord(year, month, day) - _UNIX_EPOCH_ORDINAL) * 86400
        + hour * 3600
        + minute * 60
        + second
        - tz_offset
    )


def _format_timestamp_seconds(seconds: Int, microsecond: Int) -> String:
    var fraction = String(microsecond).ascii_rjust(6, "0")
    var end = fraction.byte_length()
    while end > 1 and fraction[byte=end - 1] == "0":
        end -= 1
    return String(seconds) + "." + String(fraction[byte=0:end])


def _format_iso_week(
    year: Int, month: Int, day: Int, weekday: Int
) raises -> String:
    var ordinal = _ymd2ord(year, month, day)
    var iso_year = year
    var week1 = _iso_week1_monday(iso_year)
    if ordinal < week1:
        iso_year -= 1
        week1 = _iso_week1_monday(iso_year)
    else:
        var next_week1 = _iso_week1_monday(iso_year + 1)
        if ordinal >= next_week1:
            iso_year += 1
            week1 = next_week1
    var week = (ordinal - week1) // 7 + 1
    return (
        String(iso_year).ascii_rjust(4, "0")
        + "-W"
        + String(week).ascii_rjust(2, "0")
        + "-"
        + String(weekday)
    )


def _iso_week1_monday(year: Int) raises -> Int:
    var fourth_jan = _ymd2ord(year, 1, 4)
    var weekday = fourth_jan % 7 or 7
    return fourth_jan - weekday + 1


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
