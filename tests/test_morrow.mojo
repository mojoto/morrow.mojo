from std.testing import assert_equal, assert_true, TestSuite

from morrow._libc import c_localtime, CTm
from morrow import Morrow
from morrow import TimeZone


def matches_tm(dt: Morrow, tm: CTm) -> Bool:
    return (
        dt.year == Int(tm.tm_year) + 1900
        and dt.month == Int(tm.tm_mon) + 1
        and dt.day == Int(tm.tm_mday)
        and dt.hour == Int(tm.tm_hour)
        and dt.minute == Int(tm.tm_min)
        and dt.second == Int(tm.tm_sec)
    )


def assert_tm_equal(dt: Morrow, tm: CTm) raises:
    assert_true(matches_tm(dt, tm))


def test_now() raises:
    var result = Morrow.now()
    assert_true(result.year >= 2020)
    assert_true(result.month >= 1 and result.month <= 12)
    assert_true(result.day >= 1 and result.day <= 31)
    assert_true(result.hour >= 0 and result.hour <= 23)
    assert_true(result.minute >= 0 and result.minute <= 59)
    assert_true(result.second >= 0 and result.second <= 60)
    assert_true(result.microsecond >= 0 and result.microsecond < 1000000)


def test_utcnow() raises:
    var result = Morrow.utcnow()
    assert_true(result.year >= 2020)
    assert_true(result.month >= 1 and result.month <= 12)
    assert_true(result.day >= 1 and result.day <= 31)
    assert_true(result.hour >= 0 and result.hour <= 23)
    assert_true(result.minute >= 0 and result.minute <= 59)
    assert_true(result.second >= 0 and result.second <= 60)
    assert_equal(result.tz.offset, 0)
    assert_true(result.microsecond >= 0 and result.microsecond < 1000000)


def test_fromtimestamp() raises:
    var timestamp = 1700000000
    var result = Morrow.fromtimestamp(Float64(timestamp))
    assert_tm_equal(result, c_localtime(timestamp))


def test_utcfromtimestamp() raises:
    var result = Morrow.utcfromtimestamp(1700000000.0)
    assert_equal(result.year, 2023)
    assert_equal(result.month, 11)
    assert_equal(result.day, 14)
    assert_equal(result.hour, 22)
    assert_equal(result.minute, 13)
    assert_equal(result.second, 20)
    assert_equal(result.tz.offset, 0)


def test_iso_format() raises:
    var d0 = Morrow(2023, 10, 1, 0, 0, 0, 1234)
    assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234")
    assert_equal(d0.isoformat(timespec="seconds"), "2023-10-01T00:00:00")
    assert_equal(
        d0.isoformat(timespec="milliseconds"), "2023-10-01T00:00:00.001"
    )

    var d1 = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Beijing"))
    assert_equal(d1.isoformat(timespec="seconds"), "2023-10-01T00:00:00+08:00")


def test_strptime() raises:
    var m = Morrow.strptime(
        "20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone.none()
    )
    assert_equal(String(m), "2023-01-20T15:49:10.000000+00:00")

    m = Morrow.strptime("2023-10-18 15:49:10 +0800", "%Y-%m-%d %H:%M:%S %z")
    assert_equal(String(m), "2023-10-18T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", "+09:00")
    assert_equal(String(m), "2023-10-18T15:49:10.000000+09:00")


def test_ordinal() raises:
    var m = Morrow(2023, 10, 1)
    var o = m.toordinal()
    assert_equal(o, 738794)

    var m2 = Morrow.fromordinal(o)
    assert_equal(m2.year, 2023)
    assert_equal(m.month, 10)
    assert_equal(m.day, 1)


def test_sub() raises:
    var result = Morrow(2023, 10, 1, 10, 0, 0, 1) - Morrow(
        2023, 10, 1, 10, 0, 0
    )
    assert_equal(result.microseconds, 1)
    assert_equal(String(result), "0:00:00000001")

    result = Morrow(2023, 10, 1, 10, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 1)
    assert_equal(String(result), "0:00:01")

    result = Morrow(2023, 10, 1, 10, 1, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 60)
    assert_equal(String(result), "0:01:00")

    result = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 1)
    assert_equal(String(result), "1 day, 0:00:00")

    result = Morrow(2023, 10, 3, 10, 1, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 2)
    assert_equal(String(result), "2 days, 0:01:01")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
