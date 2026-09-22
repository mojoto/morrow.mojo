from std.testing import assert_equal, assert_true, assert_raises, TestSuite
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
    assert_equal(skipped.dst().total_seconds(), 3600.0)
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
    var before = Morrow(1969, 10, 26, 6) - TimeDelta(microseconds=1)
    var local = before.to("America/New_York")
    assert_equal(local.tz.offset, -14400)
    assert_equal(local.minute, 59)
    assert_equal(local.microsecond, 999999)
    assert_true(local.to("UTC") == before)


def test_gap_fold_offsets_and_dst() raises:
    var tz = TimeZone.from_name("America/New_York")
    var before = Morrow(2024, 3, 10, 2, 30, tz=tz, fold=0)
    var after = before.replace(fold=1)
    assert_true(before.imaginary() and after.imaginary())
    assert_equal(before.tz.offset, -18000)
    assert_equal(after.tz.offset, -14400)
    assert_equal(before.dst().total_seconds(), 0.0)
    assert_equal(after.dst().total_seconds(), 3600.0)
    assert_equal(before.to(tz).hour, 3)
    assert_equal(after.to(tz).hour, 1)


def test_southern_hemisphere_seasons() raises:
    var jan = Morrow(2024, 1, 15).to("Australia/Sydney")
    var jul = Morrow(2024, 7, 15).to("Australia/Sydney")
    assert_equal(jan.tz.offset, 39600)
    assert_equal(jul.tz.offset, 36000)
    assert_equal(jan.dst().total_seconds(), 3600.0)
    assert_equal(jul.dst().total_seconds(), 0.0)


def test_quarter_hour_named_offset() raises:
    var dt = Morrow(2024, 1, 1).to("Asia/Kathmandu")
    assert_equal(dt.hour, 5)
    assert_equal(dt.minute, 45)
    assert_equal(dt.tz.offset, 20700)
    assert_equal(dt.dst().total_seconds(), 0.0)


def test_timezone_label_does_not_attach_rules() raises:
    var fixed = Morrow(2024, 7, 1, tz=TimeZone(-18000, "America/New_York"))
    var named = Morrow(2024, 7, 1, tz=TimeZone.from_name("America/New_York"))
    assert_equal(fixed.tz.offset, -18000)
    assert_equal(named.tz.offset, -14400)
    assert_equal((fixed - named).total_seconds(), 3600.0)


def test_named_timezone_replace_recalculates_offset() raises:
    var summer = Morrow(
        2024, 7, 1, 12, tz=TimeZone.from_name("America/New_York")
    )
    var winter = summer.replace(month=1)
    assert_equal(winter.hour, 12)
    assert_equal(winter.tz.offset, -18000)
    assert_equal(summer.tz.offset, -14400)
    assert_true(not winter.ambiguous() and not winter.imaginary())


def test_mixed_calendar_and_elapsed_shift_order() raises:
    var start = Morrow(
        2024, 3, 9, 12, tz=TimeZone.from_name("America/New_York")
    )
    var mixed = start.shift(days=1, hours=2)
    assert_equal(mixed.hour, 14)
    assert_equal((mixed - start).total_seconds(), 25 * 3600.0)
    assert_true(start.shift(months=1).shift(months=-1) == start)


def test_spring_hour_range_skips_missing_hour() raises:
    var tz = TimeZone.from_name("America/New_York")
    var points = Morrow.range(
        "hour", Morrow(2024, 3, 10, tz=tz), Morrow(2024, 3, 10, 4, tz=tz)
    )
    var hours: List[Int] = [0, 1, 3, 4]
    assert_equal(len(points), len(hours))
    for i in range(len(points)):
        assert_equal(points[i].hour, hours[i])
        assert_true(not points[i].imaginary())
        if i > 0:
            assert_equal((points[i] - points[i - 1]).total_seconds(), 3600.0)


def test_fall_hour_range_preserves_both_folds() raises:
    var tz = TimeZone.from_name("America/New_York")
    var points = Morrow.range(
        "hour", Morrow(2024, 11, 3, tz=tz), Morrow(2024, 11, 3, 3, tz=tz)
    )
    var hours: List[Int] = [0, 1, 1, 2, 3]
    assert_equal(len(points), len(hours))
    for i in range(len(points)):
        assert_equal(points[i].hour, hours[i])
        if i > 0:
            assert_equal((points[i] - points[i - 1]).total_seconds(), 3600.0)
    assert_equal(points[1].fold(), 0)
    assert_equal(points[2].fold(), 1)


def test_local_timestamp_preserves_fold_instant() raises:
    for timestamp in [1730611800, 1730615400, -1]:
        var dt = Morrow.fromtimestamp(timestamp)
        assert_equal(dt.int_timestamp(), timestamp)
        assert_true(dt.to("UTC") == Morrow.utcfromtimestamp(timestamp))


def test_named_timezone_validation_errors() raises:
    with assert_raises(contains="unknown IANA timezone"):
        _ = TimeZone.from_name("Unknown/Nowhere")
    with assert_raises(contains="ASCII"):
        _ = TimeZone.from_name("Asia/上海")
    with assert_raises(contains="fold"):
        _ = Morrow(2024, 1, 1, fold=-2)
    with assert_raises(contains="fold"):
        _ = Morrow(2024, 1, 1, fold=2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
