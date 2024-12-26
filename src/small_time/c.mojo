from sys import external_call
from memory import UnsafePointer, Pointer

alias void = UInt8
alias char = UInt8
alias schar = Int8
alias uchar = UInt8
alias short = Int16
alias ushort = UInt16
alias int = Int32
alias uint = UInt32
alias long = Int64
alias ulong = UInt64
alias float = Float32
alias double = Float64


@register_passable("trivial")
struct TimeVal:
    """Time value."""
    var tv_sec: Int
    """Seconds."""
    var tv_usec: Int
    """Microseconds."""

    fn __init__(out self, tv_sec: Int = 0, tv_usec: Int = 0):
        """Initializes a new time value.
        
        Args:
            tv_sec: Seconds.
            tv_usec: Microseconds.
        """
        self.tv_sec = tv_sec
        self.tv_usec = tv_usec


@register_passable("trivial")
struct Tm:
    """C Tm struct."""

    var tm_sec: Int32
    """Seconds."""
    var tm_min: Int32
    """Minutes."""
    var tm_hour: Int32
    """Hour."""
    var tm_mday: Int32
    """Day of the month."""
    var tm_mon: Int32
    """Month."""
    var tm_year: Int32
    """Year minus 1900."""
    var tm_wday: Int32
    """Day of the week."""
    var tm_yday: Int32
    """Day of the year."""
    var tm_isdst: Int32
    """Daylight savings flag."""
    var tm_gmtoff: Int64
    """Localtime zone offset seconds."""

    fn __init__(out self):
        """Initializes a new time struct."""
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


fn gettimeofday() -> TimeVal:
    """Gets the current time. It's a wrapper around libc `gettimeofday`.
    
    Returns:
        Current time.
    """
    var tv = TimeVal()
    _ = external_call["gettimeofday", NoneType](Pointer.address_of(tv), 0)
    return tv


fn time() -> Int:
    """Returns the current time in seconds since the Epoch.
    
    Returns:
        Current time in seconds.
    """
    var time = 0
    return external_call["time", Int](Pointer.address_of(time))


fn localtime(owned tv_sec: Int) -> Tm:
    """Converts a time value to a broken-down local time.

    Args:
        tv_sec: Time value in seconds since the Epoch.
    
    Returns:
        Broken down local time.
    """
    var buf = Tm()
    _ = external_call["localtime_r", UnsafePointer[Tm]](Pointer.address_of(tv_sec), Pointer.address_of(buf))
    return buf


fn strptime(time_str: String, time_format: String) -> Tm:
    """Parses a time string according to a format string.

    Args:
        time_str: Time string.
        time_format: Time format string.
    
    Returns:
        Broken down time.
    """
    var tm = Tm()
    _ = external_call["strptime", NoneType](time_str.unsafe_ptr(), time_format.unsafe_ptr(), Pointer.address_of(tm))
    return tm


fn strftime(format: String, owned time: Tm) -> String:
    """Formats a time value according to a format string.

    Args:
        format: Format string.
        time: Time value.
    
    Returns:
        Formatted time string.
    """
    var buf = String(capacity=26)
    _ = external_call["strftime", UInt](buf.unsafe_ptr(), len(format), Pointer.address_of(format), Pointer.address_of(time))
    return buf


fn gmtime(owned tv_sec: Int) -> Tm:
    """Converts a time value to a broken-down UTC time.
    
    Args:
        tv_sec: Time value in seconds since the Epoch.
    
    Returns:
        Broken down UTC time.
    """
    var tm = external_call["gmtime", UnsafePointer[Tm]](Pointer.address_of(tv_sec)).take_pointee()
    return tm
