from std.testing import assert_equal, TestSuite

from morrow import TimeZone


def test_time_zone() raises:
    assert_equal(TimeZone.from_utc("UTC+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("UTC0800").offset, 28800)
    assert_equal(TimeZone.from_utc("+08:00").offset, 28800)
    assert_equal(TimeZone.from_utc("+0800").offset, 28800)
    assert_equal(TimeZone.from_utc("08").offset, 28800)
    assert_equal(TimeZone.from_utc("+05:30").format(), "+05:30")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
