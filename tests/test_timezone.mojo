from std.testing import assert_equal, assert_true, TestSuite

from morrow import TimeZone


def assert_timezone_raises(utc_str: String) raises:
    try:
        _ = TimeZone.from_utc(utc_str)
    except e:
        return
    raise Error("expected timezone parsing to fail")


def test_time_zone() raises:
    var none_tz = TimeZone.none()
    assert_true(none_tz.is_none())
    assert_equal(none_tz.offset, 0)
    assert_equal(String(none_tz), "None")

    var local_tz = TimeZone.local()
    assert_equal(local_tz.name, "local")
    assert_equal(String(local_tz), "local")

    assert_equal(TimeZone.from_utc("UTC").offset, 0)
    assert_equal(TimeZone.from_utc("utc").offset, 0)
    assert_equal(TimeZone.from_utc("Utc").name, "utc")
    assert_equal(TimeZone.from_utc("Z").offset, 0)
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
    assert_equal(String(TimeZone.from_utc("+08:00")), "+08:00")
    assert_equal(TimeZone.from_utc("+05:30").format(), "+05:30")
    assert_equal(TimeZone.from_utc("+05:30:15").offset, 19815)
    assert_equal(TimeZone.from_utc("+053015").offset, 19815)
    assert_equal(TimeZone.from_utc("+05:30:15").format(), "+05:30:15")
    assert_equal(String(TimeZone.from_utc("+05:30:15")), "+05:30:15")
    assert_equal(TimeZone.from_utc("-05:30:15").offset, -19815)
    assert_equal(TimeZone.from_utc("-053015").offset, -19815)
    assert_equal(TimeZone.from_utc("-05:30:15").format(), "-05:30:15")
    assert_equal(String(TimeZone.from_utc("-05:30:15")), "-05:30:15")
    assert_equal(TimeZone.from_utc("-053015").format(""), "-053015")
    assert_timezone_raises("+05:60")
    assert_timezone_raises("+05:30:60")
    assert_timezone_raises("+053060")
    assert_timezone_raises("+24:00")
    assert_timezone_raises("-24:00")
    assert_timezone_raises("+23:60")
    assert_timezone_raises("UTC+24:00")
    assert_timezone_raises("")
    assert_timezone_raises("z")
    assert_timezone_raises("UTC+8")
    assert_timezone_raises("UTC+080")
    assert_timezone_raises("UTC+08:")
    assert_timezone_raises("utc+08:00")
    assert_timezone_raises("+05:3a")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
