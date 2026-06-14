from std.format import Writable, Writer

from ._libc import c_localtime


struct TimeZone(Copyable, ImplicitlyCopyable, Movable, Writable):
    var offset: Int
    var name: String

    def __init__(out self, offset: Int, name: String = ""):
        self.offset = offset
        self.name = name

    def __init__(out self, *, copy: Self):
        self.offset = copy.offset
        self.name = copy.name

    def __init__(out self, *, deinit take: Self):
        self.offset = take.offset
        self.name = take.name^

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.name)

    def is_none(self) -> Bool:
        """
        Check if this TimeZone is None.
        """
        return self.name == "None"

    @staticmethod
    def none() -> TimeZone:
        """
        Create a None TimeZone.
        """
        return TimeZone(0, "None")

    @staticmethod
    def local() -> TimeZone:
        """
        Get the local TimeZone.
        """
        var local_t = c_localtime(0)
        return TimeZone(Int(local_t.tm_gmtoff), "local")

    @staticmethod
    def from_utc(utc_str: String) raises -> TimeZone:
        """
        Create a TimeZone from a UTC string.
        """
        if utc_str.byte_length() == 0:
            raise Error("utc_str is empty")
        if _equals_ascii_case_insensitive(utc_str, "UTC") or utc_str == "Z":
            return TimeZone(0, "utc")
        if _equals_ascii_case_insensitive(utc_str, "GMT"):
            return TimeZone(0, "GMT")
        var p = (
            3 if utc_str.byte_length() > 3 and utc_str[byte=0:3] == "UTC" else 0
        )

        var sign = -1 if utc_str[byte=p] == "-" else 1
        if utc_str[byte=p] == "+" or utc_str[byte=p] == "-":
            p += 1

        if (
            utc_str.byte_length() < p + 2
            or not _is_ascii_digit(ord(utc_str[byte=p]))
            or not _is_ascii_digit(ord(utc_str[byte=p + 1]))
        ):
            raise Error("utc_str format is invalid")
        var hours: Int = Int(utc_str[byte = p : p + 2])
        p += 2

        var minutes = 0
        var seconds = 0
        if utc_str.byte_length() <= p:
            pass
        elif (
            utc_str.byte_length() == p + 6
            and utc_str[byte=p] == ":"
            and utc_str[byte=p + 3] == ":"
        ):
            minutes = Int(utc_str[byte = p + 1 : p + 3])
            seconds = Int(utc_str[byte = p + 4 : p + 6])
        elif utc_str.byte_length() == p + 3 and utc_str[byte=p] == ":":
            minutes = Int(utc_str[byte = p + 1 : p + 3])
        elif (
            utc_str.byte_length() == p + 4
            and _is_ascii_digit(ord(utc_str[byte=p]))
            and _is_ascii_digit(ord(utc_str[byte=p + 1]))
            and _is_ascii_digit(ord(utc_str[byte=p + 2]))
            and _is_ascii_digit(ord(utc_str[byte=p + 3]))
        ):
            minutes = Int(utc_str[byte = p : p + 2])
            seconds = Int(utc_str[byte = p + 2 : p + 4])
        elif utc_str.byte_length() == p + 2 and _is_ascii_digit(
            ord(utc_str[byte=p])
        ):
            minutes = Int(utc_str[byte = p : p + 2])
        else:
            raise Error("utc_str format is invalid")
        if minutes > 59 or seconds > 59:
            raise Error("utc_str format is invalid")
        var offset: Int = sign * (hours * 3600 + minutes * 60 + seconds)
        if offset <= -86400 or offset >= 86400:
            raise Error("utc offset must be strictly between -24:00 and +24:00")
        return TimeZone(offset)

    def format(self, sep: String = ":") -> String:
        """
        Format the TimeZone as a string.
        """
        var sign: String
        var offset_abs: Int
        if self.offset < 0:
            sign = "-"
            offset_abs = -self.offset
        else:
            sign = "+"
            offset_abs = self.offset
        var hh = offset_abs // 3600
        var mm = (offset_abs % 3600) // 60
        var result = (
            sign
            + String(hh).ascii_rjust(2, "0")
            + sep
            + String(mm).ascii_rjust(2, "0")
        )
        var ss = offset_abs % 60
        if ss != 0:
            result += sep + String(ss).ascii_rjust(2, "0")
        return result


def _is_ascii_digit(c: Int) -> Bool:
    return c >= ord("0") and c <= ord("9")


def _equals_ascii_case_insensitive(left: String, right: String) -> Bool:
    if left.byte_length() != right.byte_length():
        return False
    for i in range(left.byte_length()):
        if _ascii_lower(ord(left[byte=i])) != _ascii_lower(ord(right[byte=i])):
            return False
    return True


def _ascii_lower(c: Int) -> Int:
    if c >= ord("A") and c <= ord("Z"):
        return c + 32
    return c
