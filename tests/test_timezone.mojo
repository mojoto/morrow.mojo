from std.testing import assert_equal, TestSuite

from morrow import TimeZone


def assert_timezone_raises(utc_str: String) raises:
    try:
        _ = TimeZone.from_utc(utc_str)
    except e:
        return
    raise Error("expected timezone parsing to fail")


def test_time_zone() raises:
    assert_equal(TimeZone.from_utc("UTC+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC0800").offset, 28800)
    assert_equal(TimeZone.from_utc("GMT").offset, 0)
    assert_equal(TimeZone.from_utc("GMT").name, "GMT")
    assert_equal(TimeZone.from_utc("gmt").name, "GMT")
    assert_equal(TimeZone.from_utc("Gmt").name, "GMT")
    assert_equal(TimeZone.from_utc("+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("08").offset, 28800)
    assert_equal(TimeZone.from_utc("+05:30").format(), "+05:30")
    assert_equal(TimeZone.from_utc("+05:30:15").offset, 19815)
    assert_equal(TimeZone.from_utc("+053015").offset, 19815)
    assert_equal(TimeZone.from_utc("+05:30:15").format(), "+05:30:15")
    assert_timezone_raises("+05:60")
    assert_timezone_raises("+05:30:60")
    assert_timezone_raises("+053060")
    assert_timezone_raises("+24:00")
    assert_timezone_raises("-24:00")
    assert_timezone_raises("+23:60")
    assert_timezone_raises("UTC+24:00")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
