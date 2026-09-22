from std.testing import assert_equal

from morrow import Morrow


def main() raises:
    var value = Morrow.get("2026-01-01T03:04:05Z")
    assert_equal(
        value.format("YYYY-MM-DD HH:mm:ss ZZ"), "2026-01-01 03:04:05 +00:00"
    )
    assert_equal(Morrow(2024, 7, 1).to("America/New_York").tz.offset, -14400)
    assert_equal(Morrow(2024, 1, 1).format("MMMM", locale="zh-CN"), "一月")
