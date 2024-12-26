import testing
from python import PythonObject
from _py import py_dt_datetime, py_time

import small_time.c
from small_time.small_time import SmallTime, now, strptime, from_timestamp, from_ordinal
from small_time.time_zone import TimeZone, from_utc


# TODO: Need a better way to test this, since it's not deterministic.
def assert_datetime_equal(dt: SmallTime, py_dt: PythonObject):
    testing.assert_true(
        dt.year == int(py_dt.year)
        and dt.month == int(py_dt.month)
        and dt.hour == int(py_dt.hour)
        and dt.minute == int(py_dt.minute)
        and dt.second == int(py_dt.second),
        "dt: " + str(dt) + " is not equal to py_dt: " + str(py_dt),
    )


def test_now():
    assert_datetime_equal(now(), py_dt_datetime().now())


def test_utc_now():
    assert_datetime_equal(now(utc=True), py_dt_datetime().utcnow())


def test_from_timestamp():
    assert_datetime_equal(from_timestamp(c.gettimeofday().tv_sec), py_dt_datetime().now())
    assert_datetime_equal(from_timestamp(c.gettimeofday().tv_sec, utc=True), py_dt_datetime().utcnow())


def test_iso_format():
    var d0 = SmallTime(2023, 10, 1, 0, 0, 0, 1234)
    testing.assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234+00:00")
    testing.assert_equal(d0.isoformat["seconds"](), "2023-10-01T00:00:00+00:00")
    testing.assert_equal(d0.isoformat["milliseconds"](), "2023-10-01T00:00:00.001+00:00")

    # with TimeZone
    var d1 = SmallTime(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Beijing"))
    testing.assert_equal(d1.isoformat["seconds"](), "2023-10-01T00:00:00+08:00")


def test_strptime():
    m = strptime("20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone())
    testing.assert_equal(str(m), "2023-01-20T15:49:10.000000+00:00")

    # TODO: Need to add more tests for different types of timestamps to parse.
    # Not sure if this is a valid timestamp? Python can parse it so...
    # m = strptime("2023-10-18 15:49:10 +0800", "%Y-%m-%d %H:%M:%S %z")
    # testing.assert_equal(str(m), "2023-10-18T15:49:10.000000+00:00")

    m = strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", String("+09:00"))
    testing.assert_equal(str(m), "2023-10-18T15:49:10.000000+09:00")


def test_ordinal():
    m = SmallTime(2023, 10, 1)
    o = m.to_ordinal()
    testing.assert_equal(o, 738794)

    m2 = from_ordinal(o)
    testing.assert_equal(m2.year, 2023)
    testing.assert_equal(m.month, 10)
    testing.assert_equal(m.day, 1)


def test_sub():
    var result = SmallTime(2023, 10, 1, 10, 0, 0, 1) - SmallTime(2023, 10, 1, 10, 0, 0)
    testing.assert_equal(result.microseconds, 1)
    testing.assert_equal(str(result), "0:00:00000001")

    result = SmallTime(2023, 10, 1, 10, 0, 1) - SmallTime(2023, 10, 1, 10, 0, 0)
    testing.assert_equal(result.seconds, 1)
    testing.assert_equal(str(result), "0:00:01")

    result = SmallTime(2023, 10, 1, 10, 1, 0) - SmallTime(2023, 10, 1, 10, 0, 0)
    testing.assert_equal(result.seconds, 60)
    testing.assert_equal(str(result), "0:01:00")

    result = SmallTime(2023, 10, 2, 10, 0, 0) - SmallTime(2023, 10, 1, 10, 0, 0)
    testing.assert_equal(result.days, 1)
    testing.assert_equal(str(result), "1 day, 0:00:00")

    result = SmallTime(2023, 10, 3, 10, 1, 1) - SmallTime(2023, 10, 1, 10, 0, 0)
    testing.assert_equal(result.days, 2)
    testing.assert_equal(str(result), "2 days, 0:01:01")


def test_format():
    var m = SmallTime(2024, 2, 1, 3, 4, 5, 123456)
    testing.assert_equal(m.format("YYYY-MM-DD HH:mm:ss.SSS ZZ"), "2024-02-01 03:04:05.123 +00:00")
    testing.assert_equal(m.format("Y-YY-YYY-YYYY M-MM D-DD"), "Y-24--2024 2-02 1-01")
    testing.assert_equal(m.format("H-HH-h-hh m-mm s-ss"), "3-03-3-03 4-04 5-05")
    testing.assert_equal(m.format("S-SS-SSS-SSSS-SSSSS-SSSSSS"), "1-12-123-1234-12345-123456")
    testing.assert_equal(m.format("d-dd-ddd-dddd"), "4--Thu-Thursday")
    testing.assert_equal(m.format("YYYY[Y] [[]MM[]][M]"), "2024Y [02]M")
