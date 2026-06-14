from std.testing import assert_equal, TestSuite

from morrow import Morrow
from morrow import TimeZone


def test_format() raises:
    var m = Morrow(2024, 2, 1, 3, 4, 5, 123456)
    assert_equal(
        m.format("YYYY-MM-DD HH:mm:ss.SSS ZZ"), "2024-02-01 03:04:05.123 +00:00"
    )
    assert_equal(m.format("Y-YY-YYY-YYYY M-MM D-DD"), "Y-24--2024 2-02 1-01")
    assert_equal(m.format("H-HH-h-hh m-mm s-ss"), "3-03-3-03 4-04 5-05")
    assert_equal(
        m.format("S-SS-SSS-SSSS-SSSSS-SSSSSS"), "1-12-123-1234-12345-123456"
    )
    assert_equal(m.format("d-dd-ddd-dddd"), "4--Thu-Thursday")
    assert_equal(m.format("YYYY[Y] [[]MM[]][M]"), "2024Y [02]M")

    var m_tz = Morrow(2024, 2, 1, 3, 4, 5, 123456, TimeZone.from_utc("+05:30"))
    assert_equal(m_tz.format("ZZ"), "+05:30")

    var leap = Morrow(2024, 2, 29, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))
    assert_equal(leap.format("DDD-DDDD-W"), "60-060-2024-W09-4")
    assert_equal(leap.format("X-x"), "1709175845-1709175845123456")


def test_strftime() raises:
    var m = Morrow(2024, 2, 29, 3, 4, 5, 123456, TimeZone(19800, "IST"))
    assert_equal(
        m.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"),
        "2024-02-29 03:04:05.123456 +0530 IST",
    )
    assert_equal(
        m.strftime("%a %A %b %B %j %w %u %G-W%V"),
        "Thu Thursday Feb February 060 4 4 2024-W09",
    )
    assert_equal(
        m.strftime("%I:%M %p %% %F %T"), "03:04 AM % 2024-02-29 03:04:05"
    )


def test_ordinal_day_format_token() raises:
    assert_equal(Morrow(2024, 1, 1).format("Do"), "1st")
    assert_equal(Morrow(2024, 1, 2).format("Do"), "2nd")
    assert_equal(Morrow(2024, 1, 3).format("Do"), "3rd")
    assert_equal(Morrow(2024, 1, 4).format("Do"), "4th")
    assert_equal(Morrow(2024, 1, 11).format("Do"), "11th")
    assert_equal(Morrow(2024, 1, 12).format("Do"), "12th")
    assert_equal(Morrow(2024, 1, 13).format("Do"), "13th")
    assert_equal(Morrow(2024, 1, 21).format("Do"), "21st")
    assert_equal(Morrow(2024, 1, 22).format("Do"), "22nd")
    assert_equal(Morrow(2024, 1, 23).format("Do"), "23rd")
    assert_equal(Morrow(2024, 1, 31).format("Do"), "31st")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
