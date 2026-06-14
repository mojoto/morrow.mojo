from .constants import (
    month_name,
    month_abbreviation,
    day_name,
    day_abbreviation,
)


fn format_morrow(
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
    if len(fmt) == 0:
        return ""
    var ret: String = ""
    var in_bracket = False
    var start_idx = 0
    for i in range(len(fmt)):
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
    if start_idx < len(fmt):
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


fn _replace(
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
    if len(s) == 0:
        return ""
    var ret: String = ""
    var match_chr_ord = 0
    var match_count = 0
    for i in range(len(s)):
        var c = ord(s[byte=i])
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


fn _replace_token(
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
        if token_count == 1:
            return String(day)
        if token_count == 2:
            return String(day).ascii_rjust(2, "0")
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

    elif token == _a:
        return "am" if hour < 12 else "pm"
    elif token == _A:
        return "AM" if hour < 12 else "PM"
    return ""


fn _format_timezone(offset: Int, sep: String = ":") -> String:
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


fn _sub_chr_max(c: Int) -> Int:
    if c == _Y:
        return 4
    if c == _M:
        return 4
    if c == _D:
        return 2
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
comptime _H = ord("H")  # Hour (24-hour)
comptime _h = ord("h")  # Hour (12-hour)
comptime _m = ord("m")  # Minute
comptime _s = ord("s")  # Second
comptime _S = ord("S")  # Microsecond
comptime _Z = ord("Z")  # Timezone
comptime _A = ord("A")  # AM/PM
comptime _a = ord("a")  # am/pm
