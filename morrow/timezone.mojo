from std.format import Writable, Writer

from ._libc import c_localtime


struct TimeZone(Copyable, ImplicitlyCopyable, Movable, Writable):
    var offset: Int
    var name: String

    fn __init__(out self, offset: Int, name: String = ""):
        self.offset = offset
        self.name = name

    fn __copyinit__(out self, copy: Self):
        self.offset = copy.offset
        self.name = copy.name

    fn __moveinit__(out self, deinit take: Self):
        self.offset = take.offset
        self.name = take.name^

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.name)

    fn is_none(self) -> Bool:
        """
        Check if this TimeZone is None.
        """
        return self.name == "None"

    @staticmethod
    fn none() -> TimeZone:
        """
        Create a None TimeZone.
        """
        return TimeZone(0, "None")

    @staticmethod
    fn local() -> TimeZone:
        """
        Get the local TimeZone.
        """
        var local_t = c_localtime(0)
        return TimeZone(Int(local_t.tm_gmtoff), "local")

    @staticmethod
    fn from_utc(utc_str: String) raises -> TimeZone:
        """
        Create a TimeZone from a UTC string.
        """
        if len(utc_str) == 0:
            raise Error("utc_str is empty")
        if utc_str == "utc" or utc_str == "UTC" or utc_str == "Z":
            return TimeZone(0, "utc")
        var p = 3 if len(utc_str) > 3 and utc_str[byte=0:3] == "UTC" else 0

        var sign = -1 if utc_str[byte=p] == "-" else 1
        if utc_str[byte=p] == "+" or utc_str[byte=p] == "-":
            p += 1

        if (
            len(utc_str) < p + 2
            or not _is_ascii_digit(ord(utc_str[byte=p]))
            or not _is_ascii_digit(ord(utc_str[byte=p + 1]))
        ):
            raise Error("utc_str format is invalid")
        var hours: Int = Int(utc_str[byte = p : p + 2])
        p += 2

        var minutes: Int
        if len(utc_str) <= p:
            minutes = 0
        elif len(utc_str) == p + 3 and utc_str[byte=p] == ":":
            minutes = Int(utc_str[byte = p + 1 : p + 3])
        elif len(utc_str) == p + 2 and _is_ascii_digit(ord(utc_str[byte=p])):
            minutes = Int(utc_str[byte = p : p + 2])
        else:
            raise Error("utc_str format is invalid")
        var offset: Int = sign * (hours * 3600 + minutes * 60)
        return TimeZone(offset)

    fn format(self, sep: String = ":") -> String:
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
        return (
            sign
            + String(hh).ascii_rjust(2, "0")
            + sep
            + String(mm).ascii_rjust(2, "0")
        )


fn _is_ascii_digit(c: Int) -> Bool:
    return c >= ord("0") and c <= ord("9")
