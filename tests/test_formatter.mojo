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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
