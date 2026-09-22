"""Reproducible property checks using the standard library's seeded generator."""
from std.testing import assert_equal, assert_true, TestSuite
from std.testing.prop import Rng
from morrow import Morrow, TimeZone, TimeDelta

comptime SAMPLES = 1000


def test_ordinal_round_trip_property() raises:
    var rng = Rng(seed=20260922)
    for _ in range(SAMPLES):
        var ordinal = rng.rand_int(min=1, max=3652059)
        var dt = Morrow.fromordinal(ordinal)
        assert_equal(dt.toordinal(), ordinal, "ordinal=" + String(ordinal))
        assert_true(Morrow.fromisoformat(dt.isoformat()) == dt)


def test_timestamp_round_trip_property() raises:
    var rng = Rng(seed=20260923)
    for _ in range(SAMPLES):
        var stamp = rng.rand_int(min=-62135596800, max=32503737600)
        var dt = Morrow.utcfromtimestamp(stamp)
        assert_equal(dt.int_timestamp(), stamp, "timestamp=" + String(stamp))
        assert_true(Morrow.fromisoformat(dt.isoformat()) == dt)


def test_duration_normalization_and_inverse_property() raises:
    var rng = Rng(seed=20260924)
    for _ in range(SAMPLES):
        var micros = rng.rand_int(min=-1000000000000, max=1000000000000)
        var delta = TimeDelta(microseconds=micros)
        assert_true(delta.seconds >= 0 and delta.seconds < 86400)
        assert_true(delta.microseconds >= 0 and delta.microseconds < 1000000)
        assert_equal(
            (delta.days * 86400 + delta.seconds) * 1000000 + delta.microseconds,
            micros,
        )
        assert_true(delta + (-delta) == TimeDelta())
        var base = Morrow(2024, 6, 15)
        assert_true((base + delta) - delta == base)


def test_fixed_offset_conversion_property() raises:
    var rng = Rng(seed=20260925)
    for _ in range(SAMPLES):
        var stamp = rng.rand_int(min=-2208988800, max=4102444800)
        var offset = rng.rand_int(min=-86399, max=86399)
        var utc = Morrow.utcfromtimestamp(stamp)
        var local = utc.to(TimeZone(offset))
        assert_equal(local.int_timestamp(), stamp)
        assert_true(local.to("UTC") == utc)
        assert_equal(TimeZone.from_utc(local.tz.format()).offset, offset)


def test_localized_date_round_trip_property() raises:
    var rng = Rng(seed=20260926)
    var locales: List[String] = ["en", "zh-CN", "zh-TW"]
    for _ in range(SAMPLES):
        var ordinal = rng.rand_int(min=1, max=3652059)
        var hour = rng.rand_int(min=0, max=23)
        var dt = Morrow.fromordinal(ordinal).replace(hour=hour)
        var locale = locales[rng.rand_int(min=0, max=2)]
        var fmt = "YYYY MMMM DD dddd A hh:mm:ss"
        assert_true(
            Morrow.get(dt.format(fmt, locale=locale), fmt, locale=locale) == dt,
            "ordinal=" + String(ordinal) + " locale=" + locale,
        )


def test_iana_instant_round_trip_property() raises:
    var rng = Rng(seed=20260927)
    var names: List[String] = [
        "America/New_York",
        "Europe/Berlin",
        "Australia/Lord_Howe",
        "Pacific/Apia",
        "Asia/Kathmandu",
        "Asia/Shanghai",
    ]
    for _ in range(SAMPLES):
        var stamp = rng.rand_int(min=-2208988800, max=4102444800)
        var micros = rng.rand_int(min=0, max=999999)
        var utc = Morrow.utcfromtimestamp(stamp).replace(microsecond=micros)
        var name = names[rng.rand_int(min=0, max=5)]
        var local = utc.to(name)
        assert_true(
            local.to("UTC") == utc,
            "timestamp=" + String(stamp) + " zone=" + name,
        )
        assert_equal(local.microsecond, micros)
        assert_true(not local.imaginary())
        assert_true(
            (local + TimeDelta(seconds=1)) - TimeDelta(seconds=1) == local
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
