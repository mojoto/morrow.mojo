from memory import UnsafePointer
from sys.ffi import external_call

# C type aliases
alias c_void = UInt8
alias c_char = UInt8
alias c_schar = Int8
alias c_uchar = UInt8
alias c_short = Int16
alias c_ushort = UInt16
alias c_int = Int32
alias c_uint = UInt32
alias c_long = Int64
alias c_ulong = UInt64
alias c_float = Float32
alias c_double = Float64


@value
@register_passable("trivial")
struct CTimeval:
    """Represents the C struct timeval."""

    var tv_sec: Int  # Seconds
    var tv_usec: Int  # Microseconds

    fn __init__(inout self, tv_sec: Int = 0, tv_usec: Int = 0):
        self.tv_sec = tv_sec
        self.tv_usec = tv_usec


@value
@register_passable("trivial")
struct CTm:
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

    fn __init__(inout self):
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


@always_inline
fn c_gettimeofday() -> CTimeval:
    """Wrapper for the C function gettimeofday."""
    var tv = CTimeval()
    external_call["gettimeofday", NoneType](Reference(tv), 0)
    return tv


@always_inline
fn c_localtime(owned tv_sec: Int) -> CTm:
    """Wrapper for the C function localtime."""
    var tm = CTm()
    _ = external_call["localtime_r", Reference[CTm]](
        Reference(tv_sec), Reference(tm)
    )
    return tm


@always_inline
fn c_strptime(time_str: String, time_format: String) -> CTm:
    """Wrapper for the C function strptime."""
    var tm = CTm()
    _ = external_call["strptime", Reference[String]](
        time_str.unsafe_ptr(), time_format.unsafe_ptr(), Reference(tm)
    )
    return tm


@always_inline
fn c_gmtime(owned tv_sec: Int) -> CTm:
    """Wrapper for the C function gmtime."""
    var tm = CTm()
    _ = external_call["gmtime_r", Reference[CTm]](
        Reference(tv_sec), Reference(tm)
    )
    return tm


fn to_char_ptr(s: String) -> UnsafePointer[c_char]:
    """Only ASCII-based strings."""
    var ptr = UnsafePointer[c_char]().alloc(len(s))
    for i in range(len(s)):
        ptr.store(i, ord(s[i]))
    return ptr
