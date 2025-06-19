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



@fieldwise_init
struct Token:
    """Token for the formatter."""
    var char: Byte
    """The character of the token."""
    
    alias _Y = Byte(ord("Y"))
    alias _M = Byte(ord("M"))
    alias _D = Byte(ord("D"))
    alias _d = Byte(ord("d"))
    alias _H = Byte(ord("H"))
    alias _h = Byte(ord("h"))
    alias _m = Byte(ord("m"))
    alias _s = Byte(ord("s"))
    alias _S = Byte(ord("S"))
    alias _X = Byte(ord("X"))
    alias _x = Byte(ord("x"))
    alias _Z = Byte(ord("Z"))
    alias _A = Byte(ord("A"))
    alias _a = Byte(ord("a"))

    fn __eq__(self, other: Self) -> Bool:
        """Checks if two tokens are equal.
        
        Args:
            other: The other token to compare with.
        
        Returns:
            True if the tokens are equal, False otherwise.
        """
        return self.char == other.char
    
    fn __eq__(self, other: Byte) -> Bool:
        """Checks if two tokens are equal.
        
        Args:
            other: The other token to compare with.
        
        Returns:
            True if the tokens are equal, False otherwise.
        """
        return self.char == other


fn find_brackets[template: StringSlice]() -> List[List[Int]]:
    """Finds the start index of the first bracket in the template."""
    var in_bracket = False
    var brackets: List[List[Int]] = []

    @parameter
    for i in range(len(template)):
        if template[i] == "[" and not in_bracket:
            brackets.append([i, -1])
            in_bracket = True
        elif template[i] == "]" and in_bracket:
            brackets[-1][1] = i
            in_bracket = False

    return brackets^


struct _Formatter:
    """SmallTime formatter."""
    var sub_characters: InlineArray[Int, 128]
    """Substitution characters."""

    fn __init__(out self):
        """Initializes a new formatter."""
        self.sub_characters = InlineArray[Int, 128](fill=0)
        self.sub_characters[Token._Y] = 4
        self.sub_characters[Token._M] = 4
        self.sub_characters[Token._D] = 2
        self.sub_characters[Token._d] = 4
        self.sub_characters[Token._H] = 2
        self.sub_characters[Token._h] = 2
        self.sub_characters[Token._m] = 2
        self.sub_characters[Token._s] = 2
        self.sub_characters[Token._S] = 6
        self.sub_characters[Token._Z] = 3
        self.sub_characters[Token._A] = 1
        self.sub_characters[Token._a] = 1

    # TODO (Mikhail): Add support for "Do" for day of the month with ordinal suffix (1st, 2nd, 3rd, etc.)
    fn format[template: StringSlice](self, time: SmallTime) -> String:
        """Formats the given time value using the specified format string.
        `"YYYY[abc]MM" -> replace("YYYY") + "abc" + replace("MM")`

        Parameters:
            template: Format string template to use for formatting the time.

        Args:
            time: SmallTime datetime to format.
        
        Returns:
            Formatted time string.
        """
        @parameter
        if len(template) == 0:
            return String()
        
        alias brackets = find_brackets[template]()
        @parameter
        if len(brackets) == 0:
            # No brackets found, just replace the template.
            return self.replace[template](time)
        elif len(brackets) == 1:
            return String(
                self.replace[template[:brackets[0][0]]](time),
                template[brackets[0][0]+1:brackets[0][1]],
                self.replace[template[brackets[0][1]+1:]](time)
            )
        
        var result = String(self.replace[template[:brackets[0][0]]](time), template[brackets[0][0]+1:brackets[0][1]])
        @parameter
        for i in range(1, len(brackets)):
            alias start = brackets[i][0]
            alias end = brackets[i][1]
            result.write(
                self.replace[template[brackets[i-1][1]+1:start]](time),
                template[start+1:end]
            )
        
            @parameter
            if i == len(brackets) - 1:
                # Replace the last part of the template after the last bracket.
                result.write(self.replace[template[end+1:]](time))   
        return result^

    fn replace[template: StringSlice](self, time: SmallTime) -> String:
        """Replaces the tokens in the given format string with the corresponding values.

        Parameters:
            template: Format string to replace tokens in.

        Args:
            time: SmallTime datetime to replace tokens in.
        
        Returns:
            Formatted time string.
        """
        @parameter
        if len(template) == 0:
            return String()

        var matched_byte = 0
        var matched_count = 0

        var result = String()
        @parameter
        for i in range(len(template)):
            var byte = ord(template[i])
            # If the current character is not a token, add it to the result.
            if byte > 127 or self.sub_characters[byte] == 0:
                if matched_byte > 0:
                    # If we have a matched token, replace it with the corresponding value.
                    result.write(self.replace_token(time, matched_byte, matched_count))
                    matched_byte = 0
                result.write(template[i])
                continue

            # If the current character is the same as the previous one, increment the count.
            if byte == matched_byte:
                matched_count += 1
                continue

            # If the current character is different from the previous one, replace the previous tokens
            # and move onto the next token to track.
            result.write(self.replace_token(time, matched_byte, matched_count))
            matched_byte = byte
            matched_count = 1

        # If no tokens were found, append an empty string and return the original.
        if matched_byte > 0:
            result.write(self.replace_token(time, matched_byte, matched_count))
        return result

    fn replace_token(self, time: SmallTime, token: Byte, token_count: Int) -> String:
        """Replaces the given token with the corresponding value from the SmallTime object.

        Args:
            time: SmallTime datetime to replace tokens in.
            token: The token to replace.
            token_count: The number of times the token appears in the format string.
        
        Returns:
            The string representation of the token value.
        """
        if token == Token._Y:
            if token_count == 1:
                return "Y"
            if token_count == 2:
                return String(time.year).rjust(4, "0")[2:4]
            if token_count == 4:
                return String(time.year).rjust(4, "0")
        elif token == Token._M:
            if token_count == 1:
                return String(time.month)
            if token_count == 2:
                return String(time.month).rjust(2, "0")
            if token_count == 3:
                return MONTH_ABBREVIATIONS[time.month]
            if token_count == 4:
                return MONTH_NAMES[time.month]
        elif token == Token._D:
            if token_count == 1:
                return String(time.day)
            if token_count == 2:
                return String(time.day).rjust(2, "0")
        elif token == Token._H:
            if token_count == 1:
                return String(time.hour)
            if token_count == 2:
                return String(time.hour).rjust(2, "0")
        elif token == Token._h:
            var h_12 = time.hour
            if time.hour > 12:
                h_12 -= 12
            if token_count == 1:
                return String(h_12)
            if token_count == 2:
                return String(h_12).rjust(2, "0")
        elif token == Token._m:
            if token_count == 1:
                return String(time.minute)
            if token_count == 2:
                return String(time.minute).rjust(2, "0")
        elif token == Token._s:
            if token_count == 1:
                return String(time.second)
            if token_count == 2:
                return String(time.second).rjust(2, "0")
        elif token == Token._S:
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
        elif token == Token._d:
            if token_count == 1:
                return String(time.iso_weekday())
            if token_count == 3:
                return DAY_ABBREVIATIONS[time.iso_weekday()]
            if token_count == 4:
                return DAY_NAMES[time.iso_weekday()]
        elif token == Token._Z:
            if token_count == 3:
                return time.time_zone.name
            var separator = "" if token_count == 1 else ":"
            return time.time_zone.format(separator)

        elif token == Token._a:
            return "am" if time.hour < 12 else "pm"
        elif token == Token._A:
            return "AM" if time.hour < 12 else "PM"
        return ""
