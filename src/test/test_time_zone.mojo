import testing
from small_time.time_zone import TimeZone, from_utc


def test_time_zone():
    testing.assert_equal(from_utc("UTC+0800").offset, 28800)
    testing.assert_equal(from_utc("UTC+08:00").offset, 28800)
    testing.assert_equal(from_utc("UTC08:00").offset, 28800)
    testing.assert_equal(from_utc("UTC0800").offset, 28800)
    testing.assert_equal(from_utc("+08:00").offset, 28800)
    testing.assert_equal(from_utc("+0800").offset, 28800)
    testing.assert_equal(from_utc("08").offset, 28800)


def test_time_zone_from_name():
    # Test with a known time zone
    tz = TimeZone.from_name("Asia/Shanghai")
    testing.assert_equal(tz.name, "Asia/Shanghai")
    testing.assert_equal(tz.offset, 28800)  # +08:00 in seconds

    # Test with an invalid time zone
    _ = TimeZone.from_name("Invalid/TimeZone")