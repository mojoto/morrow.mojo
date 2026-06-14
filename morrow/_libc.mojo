from std.ffi import external_call
from std.memory import UnsafePointer, alloc

# C type aliases
comptime c_void = UInt8
comptime c_char = UInt8
comptime c_schar = Int8
comptime c_uchar = UInt8
comptime c_short = Int16
comptime c_ushort = UInt16
comptime c_int = Int32
comptime c_uint = UInt32
comptime c_long = Int64
comptime c_ulong = UInt64
comptime c_float = Float32
comptime c_double = Float64


struct CTimeval(TrivialRegisterPassable):
    """Represents the C struct timeval."""

    var tv_sec: Int  # Seconds
    var tv_usec: Int  # Microseconds

    def __init__(out self, tv_sec: Int = 0, tv_usec: Int = 0):
        self.tv_sec = tv_sec
        self.tv_usec = tv_usec


struct CTm(TrivialRegisterPassable):
    """Represents the C struct tm for date and time information."""

    var tm_sec: c_int  # Seconds
    var tm_min: c_int  # Minutes
    var tm_hour: c_int  # Hour
    var tm_mday: c_int  # Day of the month
    var tm_mon: c_int  # Month
    var tm_year: c_int  # Year minus 1900
    var tm_wday: c_int  # Day of the week
    var tm_yday: c_int  # Day of the year
    var tm_isdst: c_int  # Daylight savings flag
    var tm_gmtoff: c_long  # localtime zone offset seconds
    var tm_zone: UnsafePointer[c_char, MutExternalOrigin]  # timezone name

    def __init__(out self):
        self.tm_sec = 0
        self.tm_min = 0
        self.tm_hour = 0
        self.tm_mday = 0
        self.tm_mon = 0
        self.tm_year = 0
        self.tm_wday = 0
        self.tm_yday = 0
        self.tm_isdst = 0
        self.tm_gmtoff = 0
        self.tm_zone = UnsafePointer[
            c_char, MutExternalOrigin
        ].unsafe_dangling()


@always_inline
def c_gettimeofday() -> CTimeval:
    """Wrapper for the C function gettimeofday."""
    var tv = CTimeval()
    external_call["gettimeofday", NoneType](UnsafePointer(to=tv), 0)
    return tv


@always_inline
def c_localtime(tv_sec: Int) -> CTm:
    """Wrapper for the C function localtime."""
    var tv_sec_ = tv_sec
    var tm = CTm()
    _ = external_call["localtime_r", UnsafePointer[CTm, MutExternalOrigin]](
        UnsafePointer(to=tv_sec_), UnsafePointer(to=tm)
    )
    return tm


@always_inline
def c_strptime(time_str: String, time_format: String) -> CTm:
    """Wrapper for the C function strptime."""
    var time_str_ = time_str
    var time_format_ = time_format
    var tm = CTm()
    _ = external_call["strptime", UnsafePointer[Int8, MutExternalOrigin]](
        time_str_.as_c_string_slice().unsafe_ptr(),
        time_format_.as_c_string_slice().unsafe_ptr(),
        UnsafePointer(to=tm),
    )
    return tm


@always_inline
def c_gmtime(tv_sec: Int) -> CTm:
    """Wrapper for the C function gmtime."""
    var tv_sec_ = tv_sec
    var tm = CTm()
    _ = external_call["gmtime_r", UnsafePointer[CTm, MutExternalOrigin]](
        UnsafePointer(to=tv_sec_), UnsafePointer(to=tm)
    )
    return tm


def to_char_ptr(s: String) -> UnsafePointer[c_char, MutExternalOrigin]:
    """Only ASCII-based strings."""
    var ptr = alloc[c_char](s.byte_length())
    for i in range(s.byte_length()):
        ptr.store(i, UInt8(ord(s[byte=i])))
    return ptr
