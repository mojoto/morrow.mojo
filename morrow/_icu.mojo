"""Private ICU calendar bridge; each query owns its calendar (no global TZ mutation)."""
from std.ffi import OwnedDLHandle
from std.memory import Pointer
from std.os import getenv


def _load_icu() raises -> OwnedDLHandle:
    var prefix = getenv("CONDA_PREFIX")
    if prefix != "":
        try:
            return OwnedDLHandle(prefix + "/lib/libicui18n.so")
        except e:
            pass
        try:
            return OwnedDLHandle(prefix + "/lib/libicui18n.dylib")
        except e:
            pass
    try:
        return OwnedDLHandle("/usr/lib/libicucore.A.dylib")
    except e:
        pass
    try:
        return OwnedDLHandle("libicui18n.so")
    except e:
        pass
    for version in range(99, 59, -1):
        try:
            return OwnedDLHandle("libicui18n.so." + String(version))
        except e:
            pass
    raise Error(
        "IANA timezones require ICU: install your system ICU runtime library"
    )


struct ZoneResult(Copyable, ImplicitlyCopyable, Movable):
    var offset: Int
    var dst: Int
    var timestamp: Int
    var ambiguous: Bool
    var imaginary: Bool

    def __init__(
        out self,
        offset: Int,
        dst: Int,
        timestamp: Int,
        ambiguous: Bool = False,
        imaginary: Bool = False,
    ):
        self.offset = offset
        self.dst = dst
        self.timestamp = timestamp
        self.ambiguous = ambiguous
        self.imaginary = imaginary


# ponytail: per-query calendars avoid shared mutable state; add thread-local reuse only if profiling warrants it.
struct Calendar(Movable):
    var lib: OwnedDLHandle
    var suffix: String
    var handle: Int

    def __init__(out self, name: String) raises:
        self.lib = _load_icu()
        self.suffix = ""
        self.handle = 0
        var found = False
        try:
            _ = self.lib.get_function[Int]("ucal_open")
            found = True
        except e:
            pass
        if not found:
            for version in range(99, 59, -1):
                try:
                    _ = self.lib.get_function[Int](
                        "ucal_open_" + String(version)
                    )
                    self.suffix = "_" + String(version)
                    found = True
                    break
                except e:
                    pass
        if not found:
            raise Error("ICU calendar API is unavailable")
        var chars = List[UInt16]()
        for i in range(name.byte_length()):
            var c = Int(name.as_bytes()[i])
            if c < 32 or c > 126:
                raise Error("timezone identifiers must contain printable ASCII")
            chars.append(UInt16(c))
        var status = Int32(0)
        if name != "local":
            var canonical = List[UInt16](length=256, fill=UInt16(0))
            var system_id = Int8(0)
            _ = self.lib.get_function[Int32](
                "ucal_getCanonicalTimeZoneID" + self.suffix
            )(
                chars.unsafe_ptr(),
                Int32(len(chars)),
                canonical.unsafe_ptr(),
                Int32(256),
                Pointer(to=system_id),
                Pointer(to=status),
            )
            if status > 0 or system_id == 0:
                raise Error("unknown IANA timezone: " + name)
            self.handle = self.lib.get_function[Int]("ucal_open" + self.suffix)(
                chars.unsafe_ptr(),
                Int32(len(chars)),
                0,
                Int32(1),
                Pointer(to=status),
            )
        else:
            self.handle = self.lib.get_function[Int]("ucal_open" + self.suffix)(
                0, Int32(0), 0, Int32(1), Pointer(to=status)
            )
        if status > 0 or self.handle == 0:
            raise Error("ICU could not open timezone: " + name)
        self.lib.get_function("ucal_setGregorianChange" + self.suffix)(
            self.handle, Float64(-1e18), Pointer(to=status)
        )
        self.check(status)

    def __deinit__(deinit self):
        if self.handle != 0:
            try:
                self.lib.get_function("ucal_close" + self.suffix)(self.handle)
            except e:
                pass

    @staticmethod
    def check(status: Int32) raises:
        if status > 0:
            raise Error("ICU calendar error " + String(status))

    def at(self, timestamp: Int) raises -> ZoneResult:
        var status = Int32(0)
        self.lib.get_function("ucal_setMillis" + self.suffix)(
            self.handle, Float64(timestamp) * 1000, Pointer(to=status)
        )
        var raw = self.lib.get_function[Int32]("ucal_get" + self.suffix)(
            self.handle, Int32(15), Pointer(to=status)
        )
        var dst = self.lib.get_function[Int32]("ucal_get" + self.suffix)(
            self.handle, Int32(16), Pointer(to=status)
        )
        self.check(status)
        return ZoneResult(
            (Int(raw) + Int(dst)) // 1000, Int(dst) // 1000, timestamp
        )

    def wall(
        self,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int,
        wall_seconds: Int,
        fold: Int,
    ) raises -> ZoneResult:
        var timestamps = List[Int]()
        for choice in range(2):
            var status = Int32(0)
            self.lib.get_function("ucal_clear" + self.suffix)(self.handle)
            self.lib.get_function("ucal_setAttribute" + self.suffix)(
                self.handle, Int32(3), Int32(1 - choice)
            )
            self.lib.get_function("ucal_setAttribute" + self.suffix)(
                self.handle, Int32(4), Int32(choice)
            )
            self.lib.get_function("ucal_setDateTime" + self.suffix)(
                self.handle,
                Int32(year),
                Int32(month - 1),
                Int32(day),
                Int32(hour),
                Int32(minute),
                Int32(second),
                Pointer(to=status),
            )
            var millis = self.lib.get_function[Float64](
                "ucal_getMillis" + self.suffix
            )(self.handle, Pointer(to=status))
            self.check(status)
            timestamps.append(Int(millis / 1000))
        var actual = self.at(timestamps[fold])
        var imaginary = actual.timestamp + actual.offset != wall_seconds
        var offset = wall_seconds - actual.timestamp
        return ZoneResult(
            offset,
            actual.dst + offset - actual.offset,
            actual.timestamp,
            timestamps[0] != timestamps[1] and not imaginary,
            imaginary,
        )
