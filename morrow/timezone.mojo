from std.format import Writable, Writer

from ._libc import c_gettimeofday
from ._icu import Calendar
from .util import _ymd2ord


struct TimeZone(Copyable, ImplicitlyCopyable, Movable, Writable):
    var offset: Int
    var name: String
    var zone: String
    var dst_seconds: Int
    var fold_value: Int
    var is_ambiguous: Bool
    var is_imaginary: Bool

    def __init__(out self, offset: Int, name: String = ""):
        self.offset = offset
        self.name = name
        self.zone = ""
        self.dst_seconds = 0
        self.fold_value = 0
        self.is_ambiguous = False
        self.is_imaginary = False

    def __init__(out self, *, copy: Self):
        self.offset = copy.offset
        self.name = copy.name
        self.zone = copy.zone
        self.dst_seconds = copy.dst_seconds
        self.fold_value = copy.fold_value
        self.is_ambiguous = copy.is_ambiguous
        self.is_imaginary = copy.is_imaginary

    def __init__(out self, *, deinit move: Self):
        self.offset = move.offset
        self.name = move.name^
        self.zone = move.zone^
        self.dst_seconds = move.dst_seconds
        self.fold_value = move.fold_value
        self.is_ambiguous = move.is_ambiguous
        self.is_imaginary = move.is_imaginary

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        if self.name != "":
            return self.name
        return self.format()

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
    def from_name(name: String) raises -> TimeZone:
        """Create an IANA timezone using the installed ICU timezone rules."""
        if name == "":
            raise Error("timezone name is empty")
        var result = TimeZone(0, name)
        result.zone = name
        return result.at(c_gettimeofday().tv_sec)

    @staticmethod
    def local() raises -> TimeZone:
        return TimeZone.from_name("local")

    @staticmethod
    def local(timestamp: Int) raises -> TimeZone:
        var result = TimeZone(0, "local")
        result.zone = "local"
        return result.at(timestamp)

    @staticmethod
    def local_at(
        year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int
    ) raises -> TimeZone:
        var result = TimeZone(0, "local")
        result.zone = "local"
        return result.resolve(year, month, day, hour, minute, second)

    def at(self, timestamp: Int) raises -> TimeZone:
        if self.zone == "":
            return self
        var info = Calendar(self.zone).at(timestamp)
        var result = self
        result.offset = info.offset
        result.dst_seconds = info.dst
        result.is_imaginary = False
        return result

    def resolve(
        self,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        fold: Int = -1,
    ) raises -> TimeZone:
        if fold < -1 or fold > 1:
            raise Error("fold must be 0 or 1")
        var result = self
        if fold != -1:
            result.fold_value = fold
        if result.zone == "":
            return result
        var wall = (
            (_ymd2ord(year, month, day) - 719163) * 86400
            + hour * 3600
            + minute * 60
            + second
        )
        var info = Calendar(result.zone).wall(
            year, month, day, hour, minute, second, wall, result.fold_value
        )
        result.offset = info.offset
        result.dst_seconds = info.dst
        result.is_ambiguous = info.ambiguous
        result.is_imaginary = info.imaginary
        return result

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
            or not _is_ascii_digit(Int(utc_str.as_bytes()[p]))
            or not _is_ascii_digit(Int(utc_str.as_bytes()[p + 1]))
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
            and _is_ascii_digit(Int(utc_str.as_bytes()[p]))
            and _is_ascii_digit(Int(utc_str.as_bytes()[p + 1]))
            and _is_ascii_digit(Int(utc_str.as_bytes()[p + 2]))
            and _is_ascii_digit(Int(utc_str.as_bytes()[p + 3]))
        ):
            minutes = Int(utc_str[byte = p : p + 2])
            seconds = Int(utc_str[byte = p + 2 : p + 4])
        elif utc_str.byte_length() == p + 2 and _is_ascii_digit(
            Int(utc_str.as_bytes()[p])
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
        if _ascii_lower(Int(left.as_bytes()[i])) != _ascii_lower(
            Int(right.as_bytes()[i])
        ):
            return False
    return True


def _ascii_lower(c: Int) -> Int:
    if c >= ord("A") and c <= ord("Z"):
        return c + 32
    return c
