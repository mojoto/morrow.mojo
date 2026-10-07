"""Byte-level text helpers shared by parsing, formatting and locale code.

Character arguments are byte values (`Int(s.as_bytes()[i])`); positions are
byte offsets.
"""


def utf8_width(s: String, pos: Int) -> Int:
    """Byte width of a codepoint at a known UTF-8 boundary."""
    var first = Int(s.as_bytes()[pos])
    if first < 128:
        return 1
    if first < 224:
        return 2
    if first < 240:
        return 3
    return 4


def is_digit(c: Int) -> Bool:
    return c >= ord("0") and c <= ord("9")


def is_alpha(c: Int) -> Bool:
    return (c >= ord("A") and c <= ord("Z")) or (
        c >= ord("a") and c <= ord("z")
    )


def is_alnum(c: Int) -> Bool:
    return is_digit(c) or is_alpha(c)


def is_space(c: Int) -> Bool:
    """ASCII whitespace: space, tab, newline, vertical tab, form feed, CR."""
    return c == ord(" ") or (c >= 9 and c <= 13)


def ascii_lower(c: Int) -> Int:
    if c >= ord("A") and c <= ord("Z"):
        return c + 32
    return c


def starts_at(value: String, position: Int, token: String) -> Bool:
    """Whether token occurs in value at byte position."""
    if position < 0 or position + token.byte_length() > value.byte_length():
        return False
    for i in range(token.byte_length()):
        if value.as_bytes()[position + i] != token.as_bytes()[i]:
            return False
    return True


def starts_at_ascii_ignore_case(
    value: String, position: Int, token: String
) -> Bool:
    """Like `starts_at`, comparing ASCII letters case-insensitively."""
    if position < 0 or position + token.byte_length() > value.byte_length():
        return False
    for i in range(token.byte_length()):
        if ascii_lower(Int(value.as_bytes()[position + i])) != ascii_lower(
            Int(token.as_bytes()[i])
        ):
            return False
    return True


def equals_ascii_ignore_case(left: String, right: String) -> Bool:
    return left.byte_length() == right.byte_length() and (
        starts_at_ascii_ignore_case(left, 0, right)
    )


def find_byte(value: String, byte: Int, start: Int, end: Int) -> Int:
    """First index of byte in value[start:end], or end when absent."""
    for i in range(start, end):
        if Int(value.as_bytes()[i]) == byte:
            return i
    return end


def pad(value: Int, width: Int, fill: StaticString = "0") -> String:
    """`value` right-aligned to width, like `str(value).rjust(width, fill)`."""
    return String(value).ascii_rjust(width, fill)
