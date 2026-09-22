from std.testing import assert_equal, assert_true, TestSuite
from morrow import Morrow, TimeZone, TimeDelta


def test_zone_conversion_and_history() raises:
    var utc = Morrow(2024, 7, 1)
    var ny = utc.to("America/New_York")
    assert_equal(ny.hour, 20)
    assert_equal(ny.day, 30)
    assert_equal(ny.tz.offset, -14400)
    assert_equal(ny.dst().total_seconds(), 3600.0)
    assert_true(ny == utc)
    assert_equal(Morrow(2024, 1, 1).to("America/New_York").tz.offset, -18000)
    assert_equal(Morrow(1900, 1, 1).to("Asia/Shanghai").tz.offset, 29143)
    assert_equal(Morrow(2050, 7, 1).to("America/New_York").tz.offset, -14400)
    var parsed = Morrow.get(
        "2024-07-01 12:00 America/New_York", "YYYY-MM-DD HH:mm ZZZ"
    )
    assert_equal(parsed.tz.offset, -14400)
    assert_equal(parsed.hour, 12)
    assert_equal(Morrow.get("2024-07-01 GMT0", "YYYY-MM-DD ZZZ").tz.offset, 0)
    assert_true(
        Morrow.strptime(
            "2024-07-01 12:00 America/New_York", "%Y-%m-%d %H:%M %Z"
        )
        == parsed
    )
    var rejected = False
    try:
        _ = TimeZone.from_name("Invalid/Zone")
    except e:
        rejected = True
    assert_true(rejected)


def test_repeated_and_missing_times() raises:
    var tz = TimeZone.from_name("America/New_York")
    var first = Morrow(2024, 11, 3, 1, 30, tz=tz, fold=0)
    var second = first.replace(fold=1)
    assert_true(first.ambiguous())
    assert_true(second.ambiguous())
    assert_equal((second - first).total_seconds(), 3600.0)
    assert_equal(first.fold(), 0)
    assert_equal(second.fold(), 1)
    assert_equal(second.to("UTC").to(tz).fold(), 1)
    assert_true(second.to("UTC").to(tz) == second)
    var missing = Morrow(2024, 3, 10, 2, 30, tz=tz)
    assert_true(missing.imaginary())
    assert_equal(missing.to(tz).hour, 3)
    assert_true(not missing.to(tz).imaginary())
    var previous = Morrow(2024, 3, 9, 2, 30, tz=tz)
    assert_equal(previous.shift(days=1).hour, 3)
    assert_true(previous.shift(days=1, check_imaginary=False).imaginary())


def test_calendar_and_elapsed_time() raises:
    var tz = TimeZone.from_name("America/New_York")
    var before = Morrow(2024, 3, 9, 12, tz=tz)
    var tomorrow = before.shift(days=1)
    assert_equal(tomorrow.hour, 12)
    assert_equal((tomorrow - before).total_seconds(), 23 * 3600.0)
    assert_equal(before.shift(hours=24).hour, 13)
    assert_equal((before + TimeDelta(days=1)).hour, 13)
    var span = Morrow(2024, 3, 10, 12, tz=tz).span("day")
    assert_equal(
        (span.end.shift(microseconds=1) - span.start).total_seconds(),
        23 * 3600.0,
    )
    var fall = Morrow(2024, 11, 3, 12, tz=tz).span("day")
    assert_equal(
        (fall.end.shift(microseconds=1) - fall.start).total_seconds(),
        25 * 3600.0,
    )
    var count = 0
    for point in Morrow.iter_range(
        "hour", Morrow(2024, 11, 3, tz=tz), Morrow(2024, 11, 3, 3, tz=tz)
    ):
        count += 1
        assert_true(count <= 5)
    assert_equal(count, 5)


def test_unusual_transitions_and_invalid_names() raises:
    var lord_howe = TimeZone.from_name("Australia/Lord_Howe")
    var early = Morrow(2024, 4, 7, 1, 45, tz=lord_howe, fold=0)
    var late = early.replace(fold=1)
    assert_true(early.ambiguous())
    assert_equal((late - early).total_seconds(), 1800.0)
    var apia = TimeZone.from_name("Pacific/Apia")
    var skipped = Morrow(2011, 12, 30, 12, tz=apia)
    assert_true(skipped.imaginary())
    assert_equal(skipped.to(apia).day, 31)
    var invalid_names: List[String] = ["", "未知/地区", "Invalid/Zone"]
    for name in invalid_names:
        var rejected = False
        try:
            _ = TimeZone.from_name(name)
        except e:
            rejected = True
        assert_true(rejected)
    var rejected = False
    try:
        _ = early.replace(fold=2)
    except e:
        rejected = True
    assert_true(rejected)


def test_aware_calendar_limits() raises:
    var earliest = Morrow(1, 1, 1, tz=TimeZone.from_utc("+14:00"))
    var latest = Morrow(
        9999, 12, 31, 23, 59, 59, 999999, tz=TimeZone.from_utc("-12:00")
    )
    assert_true(earliest + TimeDelta() == earliest)
    assert_true(latest + TimeDelta() == latest)
    assert_equal(earliest.shift(hours=1).hour, 1)
    assert_equal(latest.shift(hours=-1).hour, 22)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
