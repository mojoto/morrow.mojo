from memory.unsafe import Pointer


@value
@register_passable("trivial")
struct CTimeval:
    var tv_sec: Int  # Seconds
    var tv_usec: Int  # Microseconds

    fn __init__(tv_sec: Int = 0, tv_usec: Int = 0) -> Self:
        return Self {tv_sec: tv_sec, tv_usec: tv_usec}


@value
@register_passable("trivial")
struct CTm:
    var tm_sec: Int32  # Seconds
    var tm_min: Int32  # Minutes
    var tm_hour: Int32  # Hour
    var tm_mday: Int32  # Day of the month
    var tm_mon: Int32  # Month
    var tm_year: Int32  # Year minus 1900
    var tm_wday: Int32  # Day of the week
    var tm_yday: Int32  # Day of the year
    var tm_isdst: Int32  # Daylight savings flag
    var tm_gmtoff: Int64  # localtime zone offset seconds

    fn __init__() -> Self:
        return Self {
            tm_sec: 0,
            tm_min: 0,
            tm_hour: 0,
            tm_mday: 0,
            tm_mon: 0,
            tm_year: 0,
            tm_wday: 0,
            tm_yday: 0,
            tm_isdst: 0,
            tm_gmtoff: 0,
        }


@always_inline
fn c_gettimeofday() -> CTimeval:
    var tv = CTimeval()
    let p_tv = Pointer[CTimeval].address_of(tv)
    external_call["gettimeofday", NoneType, Pointer[CTimeval], Int32](p_tv, 0)
    return tv


@always_inline
fn c_localtime(owned tv_sec: Int) -> CTm:
    let p_tv_sec = Pointer[Int].address_of(tv_sec)
    let tm = external_call["localtime", Pointer[CTm], Pointer[Int]](p_tv_sec).load()
    return tm


@always_inline
fn c_gmtime(owned tv_sec: Int) -> CTm:
    let p_tv_sec = Pointer[Int].address_of(tv_sec)
    let tm = external_call["gmtime", Pointer[CTm], Pointer[Int]](p_tv_sec).load()
    return tm
