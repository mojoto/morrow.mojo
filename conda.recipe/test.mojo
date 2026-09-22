from std.testing import assert_equal, assert_true, assert_raises
from morrow import Morrow, TimeZone, TimeDelta, FORMAT_RFC3339_STRICT


def main() raises:
    var value = Morrow.get("2026-01-01T03:04:05Z")
    assert_equal(
        value.format(FORMAT_RFC3339_STRICT), "2026-01-01T03:04:05+00:00"
    )
    assert_true(Morrow.fromisoformat(value.isoformat()) == value)
    assert_true((value + TimeDelta(days=1)) - TimeDelta(days=1) == value)
    var ny = TimeZone.from_name("America/New_York")
    var early = Morrow(2024, 11, 3, 1, 30, tz=ny)
    var late = early.replace(fold=1)
    assert_true(early.ambiguous())
    assert_equal((late - early).total_seconds(), 3600.0)
    assert_equal(late.to("UTC").to(ny).fold(), 1)
    var text = value.format("YYYY MMMM DD", locale="zh-CN")
    assert_true(
        Morrow.get(text, "YYYY MMMM DD", locale="zh-CN") == value.floor("day")
    )
    assert_equal(value.shift(hours=2).humanize(value, locale="zh-TW"), "2小時後")
    assert_true(
        value.dehumanize("2小时前", locale="zh-CN") == value.shift(hours=-2)
    )
    var count = 0
    for point in Morrow.iter_range("day", value, limit=3):
        assert_true(point == value.shift(days=count))
        count += 1
    assert_equal(count, 3)
    with assert_raises():
        _ = Morrow(2023, 2, 29)
