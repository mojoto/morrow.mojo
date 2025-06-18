from sys import external_call, os_is_macos, os_is_windows
from sys.ffi import c_uchar, c_int, c_long, c_char
import sys._libc as libc
from memory import UnsafePointer


alias time_t = Int64
alias suseconds_t = time_t
alias c_void = UInt8


@fieldwise_init
@register_passable("trivial")
struct _TimeValue(Copyable, ExplicitlyCopyable, Movable):
    """C `TimeValue` struct."""
    var seconds: time_t
    """Seconds to wait. Corresponds to `tv_sec` in C."""
    var microseconds: suseconds_t
    """Microseconds to wait. Corresponds to `tv_usec` in C."""


@fieldwise_init
@register_passable("trivial")
struct _TimeZone(Copyable, ExplicitlyCopyable, Movable):
    """C `timezone` struct."""
    var minutes_west: c_int
    """Minutes west of Greenwich."""
    var dst_time_correction: c_int
    """Type of DST correction."""


@fieldwise_init
@register_passable("trivial")
struct _Time(Copyable, ExplicitlyCopyable, Movable):
    """C `_Time` struct."""

    var seconds: c_int
    """Seconds."""
    var minutes: c_int
    """Minutes."""
    var hours: c_int
    """Hour."""
    var day_of_month: c_int
    """Day of the month."""
    var month: c_int
    """Month."""
    var year: c_int
    """Year minus 1900."""
    var day_of_week: c_int
    """Day of the week."""
    var day_of_year: c_int
    """Day of the year."""
    var is_daylight_savings: c_int
    """Whether daylight saving time is in effect at the time described.
    The value is positive if daylight saving time is in effect,
    zero if it is not, and negative if the information is not available."""
    var time_zone_offset: c_long
    """The difference, in seconds, of the timezone represented by this broken-down time and UTC"""

    fn __init__(out self):
        """Initializes a new time struct."""
        self.seconds = 0
        self.minutes = 0
        self.hours = 0
        self.day_of_month = 0
        self.month = 0
        self.year = 0
        self.day_of_week = 0
        self.day_of_year = 0
        self.is_daylight_savings = 0
        self.time_zone_offset = 0


fn _gettimeofday(tv: UnsafePointer[_TimeValue], tz: UnsafePointer[_TimeZone]) -> Int32:
    """Gets the current time. It's a wrapper around libc `gettimeofday`.
    The `tv` parameter is a pointer to a `struct timeval` that will be filled.

    Args:
        tv: UnsafePointer to a `struct timeval` that will be filled with the current time.
        tz: UnsafePointer to a `struct timezone` that will be filled with the timezone information.
    
    Returns:
        The return value is 0 on success, or -1 on error. If an error occurs,
        the global variable `errno` is set to indicate the error.
    
    #### C Function:
    ```c
    int gettimeofday(struct timeval *restrict tv, struct timezone *_Nullable restrict tz);
    ```
    """
    return external_call["gettimeofday", Int32, UnsafePointer[_TimeValue], UnsafePointer[_TimeZone]](tv, tz)


fn get_time_of_day() raises -> _TimeValue:
    """Gets the current time. Wrapper around libc `gettimeofday`.
    
    Returns:
        The current time.
    
    #### C Function:
    ```c
    int gettimeofday(struct timeval *restrict tv, struct timezone *restrict tz);
    ```
    """
    var tv = InlineArray[_TimeValue, 1](uninitialized=True)
    var tz = InlineArray[_TimeZone, 1](uninitialized=True)
    var result = _gettimeofday(tv.unsafe_ptr(), tz.unsafe_ptr())
    if result != 0:
        var errno = get_errno()
        if errno == EFAULT:
            raise Error("[EFAULT] gettimeofday failed: One of `tv` or `tz` pointed outside the accessible address space.")
        else:
            raise Error("[UNKNOWN] gettimeofday failed with unknown errno code: ", errno)
    return tv[0]


fn _localtime_r(timep: UnsafePointer[time_t, mut=False], result: UnsafePointer[_Time]) -> None:
    """Converts a time value to a broken-down local time.

    Args:
        timep: UnsafePointer to a time value in seconds since the Epoch.
        result: UnsafePointer to a `_Time` struct where the broken-down local time will be stored.
    
    #### C Function:
    ```c
    struct tm *localtime_r(const time_t *timep, struct tm *result);
    ```
    """
    _ = external_call[
        "localtime_r",
        UnsafePointer[_Time],
        UnsafePointer[time_t, mut=False],
        UnsafePointer[_Time]
    ](timep, result)


fn get_local_time(seconds_since_epoch: Int64) raises -> _Time:
    """Converts a time value to a broken-down local time.

    Args:
        seconds_since_epoch: Time value in seconds since the Epoch.
    
    #### C Function:
    ```c
    struct tm *localtime_r(const time_t *timep, struct tm *result);
    ```
    """
    var result = InlineArray[_Time, 1](uninitialized=True)
    _localtime_r(UnsafePointer[mut=False](to=seconds_since_epoch), result.unsafe_ptr())
    if not result.unsafe_ptr():
        raise Error("get_local_time failed: The pointer to the result is still null, which indicates the conversion failed.")
    return result[0]


fn _strptime(
    s: UnsafePointer[c_char, mut=False],
    format: UnsafePointer[c_char, mut=False],
    tm: UnsafePointer[_Time]
) -> UnsafePointer[c_char]:
    """Parses a time string according to a format string.

    Args:
        s: Time string to parse.
        format: Time format string.
        tm: UnsafePointer to a `_Time` struct where the broken-down time will be stored.
    
    Returns:
        Broken down time.
    
    #### C Function:
    ```c
    char *strptime(
        const char *restrict s, const char *restrict format, struct tm *restrict tm
    );
    ```
    """
    return external_call[
        "strptime",
        UnsafePointer[c_char],
        UnsafePointer[c_char, mut=False],
        UnsafePointer[c_char, mut=False],
        UnsafePointer[_Time]
    ](s, format, tm)


fn parse_time_with_format(owned time: String, owned format: String) raises -> _Time:
    """Parses a time string according to a format string.

    Args:
        time: Time string to parse.
        format: Time format string.
    
    Returns:
        Broken down time.
    
    #### C Function:
    ```c
    char *strptime(
        const char *restrict s, const char *restrict format, struct tm *restrict tm
    );
    ```
    """
    var tm = InlineArray[_Time, 1](uninitialized=True)
    _ = _strptime(
        time.unsafe_cstr_ptr().origin_cast[mut=False](),
        format.unsafe_cstr_ptr().origin_cast[mut=False](),
        tm.unsafe_ptr()
    )
    if not tm.unsafe_ptr():
        raise Error("parse_time_with_format failed: The pointer to the result is still null, which indicates the parsing failed.")
    return tm[0]


fn _gmtime(timep: UnsafePointer[time_t, mut=False]) -> UnsafePointer[_Time]:
    """Converts a time value to a broken-down UTC time.
    
    Args:
        timep: UnsafePointer to a time value in seconds since the Epoch.
    
    Returns:
        Broken down UTC time.
    
    #### C Function:
    ```c
    struct tm *gmtime(const time_t *timep);
    ```
    """
    return external_call["gmtime", UnsafePointer[_Time], UnsafePointer[time_t, mut=False]](timep)


fn get_gm_time(time: time_t) raises -> _Time:
    """Converts a time value to a broken-down UTC time.
    
    Args:
        time: Time value in seconds since the Epoch.

    Returns:
        Broken down UTC time.
    
    #### C Function:
    ```c
    struct tm *gmtime(const time_t *timep);
    ```
    """
    var result = _gmtime(UnsafePointer[mut=False](to=time))
    if not result:
        raise Error("get_gm_time failed: The pointer to the result is still null, which indicates the conversion failed.")
    
    # TODO (Mikhail): Maybe copy the result, not sure if take_pointee is safe here.
    return result.take_pointee()


fn get_errno() -> c_int:
    """Get a copy of the current value of the `errno` global variable for
    the current thread.

    Returns:
        A copy of the current value of `errno` for the current thread.
    """

    @parameter
    if os_is_windows():
        var errno = InlineArray[c_int, 1]()
        _ = external_call["_get_errno", c_void](errno.unsafe_ptr())
        return errno[0]
    else:
        alias loc = "__error" if os_is_macos() else "__errno_location"
        return external_call[loc, UnsafePointer[c_int]]()[]


# --- ( error.h Constants )-----------------------------------------------------
# TODO: These are probably platform specific, we should check the values on each linux and macos.
alias EPERM = 1
alias ENOENT = 2
alias ESRCH = 3
alias EINTR = 4
alias EIO = 5
alias ENXIO = 6
alias E2BIG = 7
alias ENOEXEC = 8
alias EBADF = 9
alias ECHILD = 10
alias EAGAIN = 11
alias ENOMEM = 12
alias EACCES = 13
alias EFAULT = 14
alias ENOTBLK = 15
alias EBUSY = 16
alias EEXIST = 17
alias EXDEV = 18
alias ENODEV = 19
alias ENOTDIR = 20
alias EISDIR = 21
alias EINVAL = 22
alias ENFILE = 23
alias EMFILE = 24
alias ENOTTY = 25
alias ETXTBSY = 26
alias EFBIG = 27
alias ENOSPC = 28
alias ESPIPE = 29
alias EROFS = 30
alias EMLINK = 31
alias EPIPE = 32
alias EDOM = 33
alias ERANGE = 34
alias EWOULDBLOCK = EAGAIN
alias EINPROGRESS = 36 if os_is_macos() else 115
alias EALREADY = 37 if os_is_macos() else 114
alias ENOTSOCK = 38 if os_is_macos() else 88
alias EDESTADDRREQ = 39 if os_is_macos() else 89
alias EMSGSIZE = 40 if os_is_macos() else 90
alias ENOPROTOOPT = 42 if os_is_macos() else 92
alias EAFNOSUPPORT = 47 if os_is_macos() else 97
alias EADDRINUSE = 48 if os_is_macos() else 98
alias EADDRNOTAVAIL = 49 if os_is_macos() else 99
alias ENETDOWN = 50 if os_is_macos() else 100
alias ENETUNREACH = 51 if os_is_macos() else 101
alias ECONNABORTED = 53 if os_is_macos() else 103
alias ECONNRESET = 54 if os_is_macos() else 104
alias ENOBUFS = 55 if os_is_macos() else 105
alias EISCONN = 56 if os_is_macos() else 106
alias ENOTCONN = 57 if os_is_macos() else 107
alias ETIMEDOUT = 60 if os_is_macos() else 110
alias ECONNREFUSED = 61 if os_is_macos() else 111
alias ELOOP = 62 if os_is_macos() else 40
alias ENAMETOOLONG = 63 if os_is_macos() else 36
alias EHOSTUNREACH = 65 if os_is_macos() else 113
alias EDQUOT = 69 if os_is_macos() else 122
alias ENOMSG = 91 if os_is_macos() else 42
alias EPROTO = 100 if os_is_macos() else 71
alias EOPNOTSUPP = 102 if os_is_macos() else 95
