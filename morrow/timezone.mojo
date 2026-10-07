"""Fixed UTC offsets and IANA zones resolved from tzdata or ICU."""

from std.format import Writable, Writer
from std.collections import Optional
from std.memory import ArcPointer

from ._text import is_digit, equals_ascii_ignore_case, pad
from ._calendar import epoch_seconds
from ._libc import c_gettimeofday
from ._icu import Calendar
from ._tzif import ZoneData, load_zone


struct TimeZone(Copyable, ImplicitlyCopyable, Movable, Writable):
    var offset: Int
    var name: String
    var zone: String
    var dst_seconds: Int
    var fold_value: Int
    var is_ambiguous: Bool
    var is_imaginary: Bool
    var _data: Optional[ArcPointer[ZoneData]]
    """Parsed tzdata shared by copies; None for fixed offsets or ICU zones."""

    def __init__(out self, offset: Int, name: String = ""):
        self.offset = offset
        self.name = name
        self.zone = ""
        self.dst_seconds = 0
        self.fold_value = 0
        self.is_ambiguous = False
        self.is_imaginary = False
        self._data = None

    def __init__(out self, *, copy: Self):
        self.offset = copy.offset
        self.name = copy.name
        self.zone = copy.zone
        self.dst_seconds = copy.dst_seconds
        self.fold_value = copy.fold_value
        self.is_ambiguous = copy.is_ambiguous
        self.is_imaginary = copy.is_imaginary
        self._data = copy._data

    def __init__(out self, *, deinit move: Self):
        self.offset = move.offset
        self.name = move.name^
        self.zone = move.zone^
        self.dst_seconds = move.dst_seconds
        self.fold_value = move.fold_value
        self.is_ambiguous = move.is_ambiguous
        self.is_imaginary = move.is_imaginary
        self._data = move._data^

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
        """Create an IANA timezone from the system tzdata, or ICU without it."""
        if name == "":
            raise Error("timezone name is empty")
        return TimeZone._named(name, name).at(c_gettimeofday().tv_sec)

    @staticmethod
    def _named(zone: String, name: String) -> TimeZone:
        var result = TimeZone(0, name)
        result.zone = zone
        result._data = load_zone(zone)
        return result^

    @staticmethod
    def local() raises -> TimeZone:
        return TimeZone.from_name("local")

    @staticmethod
    def local(timestamp: Int) raises -> TimeZone:
        return TimeZone._named("local", "local").at(timestamp)

    @staticmethod
    def local_at(
        year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int
    ) raises -> TimeZone:
        return TimeZone._named("local", "local").resolve(
            year, month, day, hour, minute, second
        )

    def at(self, timestamp: Int) raises -> TimeZone:
        if self.zone == "":
            return self
        if self._data:
            var zone_info = self._data.value()[].info_at(timestamp)
            var result = self
            result.offset = zone_info.offset
            result.dst_seconds = zone_info.dst
            result.is_imaginary = False
            return result
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
        if result._data:
            var wall = epoch_seconds(year, month, day, hour, minute, second)
            var info = result._data.value()[].resolve_wall(
                wall, result.fold_value
            )
            result.offset = info.offset
            result.dst_seconds = info.dst
            result.is_ambiguous = info.ambiguous
            result.is_imaginary = info.imaginary
            return result
        return result._resolve_with(
            Calendar(result.zone), year, month, day, hour, minute, second
        )

    def _resolve_with(
        self,
        calendar: Calendar,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
    ) raises -> TimeZone:
        """Resolve wall fields with an already open calendar for this zone."""
        var result = self
        var wall = epoch_seconds(year, month, day, hour, minute, second)
        var info = calendar.wall(
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
        if equals_ascii_ignore_case(utc_str, "UTC") or utc_str == "Z":
            return TimeZone(0, "utc")
        if equals_ascii_ignore_case(utc_str, "GMT"):
            return TimeZone(0, "GMT")
        for byte in utc_str.as_bytes():
            if byte > 127:
                raise Error("utc_str must contain ASCII offset text")
        var p = (
            3 if utc_str.byte_length() > 3 and utc_str[byte=0:3] == "UTC" else 0
        )

        var sign = -1 if utc_str[byte=p] == "-" else 1
        if utc_str[byte=p] == "+" or utc_str[byte=p] == "-":
            p += 1

        if (
            utc_str.byte_length() < p + 2
            or not is_digit(Int(utc_str.as_bytes()[p]))
            or not is_digit(Int(utc_str.as_bytes()[p + 1]))
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
            and is_digit(Int(utc_str.as_bytes()[p]))
            and is_digit(Int(utc_str.as_bytes()[p + 1]))
            and is_digit(Int(utc_str.as_bytes()[p + 2]))
            and is_digit(Int(utc_str.as_bytes()[p + 3]))
        ):
            minutes = Int(utc_str[byte = p : p + 2])
            seconds = Int(utc_str[byte = p + 2 : p + 4])
        elif utc_str.byte_length() == p + 2 and is_digit(
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
        return format_offset(self.offset, sep)


def format_offset(
    offset: Int, sep: String = ":", include_seconds: Bool = True
) -> String:
    """A UTC offset as "+HH:MM", with ":SS" when seconds are nonzero."""
    var magnitude = abs(offset)
    var result = (
        ("-" if offset < 0 else "+")
        + pad(magnitude // 3600, 2)
        + sep
        + pad((magnitude % 3600) // 60, 2)
    )
    if include_seconds and magnitude % 60 != 0:
        result += sep + pad(magnitude % 60, 2)
    return result
