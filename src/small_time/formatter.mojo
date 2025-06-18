alias MONTH_NAMES: InlineArray[String, 13] = [
    "",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
]
"""The full month names."""

alias MONTH_ABBREVIATIONS: InlineArray[String, 13] = [
    "",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
]
"""The month name abbreviations."""

alias DAY_NAMES: InlineArray[String, 8] = [
    "",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
]
"""The full day names."""
alias DAY_ABBREVIATIONS: InlineArray[String, 8] = [
    "",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
]
"""The day name abbreviations."""
alias FORMATTER = _Formatter()
"""Default formatter instance."""


struct _Formatter:
    """SmallTime formatter."""
    var _sub_chrs: InlineArray[Int, 128]
    """Substitution characters."""

    fn __init__(out self):
        """Initializes a new formatter."""
        self._sub_chrs = InlineArray[Int, 128](fill=0)
        self._sub_chrs[_Y] = 4
        self._sub_chrs[_M] = 4
        self._sub_chrs[_D] = 2
        self._sub_chrs[_d] = 4
        self._sub_chrs[_H] = 2
        self._sub_chrs[_h] = 2
        self._sub_chrs[_m] = 2
        self._sub_chrs[_s] = 2
        self._sub_chrs[_S] = 6
        self._sub_chrs[_Z] = 3
        self._sub_chrs[_A] = 1
        self._sub_chrs[_a] = 1

    fn format(self, time: SmallTime, fmt: StringSlice) -> String:
        """Formats the given time value using the specified format string.
        "YYYY[abc]MM" -> replace("YYYY") + "abc" + replace("MM")

        Args:
            time: SmallTime datetime to format.
            fmt: Format string.
        
        Returns:
            Formatted time string.
        """
        if len(fmt) == 0:
            return ""

        var result = String()
        var in_bracket = False
        var start = 0

        for i in range(len(fmt)):
            if fmt[i] == "[":
                if in_bracket:
                    result.write("[")
                else:
                    in_bracket = True

                result.write(self.replace(time, fmt[start:i]))
                start = i + 1
            elif fmt[i] == "]":
                if in_bracket:
                    result.write(fmt[start:i])
                    in_bracket = False
                else:
                    result.write(fmt[start:i], "]")
                start = i + 1

        if in_bracket:
            result.write("[")

        if start < len(fmt):
            result.write(self.replace(time, fmt[start:]))
        return result

    fn replace(self, time: SmallTime, fmt: StringSlice) -> String:
        """Replaces the tokens in the given format string with the corresponding values.

        Args:
            time: SmallTime datetime to replace tokens in.
            fmt: Format string.
        
        Returns:
            Formatted time string.
        """
        if len(fmt) == 0:
            return ""

        var result = String()
        var matched_byte = 0
        var matched_count = 0
        for i in range(len(fmt)):
            var c = ord(fmt[i])

            # If the current character is not a token, add it to the result.
            if c > 127 or self._sub_chrs[c] == 0:
                if matched_byte > 0:
                    result.write(self.replace_token(time, matched_byte, matched_count))
                    matched_byte = 0
                result.write(fmt[i])
                continue

            # If the current character is the same as the previous one, increment the count.
            if c == matched_byte:
                matched_count += 1
                continue

            # If the current character is different from the previous one, replace the previous tokens
            # and move onto the next token to track.
            result += self.replace_token(time, matched_byte, matched_count)
            matched_byte = c
            matched_count = 1

        # If no tokens were found, append an empty string and return the original.
        if matched_byte > 0:
            result += self.replace_token(time, matched_byte, matched_count)
        return result

    fn replace_token(self, time: SmallTime, token: Int, token_count: Int) -> String:
        if token == _Y:
            if token_count == 1:
                return "Y"
            if token_count == 2:
                return String(time.year).rjust(4, "0")[2:4]
            if token_count == 4:
                return String(time.year).rjust(4, "0")
        elif token == _M:
            if token_count == 1:
                return String(time.month)
            if token_count == 2:
                return String(time.month).rjust(2, "0")
            if token_count == 3:
                return MONTH_ABBREVIATIONS[time.month]
            if token_count == 4:
                return MONTH_NAMES[time.month]
        elif token == _D:
            if token_count == 1:
                return String(time.day)
            if token_count == 2:
                return String(time.day).rjust(2, "0")
        elif token == _H:
            if token_count == 1:
                return String(time.hour)
            if token_count == 2:
                return String(time.hour).rjust(2, "0")
        elif token == _h:
            var h_12 = time.hour
            if time.hour > 12:
                h_12 -= 12
            if token_count == 1:
                return String(h_12)
            if token_count == 2:
                return String(h_12).rjust(2, "0")
        elif token == _m:
            if token_count == 1:
                return String(time.minute)
            if token_count == 2:
                return String(time.minute).rjust(2, "0")
        elif token == _s:
            if token_count == 1:
                return String(time.second)
            if token_count == 2:
                return String(time.second).rjust(2, "0")
        elif token == _S:
            if token_count == 1:
                return String(time.microsecond // 100000)
            if token_count == 2:
                return String(time.microsecond // 10000).rjust(2, "0")
            if token_count == 3:
                return String(time.microsecond // 1000).rjust(3, "0")
            if token_count == 4:
                return String(time.microsecond // 100).rjust(4, "0")
            if token_count == 5:
                return String(time.microsecond // 10).rjust(5, "0")
            if token_count == 6:
                return String(time.microsecond).rjust(6, "0")
        elif token == _d:
            if token_count == 1:
                return String(time.iso_weekday())
            if token_count == 3:
                return DAY_ABBREVIATIONS[time.iso_weekday()]
            if token_count == 4:
                return DAY_NAMES[time.iso_weekday()]
        elif token == _Z:
            if token_count == 3:
                return time.time_zone.name
            var separator = "" if token_count == 1 else ":"
            return time.time_zone.format(separator)

        elif token == _a:
            return "am" if time.hour < 12 else "pm"
        elif token == _A:
            return "AM" if time.hour < 12 else "PM"
        return ""


alias _Y = ord("Y")
alias _M = ord("M")
alias _D = ord("D")
alias _d = ord("d")
alias _H = ord("H")
alias _h = ord("h")
alias _m = ord("m")
alias _s = ord("s")
alias _S = ord("S")
alias _X = ord("X")
alias _x = ord("x")
alias _Z = ord("Z")
alias _A = ord("A")
alias _a = ord("a")
