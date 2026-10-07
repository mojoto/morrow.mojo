"""Plain value views returned by Morrow: dates, times, spans and tuples."""

from std.format import Writable, Writer

from ._text import pad
from .morrow import Morrow
from .timezone import TimeZone


struct MorrowSpan(Copyable, ImplicitlyCopyable, Movable, Writable):
    var start: Morrow
    var end: Morrow

    def __init__(out self, start: Morrow, end: Morrow):
        self.start = start
        self.end = end

    def __init__(out self, *, copy: Self):
        self.start = copy.start
        self.end = copy.end

    def __init__(out self, *, deinit move: Self):
        self.start = move.start^
        self.end = move.end^

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            "MorrowSpan(start="
            + self.start._isoformat_auto()
            + ", end="
            + self.end._isoformat_auto()
            + ")"
        )


struct MorrowIsoCalendar(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var week: Int
    var weekday: Int

    def __init__(out self, year: Int, week: Int, weekday: Int):
        self.year = year
        self.week = week
        self.weekday = weekday

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            "MorrowIsoCalendar(year="
            + String(self.year)
            + ", week="
            + String(self.week)
            + ", weekday="
            + String(self.weekday)
            + ")"
        )


struct MorrowDate(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var month: Int
    var day: Int

    def __init__(out self, year: Int, month: Int, day: Int):
        self.year = year
        self.month = month
        self.day = day

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            pad(self.year, 4)
            + "-"
            + pad(self.month, 2)
            + "-"
            + pad(self.day, 2)
        )


struct MorrowTime(Copyable, ImplicitlyCopyable, Movable, Writable):
    var hour: Int
    var minute: Int
    var second: Int
    var microsecond: Int
    var tz: TimeZone

    def __init__(
        out self,
        hour: Int,
        minute: Int,
        second: Int,
        microsecond: Int,
        tz: TimeZone = TimeZone.none(),
    ):
        self.hour = hour
        self.minute = minute
        self.second = second
        self.microsecond = microsecond
        self.tz = tz

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        var result = (
            pad(self.hour, 2)
            + ":"
            + pad(self.minute, 2)
            + ":"
            + pad(self.second, 2)
            + "."
            + pad(self.microsecond, 6)
        )
        if not self.tz.is_none():
            result += self.tz.format()
        return result


struct MorrowTimeTuple(Copyable, ImplicitlyCopyable, Movable, Writable):
    var year: Int
    var mon: Int
    var mday: Int
    var hour: Int
    var min: Int
    var sec: Int
    var wday: Int
    var yday: Int
    var isdst: Int

    def __init__(
        out self,
        year: Int,
        mon: Int,
        mday: Int,
        hour: Int,
        min: Int,
        sec: Int,
        wday: Int,
        yday: Int,
        isdst: Int,
    ):
        self.year = year
        self.mon = mon
        self.mday = mday
        self.hour = hour
        self.min = min
        self.sec = sec
        self.wday = wday
        self.yday = yday
        self.isdst = isdst

    def __str__(self) -> String:
        return self.to_string()

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.to_string())

    def to_string(self) -> String:
        return (
            "MorrowTimeTuple(year="
            + String(self.year)
            + ", mon="
            + String(self.mon)
            + ", mday="
            + String(self.mday)
            + ", hour="
            + String(self.hour)
            + ", min="
            + String(self.min)
            + ", sec="
            + String(self.sec)
            + ", wday="
            + String(self.wday)
            + ", yday="
            + String(self.yday)
            + ", isdst="
            + String(self.isdst)
            + ")"
        )
