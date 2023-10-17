from testing import assert_equal, assert_true

from morrow import Morrow
from morrow._libc import c_gettimeofday
from morrow._py import py_dt_datetime, py_time
from morrow.timezone import TimeZone


fn assert_datetime_equal(dt: Morrow, py_dt: PythonObject) raises:
    _ = assert_true(
        dt.year == py_dt.year.to_float64().to_int()
        and dt.month == py_dt.month.to_float64().to_int()
        and dt.hour == py_dt.hour.to_float64().to_int()
        and dt.minute == py_dt.minute.to_float64().to_int()
        and dt.second == py_dt.second.to_float64().to_int(),
        "dt: " + dt.__str__() + " is not equal to py_dt: " + py_dt.to_string(),
    )


fn test_now() raises:
    print("Running test_now()")
    let result = Morrow.now()
    assert_datetime_equal(result, py_dt_datetime().now())


fn test_utcnow() raises:
    print("Running test_utcnow()")
    let result = Morrow.utcnow()
    assert_datetime_equal(result, py_dt_datetime().utcnow())


fn test_fromtimestamp() raises:
    print("Running test_fromtimestamp()")
    let t = c_gettimeofday()
    let result = Morrow.fromtimestamp(t.tv_sec)
    assert_datetime_equal(result, py_dt_datetime().now())


fn test_utcfromtimestamp() raises:
    print("Running test_utcfromtimestamp()")
    let t = c_gettimeofday()
    let result = Morrow.utcfromtimestamp(t.tv_sec)
    assert_datetime_equal(result, py_dt_datetime().utcnow())


def test_iso_format():
    print("Running test_iso_format()")
    let d0 = Morrow(2023, 10, 1, 0, 0, 0, 1234)
    assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234")
    assert_equal(d0.isoformat(timespec="seconds"), "2023-10-01T00:00:00")
    assert_equal(d0.isoformat(timespec="milliseconds"), "2023-10-01T00:00:00.001")

    # with TimeZone
    let d1 = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Bejing"))
    assert_equal(d1.isoformat(timespec="seconds"), "2023-10-01T00:00:00+08:00")


def test_time_zone():
    print("Running test_time_zone()")
    assert_equal(TimeZone.from_utc("UTC+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC0800").offset, 28800)
    assert_equal(TimeZone.from_utc("+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("08").offset, 28800)


def test_strptime():
    print("Running test_strptime()")
    m = Morrow.strptime("20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone.local())
    assert_equal(m.__str__(), "2023-01-20T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10 +08:00", "%Y-%m-%d %H:%M:%S %z")
    assert_equal(m.__str__(), "2023-10-18T15:49:10.000000+08:00")


def test_sub():
    print("Running test_sub()")
    var result = Morrow(2023, 10, 1, 10, 0, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.microseconds, 1)
    assert_equal(result.__str__(), "0:00:00000001")

    result = Morrow(2023, 10, 1, 10, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 1)
    assert_equal(result.__str__(), "0:00:01")

    result = Morrow(2023, 10, 1, 10, 1, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 60)
    assert_equal(result.__str__(), "0:01:00")

    result = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 1)
    assert_equal(result.__str__(), "1 day 0:00:00")

    result = Morrow(2023, 10, 3, 10, 1, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 2)
    assert_equal(result.__str__(), "2 days 0:01:01")


def main():
    test_now()
    test_utcnow()
    test_fromtimestamp()
    test_utcfromtimestamp()
    test_iso_format()
    test_sub()
    test_time_zone()
    test_strptime()
