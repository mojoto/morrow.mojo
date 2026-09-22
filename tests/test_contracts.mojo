from std.testing import assert_equal, assert_true, assert_raises, TestSuite
from morrow import Morrow, TimeZone, TimeDelta


def test_constructor_year_limits() raises:
    for year in [-1, 0, 10000]:
        with assert_raises(contains="year"):
            _ = Morrow(year, 1, 1)
    assert_equal(Morrow(1, 1, 1).toordinal(), 1)
    assert_equal(Morrow(9999, 12, 31).toordinal(), 3652059)


def test_constructor_month_limits() raises:
    for month in [-1, 0, 13]:
        with assert_raises(contains="month"):
            _ = Morrow(2024, month, 1)


def test_constructor_day_limits() raises:
    for day in [-1, 0, 30, 31, 32]:
        with assert_raises(contains="day"):
            _ = Morrow(2024, 2, day)
    with assert_raises(contains="day"):
        _ = Morrow(2024, 4, 31)


def test_gregorian_century_leap_rules() raises:
    for year in [1600, 2000, 2400]:
        assert_equal(Morrow(year, 2, 29).shift(days=1).month, 3)
    for year in [1700, 1800, 1900, 2100]:
        with assert_raises(contains="day"):
            _ = Morrow(year, 2, 29)


def test_constructor_clock_limits() raises:
    for hour in [-1, 24]:
        with assert_raises(contains="hour"):
            _ = Morrow(2024, 1, 1, hour=hour)
    for value in [-1, 60]:
        with assert_raises(contains="minute"):
            _ = Morrow(2024, 1, 1, minute=value)
        with assert_raises(contains="second"):
            _ = Morrow(2024, 1, 1, second=value)


def test_constructor_microsecond_limits() raises:
    for value in [-1, 1000000]:
        with assert_raises(contains="microsecond"):
            _ = Morrow(2024, 1, 1, microsecond=value)


def test_constructor_offset_limits() raises:
    for offset in [-86400, 86400]:
        with assert_raises():
            _ = Morrow(2024, 1, 1, tz=TimeZone(offset))
    for offset in [-86399, 86399]:
        assert_equal(Morrow(2024, 1, 1, tz=TimeZone(offset)).tz.offset, offset)


def test_month_shift_across_years() raises:
    assert_true(Morrow(2024, 1, 31).shift(months=-1) == Morrow(2023, 12, 31))
    assert_true(Morrow(2024, 12, 31).shift(months=2) == Morrow(2025, 2, 28))
    assert_true(Morrow(2024, 2, 29).shift(years=1) == Morrow(2025, 2, 28))


def test_calendar_shift_argument_limits() raises:
    var dt = Morrow(2024, 1, 1)
    for value in [-9223372036854775807, 9223372036854775807]:
        with assert_raises():
            _ = dt.shift(years=value)
        with assert_raises():
            _ = dt.shift(months=value)
        with assert_raises():
            _ = dt.shift(quarters=value)
        with assert_raises():
            _ = dt.shift(weeks=value)
        with assert_raises():
            _ = dt.shift(days=value)


def test_elapsed_shift_argument_limits() raises:
    var dt = Morrow(2024, 1, 1)
    for value in [-9223372036854775807, 9223372036854775807]:
        with assert_raises():
            _ = dt.shift(hours=value)
        with assert_raises():
            _ = dt.shift(minutes=value)
        with assert_raises():
            _ = dt.shift(seconds=value)
        with assert_raises():
            _ = dt.shift(microseconds=value)


def test_nth_weekday_invalid_arguments() raises:
    var dt = Morrow(2024, 1, 1)
    for weekday in [-1, 7]:
        with assert_raises():
            _ = dt.shift_weekday(weekday)
    with assert_raises():
        _ = dt.shift_weekday(0, 0)
    with assert_raises():
        _ = dt.shift_weekday(0, 9223372036854775807)


def test_mixed_awareness_ordering() raises:
    var aware = Morrow(2024, 1, 1)
    var naive = aware.naive()
    assert_true(not (aware == naive))
    with assert_raises():
        _ = naive < aware
    with assert_raises():
        _ = aware <= naive
    with assert_raises():
        _ = naive > aware
    with assert_raises():
        _ = aware >= naive


def test_mixed_awareness_relative_operations() raises:
    var aware = Morrow(2024, 1, 1)
    var naive = aware.naive()
    with assert_raises():
        _ = naive - aware
    with assert_raises():
        _ = naive.humanize(aware)
    with assert_raises():
        _ = aware.is_between(naive, aware.shift(days=1))
    with assert_raises():
        _ = Morrow.range("day", naive, aware)


def test_equivalent_fixed_offset_instants() raises:
    var utc = Morrow(2024, 1, 1, 12)
    for seconds in [-86399, -19815, 0, 20700, 86399]:
        var other = utc.to(TimeZone(seconds))
        assert_true(other == utc)
        assert_true(other <= utc and other >= utc)
        assert_equal((other - utc).total_seconds(), 0.0)
        assert_equal(other.int_timestamp(), utc.int_timestamp())


def test_replace_preserves_wall_and_to_preserves_instant() raises:
    var utc = Morrow(2024, 1, 1, 12)
    var attached = utc.replace(tzinfo="+05:30")
    assert_equal(attached.hour, 12)
    assert_equal((utc - attached).total_seconds(), 19800.0)
    assert_true(utc.to("+05:30") == utc)
    assert_true(utc.naive().tz.is_none())


def test_negative_fractional_timestamp() raises:
    var dt = Morrow.utcfromtimestamp(-0.000001)
    assert_equal(dt.year, 1969)
    assert_equal(dt.second, 59)
    assert_equal(dt.microsecond, 999999)
    assert_true(dt.shift(microseconds=1) == Morrow(1970, 1, 1))


def test_span_bounds_at_microsecond_resolution() raises:
    var dt = Morrow(2024, 2, 29, 12)
    var closed = dt.span("day", bounds="[]")
    var open = dt.span("day", bounds="()")
    assert_true(closed.start == Morrow(2024, 2, 29))
    assert_true(closed.end == Morrow(2024, 3, 1))
    assert_true(open.start == closed.start.shift(microseconds=1))
    assert_true(open.end == closed.end.shift(microseconds=-1))


def test_naive_elapsed_arithmetic() raises:
    var dt = Morrow(2024, 2, 29, 23, 59, 59, 999999).naive()
    var next = dt + TimeDelta(microseconds=1)
    assert_true(next.tz.is_none())
    assert_equal(next.day, 1)
    assert_equal(next.month, 3)
    assert_true(next - TimeDelta(microseconds=1) == dt)


def test_calendar_overflow_raises() raises:
    with assert_raises():
        _ = Morrow.min() - TimeDelta(microseconds=1)
    with assert_raises():
        _ = Morrow.max() + TimeDelta(microseconds=1)
    with assert_raises():
        _ = Morrow.max().ceil("day")


def test_invalid_offset_text() raises:
    var invalid: List[String] = [
        "+99:00",
        "+01:99",
        "+01:01:99",
        "garbage",
        "🌙",
        "+0🌙",
    ]
    for text in invalid:
        with assert_raises():
            _ = TimeZone.from_utc(text)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
