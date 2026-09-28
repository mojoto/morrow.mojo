"""Private TZif (RFC 8536) reader and zone rules from the system tzdata.

Named zones are parsed once into `ZoneData`, shared by every copy of a
`TimeZone`, so conversions need no file or ICU access. ICU remains the
fallback when no zone file exists.
"""
from std.collections import Optional
from std.ffi import _get_global, external_call
from std.memory import ArcPointer, Pointer
from std.memory.alloc import unsafe_alloc
from std.os import getenv
from std.os.path import exists

from .util import _days_in_month, _ymd2ord

comptime _EPOCH_ORDINAL = 719163
comptime _WINDOW = 93600  # 26 hours: wider than any UTC offset.


def _zone_path(zone: String) -> String:
    if zone == "local":
        var tz = getenv("TZ")
        if tz.byte_length() == 0:
            return "/etc/localtime" if exists("/etc/localtime") else ""
        var name = String(tz[byte=1:]) if tz.as_bytes()[0] == 58 else tz
        if name.byte_length() > 0 and name.as_bytes()[0] == 47:
            return name if exists(name) else ""
        return _zone_path(name)
    if (
        zone.byte_length() == 0
        or zone.find("..") >= 0
        or zone.as_bytes()[0] == 47
    ):
        return ""
    var roots = List[String]()
    var tzdir = getenv("TZDIR")
    if tzdir.byte_length() > 0:
        roots.append(tzdir)
    var prefix = getenv("CONDA_PREFIX")
    if prefix.byte_length() > 0:
        roots.append(prefix + "/share/zoneinfo")
    roots.append("/usr/share/zoneinfo")
    roots.append("/usr/lib/zoneinfo")
    roots.append("/usr/share/lib/zoneinfo")
    for root in roots:
        var path = root + "/" + zone
        if exists(path):
            return path
    return ""


def _read(path: String) -> List[UInt8]:
    try:
        with open(path, "r") as file:
            return file.read_bytes()
    except:
        return List[UInt8]()


def _u32(data: List[UInt8], pos: Int) -> Int:
    return (
        (Int(data[pos]) << 24)
        | (Int(data[pos + 1]) << 16)
        | (Int(data[pos + 2]) << 8)
        | Int(data[pos + 3])
    )


def _i32(data: List[UInt8], pos: Int) -> Int:
    var value = _u32(data, pos)
    return value - (1 << 32) if value >= (1 << 31) else value


def _i64(data: List[UInt8], pos: Int) -> Int:
    var value = 0
    for i in range(8):
        value = (value << 8) | Int(data[pos + i])
    return value


def _is_alpha(byte: Int) -> Bool:
    return (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122)


def _is_digit(byte: Int) -> Bool:
    return byte >= 48 and byte <= 57


struct _Cursor:
    """Parser position over a POSIX TZ string."""

    var text: String
    var pos: Int

    def __init__(out self, text: String):
        self.text = text
        self.pos = 0

    def peek(self) -> Int:
        if self.pos >= self.text.byte_length():
            return -1
        return Int(self.text.as_bytes()[self.pos])

    def number(mut self) raises -> Int:
        var start = self.pos
        var value = 0
        while _is_digit(self.peek()):
            value = value * 10 + self.peek() - 48
            self.pos += 1
        if self.pos == start:
            raise Error("invalid POSIX TZ number")
        return value

    def name(mut self) raises -> String:
        var start = self.pos
        if self.peek() == 60:
            while self.peek() != 62:
                if self.peek() < 0:
                    raise Error("invalid POSIX TZ name")
                self.pos += 1
            self.pos += 1
            return String(self.text[byte = start + 1 : self.pos - 1])
        while _is_alpha(self.peek()):
            self.pos += 1
        if self.pos - start < 3:
            raise Error("invalid POSIX TZ name")
        return String(self.text[byte = start : self.pos])

    def seconds(mut self) raises -> Int:
        """[+-]hh[:mm[:ss]] as signed seconds."""
        var sign = 1
        if self.peek() == 45:
            sign = -1
            self.pos += 1
        elif self.peek() == 43:
            self.pos += 1
        var total = self.number() * 3600
        if self.peek() == 58:
            self.pos += 1
            total += self.number() * 60
            if self.peek() == 58:
                self.pos += 1
                total += self.number()
        return sign * total


@fieldwise_init
struct _Rule(Copyable, ImplicitlyCopyable, Movable):
    """A POSIX transition date: kind 0 is Jn, 1 is n, 2 is Mm.w.d."""

    var kind: Int
    var month: Int
    var week: Int
    var day: Int
    var time: Int

    def local_seconds(self, year: Int) -> Int:
        """Local wall seconds since the epoch at which the rule fires."""
        var ordinal: Int
        if self.kind == 0:
            var day = self.day
            if day >= 60 and _days_in_month(year, 2) == 29:
                day += 1
            ordinal = _ymd2ord(year, 1, 1) + day - 1
        elif self.kind == 1:
            ordinal = _ymd2ord(year, 1, 1) + self.day
        else:
            var first = _ymd2ord(year, self.month, 1)
            var day = 1 + (self.day - first % 7 + 7) % 7 + (self.week - 1) * 7
            while day > _days_in_month(year, self.month):
                day -= 7
            ordinal = first + day - 1
        return (ordinal - _EPOCH_ORDINAL) * 86400 + self.time


def _parse_rule(mut cursor: _Cursor) raises -> _Rule:
    var rule: _Rule
    if cursor.peek() == 74:
        cursor.pos += 1
        rule = _Rule(0, 0, 0, cursor.number(), 7200)
    elif cursor.peek() == 77:
        cursor.pos += 1
        var month = cursor.number()
        cursor.pos += 1
        var week = cursor.number()
        cursor.pos += 1
        rule = _Rule(2, month, week, cursor.number(), 7200)
    else:
        rule = _Rule(1, 0, 0, cursor.number(), 7200)
    if cursor.peek() == 47:
        cursor.pos += 1
        rule.time = cursor.seconds()
    return rule


@fieldwise_init
struct ZoneInfo(Copyable, ImplicitlyCopyable, Movable):
    """Offset, DST amount and abbreviation in effect at an instant."""

    var offset: Int
    var dst: Int
    var abbreviation: Int
    """Type index, or -1/-2 for the footer's standard/daylight names."""


@fieldwise_init
struct WallInfo(Copyable, ImplicitlyCopyable, Movable):
    var offset: Int
    var dst: Int
    var ambiguous: Bool
    var imaginary: Bool


@fieldwise_init
struct _Transition(Copyable, ImplicitlyCopyable, Movable):
    # Plain fields: copying nested ZoneInfo values here miscompiled on 1.1.
    var at: Int
    var before_offset: Int
    var before_dst: Int
    var after_offset: Int
    var after_dst: Int


struct ZoneData(Movable):
    var times: List[Int]
    var types: List[Int]
    var dsts: List[Int]
    """DST amount after each transition."""
    var offsets: List[Int]
    var abbreviations: List[String]
    var initial: ZoneInfo
    var has_rule: Bool
    var has_dst: Bool
    var std_offset: Int
    var dst_offset: Int
    var std_name: String
    var dst_name: String
    var start: _Rule
    var end: _Rule

    def __init__(out self):
        self.times = List[Int]()
        self.types = List[Int]()
        self.dsts = List[Int]()
        self.offsets = List[Int]()
        self.abbreviations = List[String]()
        self.initial = ZoneInfo(0, 0, 0)
        self.has_rule = False
        self.has_dst = False
        self.std_offset = 0
        self.dst_offset = 0
        self.std_name = ""
        self.dst_name = ""
        self.start = _Rule(0, 0, 0, 0, 0)
        self.end = _Rule(0, 0, 0, 0, 0)

    # Lookups.

    def _table_info(self, index: Int) -> ZoneInfo:
        var kind = self.types[index]
        return ZoneInfo(self.offsets[kind], self.dsts[index], kind)

    def _rule_transitions(self, year: Int) -> Tuple[Int, Int]:
        """UTC instants of the daylight start and end in a year."""
        return (
            self.start.local_seconds(year) - self.std_offset,
            self.end.local_seconds(year) - self.dst_offset,
        )

    def _rule_info(self, daylight: Bool) -> ZoneInfo:
        if not daylight:
            # tzdata "main" data can mark winter as negative DST (Dublin);
            # report positive summer DST like ICU instead.
            var dst = (
                self.std_offset
                - self.dst_offset if (
                    self.has_dst and self.dst_offset < self.std_offset
                ) else 0
            )
            return ZoneInfo(self.std_offset, dst, -1)
        var amount = self.dst_offset - self.std_offset
        return ZoneInfo(self.dst_offset, amount if amount > 0 else 0, -2)

    def _in_rule(self, timestamp: Int) -> Bool:
        return self.has_rule and (
            len(self.times) == 0 or timestamp >= self.times[len(self.times) - 1]
        )

    def info_at(self, timestamp: Int) -> ZoneInfo:
        if not self._in_rule(timestamp):
            var low = 0
            var high = len(self.times)
            while low < high:
                var middle = (low + high) // 2
                if self.times[middle] <= timestamp:
                    low = middle + 1
                else:
                    high = middle
            if low == 0:
                return self.initial
            return self._table_info(low - 1)
        if not self.has_dst:
            return self._rule_info(False)
        var year = _utc_year(timestamp)
        var daylight = False
        var latest = Int.MIN
        # Later events win ties: "all year" rules end one year exactly when
        # the next begins (e.g. XXX-2<+01>-1,0/0,J365/23).
        for y in range(year - 1, year + 2):
            var edges = self._rule_transitions(y)
            var start = edges[0]
            var end = edges[1]
            if start <= end:
                if start <= timestamp and start >= latest:
                    latest = start
                    daylight = True
                if end <= timestamp and end >= latest:
                    latest = end
                    daylight = False
            else:
                if end <= timestamp and end >= latest:
                    latest = end
                    daylight = False
                if start <= timestamp and start >= latest:
                    latest = start
                    daylight = True
        return self._rule_info(daylight)

    def _next_transition(self, timestamp: Int) -> Optional[_Transition]:
        """First transition strictly after timestamp."""
        if not self._in_rule(timestamp):
            var low = 0
            var high = len(self.times)
            while low < high:
                var middle = (low + high) // 2
                if self.times[middle] <= timestamp:
                    low = middle + 1
                else:
                    high = middle
            if low < len(self.times):
                var before = self.initial if low == 0 else self._table_info(
                    low - 1
                )
                var after = self._table_info(low)
                return _Transition(
                    self.times[low],
                    before.offset,
                    before.dst,
                    after.offset,
                    after.dst,
                )
            if not self.has_rule:
                return None
        if not self.has_dst:
            return None
        var year = _utc_year(timestamp)
        var best = Int.MAX
        for y in range(year - 1, year + 2):
            var edges = self._rule_transitions(y)
            if edges[0] > timestamp and edges[0] < best:
                best = edges[0]
            if edges[1] > timestamp and edges[1] < best:
                best = edges[1]
        var before = self.info_at(best - 1)
        var after = self.info_at(best)
        return _Transition(
            best, before.offset, before.dst, after.offset, after.dst
        )

    def resolve_wall(self, wall: Int, fold: Int) -> WallInfo:
        """Resolve local wall seconds; fold 1 picks the later of two instants.
        """
        var first = Int.MAX
        var second = Int.MIN
        var gap = Optional[_Transition]()
        var cursor = wall - _WINDOW
        var offset = self.info_at(cursor).offset
        while True:
            var candidate = wall - offset
            if self.info_at(candidate).offset == offset:
                if candidate < first:
                    first = candidate
                if candidate > second:
                    second = candidate
            var upcoming = self._next_transition(cursor)
            if not upcoming or upcoming.value().at > wall + _WINDOW:
                break
            var transition = upcoming.value()
            if (
                transition.at + transition.before_offset <= wall
                and wall < transition.at + transition.after_offset
            ):
                gap = transition
            cursor = transition.at
            offset = transition.after_offset
        if first == Int.MAX:
            if not gap:
                # ponytail: unreachable for consistent data; keep a sane answer.
                var guess = self.info_at(wall - self.info_at(wall).offset)
                return WallInfo(guess.offset, guess.dst, False, True)
            var transition = gap.value()
            if fold == 0:
                return WallInfo(
                    transition.before_offset,
                    transition.before_dst,
                    False,
                    True,
                )
            return WallInfo(
                transition.after_offset, transition.after_dst, False, True
            )
        var chosen = first if fold == 0 else second
        var result = self.info_at(chosen)
        return WallInfo(wall - chosen, result.dst, first != second, False)

    def abbreviation(self, timestamp: Int) -> String:
        var info = self.info_at(timestamp)
        if info.abbreviation == -1:
            return self.std_name
        if info.abbreviation == -2:
            return self.dst_name
        return self.abbreviations[info.abbreviation]


def _utc_year(timestamp: Int) -> Int:
    # Within a year is enough: callers examine the neighbouring years too.
    return 1970 + Int(Float64(timestamp) / 31556952.0)


def _abbreviation_at(data: List[UInt8], start: Int, index: Int) -> String:
    var result = String("")
    var pos = start + index
    while pos < len(data) and data[pos] != 0:
        result += chr(Int(data[pos]))
        pos += 1
    return result


def _parse_footer(footer: String, mut zone: ZoneData) raises:
    var cursor = _Cursor(footer)
    zone.std_name = cursor.name()
    zone.std_offset = -cursor.seconds()
    zone.has_rule = True
    if cursor.peek() < 0:
        return
    zone.dst_name = cursor.name()
    zone.dst_offset = zone.std_offset + 3600
    if cursor.peek() != 44 and cursor.peek() >= 0:
        zone.dst_offset = -cursor.seconds()
    if cursor.peek() != 44:
        raise Error("POSIX TZ rule is missing")
    cursor.pos += 1
    zone.start = _parse_rule(cursor)
    if cursor.peek() != 44:
        raise Error("POSIX TZ end rule is missing")
    cursor.pos += 1
    zone.end = _parse_rule(cursor)
    zone.has_dst = True


def _dst_amount(offset: Int, previous: Int, following: Int) -> Int:
    var best = Int.MIN
    for standard in [previous, following]:
        if standard == Int.MIN:
            continue
        var amount = offset - standard
        if best == Int.MIN or (amount > 0 and (best <= 0 or amount < best)):
            best = amount
    return 0 if best == Int.MIN else best


def _parse(data: List[UInt8]) raises -> ZoneData:
    if (
        len(data) < 44
        or data[0] != 84
        or data[1] != 90
        or data[2] != 105
        or data[3] != 102
    ):
        raise Error("not a TZif file")
    var base = 0
    var time_size = 4
    if data[4] >= 50:
        base = 44 + (
            _u32(data, 32) * 5
            + _u32(data, 36) * 6
            + _u32(data, 40)
            + _u32(data, 28) * 8
            + _u32(data, 24)
            + _u32(data, 20)
        )
        time_size = 8
        if len(data) < base + 44:
            raise Error("truncated TZif file")
    var timecnt = _u32(data, base + 32)
    var typecnt = _u32(data, base + 36)
    var charcnt = _u32(data, base + 40)
    var times = base + 44
    var indexes = times + timecnt * time_size
    var types = indexes + timecnt
    var chars = types + typecnt * 6
    var end = chars + charcnt + _u32(data, base + 28) * (time_size + 4)
    end += _u32(data, base + 24) + _u32(data, base + 20)
    if typecnt == 0 or len(data) < end:
        raise Error("truncated TZif file")

    var zone = ZoneData()
    var is_dst = List[Bool]()
    for i in range(typecnt):
        var record = types + i * 6
        zone.offsets.append(_i32(data, record))
        is_dst.append(data[record + 4] != 0)
        zone.abbreviations.append(
            _abbreviation_at(data, chars, Int(data[record + 5]))
        )
    for i in range(timecnt):
        zone.times.append(
            _i64(data, times + i * 8) if time_size
            == 8 else _i32(data, times + i * 4)
        )
        zone.types.append(Int(data[indexes + i]))

    # DST amounts: tzdata stores only total offsets, so take the smallest
    # positive difference to the previous or next standard offset. Negative
    # amounts (tzdata "main" winter time) flip to positive summer DST, as ICU.
    var count = len(zone.times)
    var previous = List[Int](length=count, fill=Int.MIN)
    var following = List[Int](length=count, fill=Int.MIN)
    var last_standard = zone.offsets[0] if not is_dst[0] else Int.MIN
    for i in range(count):
        var kind = zone.types[i]
        if not is_dst[kind]:
            last_standard = zone.offsets[kind]
        previous[i] = last_standard
    var next_standard = Int.MIN
    for i in range(count - 1, -1, -1):
        var kind = zone.types[i]
        if not is_dst[kind]:
            next_standard = zone.offsets[kind]
        following[i] = next_standard
    for i in range(count):
        var kind = zone.types[i]
        var amount = 0
        if is_dst[kind]:
            amount = _dst_amount(zone.offsets[kind], previous[i], following[i])
        zone.dsts.append(amount)
    for i in range(count):
        if zone.dsts[i] < 0:
            # The neighbouring "standard" periods are the real summer time.
            var winter = zone.offsets[zone.types[i]]
            zone.dsts[i] = 0
            for j in [i - 1, i + 1]:
                if j >= 0 and j < count and not is_dst[zone.types[j]]:
                    var gain = zone.offsets[zone.types[j]] - winter
                    if gain > 0:
                        zone.dsts[j] = gain
    var initial_dst = 0
    if is_dst[0] and count > 0:
        initial_dst = max(
            _dst_amount(zone.offsets[0], Int.MIN, following[0]), 0
        )
    zone.initial = ZoneInfo(zone.offsets[0], initial_dst, 0)

    if time_size == 8:
        var footer_start = end + 1
        var footer_end = footer_start
        while footer_end < len(data) and data[footer_end] != 10:
            footer_end += 1
        if footer_end > footer_start:
            var footer = String("")
            for i in range(footer_start, footer_end):
                footer += chr(Int(data[i]))
            _parse_footer(footer, zone)
    return zone^


struct _ZoneCache(Movable):
    """Process-wide parsed zones, keyed by name; guarded by a pthread mutex."""

    var mutex: Pointer[UInt8, MutUntrackedOrigin]
    var names: List[String]
    var zones: List[ArcPointer[ZoneData]]

    def __init__(out self):
        # Large enough for pthread_mutex_t on every supported platform.
        self.mutex = unsafe_alloc[UInt8](128)
        self.names = List[String]()
        self.zones = List[ArcPointer[ZoneData]]()


def _init_cache() -> Optional[Pointer[NoneType, MutUntrackedOrigin]]:
    var cache = unsafe_alloc[_ZoneCache](1)
    cache.unsafe_write(_ZoneCache())
    _ = external_call["pthread_mutex_init", Int32](cache[].mutex, 0)
    return rebind[Pointer[NoneType, MutUntrackedOrigin]](cache)


def _keep_cache(cache: Optional[Pointer[NoneType, MutUntrackedOrigin]]):
    # Zones stay cached for the life of the process.
    pass


def _cache() -> Pointer[_ZoneCache, MutUntrackedOrigin]:
    var cache = _get_global[
        "morrow_tzif_zone_cache", _init_cache, _keep_cache
    ]()
    return rebind[Pointer[_ZoneCache, MutUntrackedOrigin]](cache.value())


def load_zone(zone: String) -> Optional[ArcPointer[ZoneData]]:
    """Return the parsed zone, reading each zone file once per process."""
    var cache = _cache()
    _ = external_call["pthread_mutex_lock", Int32](cache[].mutex)
    # ponytail: linear scan; programs use few zones, switch to Dict if not.
    for i in range(len(cache[].names)):
        if cache[].names[i] == zone:
            var found = cache[].zones[i].copy()
            _ = external_call["pthread_mutex_unlock", Int32](cache[].mutex)
            return found^
    _ = external_call["pthread_mutex_unlock", Int32](cache[].mutex)
    # Parse outside the lock; missing zones are not cached (ICU handles them).
    var parsed = _load_zone_file(zone)
    if parsed:
        _ = external_call["pthread_mutex_lock", Int32](cache[].mutex)
        cache[].names.append(zone)
        cache[].zones.append(parsed.value().copy())
        _ = external_call["pthread_mutex_unlock", Int32](cache[].mutex)
    return parsed^


def _load_zone_file(zone: String) -> Optional[ArcPointer[ZoneData]]:
    """Parse the system zone file, or None when unavailable or unsupported."""
    var path = _zone_path(zone)
    if path.byte_length() == 0:
        return None
    try:
        return ArcPointer(_parse(_read(path)))
    except:
        return None
