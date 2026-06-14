from std.testing import assert_equal, assert_true, TestSuite

from morrow._libc import c_localtime, CTm
from morrow import Morrow
from morrow import TimeZone


def matches_tm(dt: Morrow, tm: CTm) -> Bool:
    return (
        dt.year == Int(tm.tm_year) + 1900
        and dt.month == Int(tm.tm_mon) + 1
        and dt.day == Int(tm.tm_mday)
        and dt.hour == Int(tm.tm_hour)
        and dt.minute == Int(tm.tm_min)
        and dt.second == Int(tm.tm_sec)
    )


def assert_tm_equal(dt: Morrow, tm: CTm) raises:
    assert_true(matches_tm(dt, tm))


def test_now() raises:
    var result = Morrow.now()
    assert_true(result.year >= 2020)
    assert_true(result.month >= 1 and result.month <= 12)
    assert_true(result.day >= 1 and result.day <= 31)
    assert_true(result.hour >= 0 and result.hour <= 23)
    assert_true(result.minute >= 0 and result.minute <= 59)
    assert_true(result.second >= 0 and result.second <= 60)
    assert_true(result.microsecond >= 0 and result.microsecond < 1000000)


def test_utcnow() raises:
    var result = Morrow.utcnow()
    assert_true(result.year >= 2020)
    assert_true(result.month >= 1 and result.month <= 12)
    assert_true(result.day >= 1 and result.day <= 31)
    assert_true(result.hour >= 0 and result.hour <= 23)
    assert_true(result.minute >= 0 and result.minute <= 59)
    assert_true(result.second >= 0 and result.second <= 60)
    assert_equal(result.tz.offset, 0)
    assert_true(result.microsecond >= 0 and result.microsecond < 1000000)


def test_fromtimestamp() raises:
    var timestamp = 1700000000
    var result = Morrow.fromtimestamp(Float64(timestamp))
    assert_tm_equal(result, c_localtime(timestamp))


def test_utcfromtimestamp() raises:
    var result = Morrow.utcfromtimestamp(1700000000.0)
    assert_equal(result.year, 2023)
    assert_equal(result.month, 11)
    assert_equal(result.day, 14)
    assert_equal(result.hour, 22)
    assert_equal(result.minute, 13)
    assert_equal(result.second, 20)
    assert_equal(result.tz.offset, 0)


def test_iso_format() raises:
    var d0 = Morrow(2023, 10, 1, 0, 0, 0, 1234)
    assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234")
    assert_equal(d0.isoformat(timespec="seconds"), "2023-10-01T00:00:00")
    assert_equal(
        d0.isoformat(timespec="milliseconds"), "2023-10-01T00:00:00.001"
    )

    var d1 = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Beijing"))
    assert_equal(d1.isoformat(timespec="seconds"), "2023-10-01T00:00:00+08:00")


def test_strptime() raises:
    var m = Morrow.strptime(
        "20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone.none()
    )
    assert_equal(String(m), "2023-01-20T15:49:10.000000+00:00")

    m = Morrow.strptime("2023-10-18 15:49:10 +0800", "%Y-%m-%d %H:%M:%S %z")
    assert_equal(String(m), "2023-10-18T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", "+09:00")
    assert_equal(String(m), "2023-10-18T15:49:10.000000+09:00")


def test_ordinal() raises:
    var m = Morrow(2023, 10, 1)
    var o = m.toordinal()
    assert_equal(o, 738794)

    var m2 = Morrow.fromordinal(o)
    assert_equal(m2.year, 2023)
    assert_equal(m.month, 10)
    assert_equal(m.day, 1)

    var leap_day = Morrow.fromordinal(Morrow(2024, 2, 29).toordinal())
    assert_equal(String(leap_day), "2024-02-29T00:00:00.000000")


def test_sub() raises:
    var result = Morrow(2023, 10, 1, 10, 0, 0, 1) - Morrow(
        2023, 10, 1, 10, 0, 0
    )
    assert_equal(result.microseconds, 1)
    assert_equal(String(result), "0:00:00000001")

    result = Morrow(2023, 10, 1, 10, 0, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 1)
    assert_equal(String(result), "0:00:01")

    result = Morrow(2023, 10, 1, 10, 1, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.seconds, 60)
    assert_equal(String(result), "0:01:00")

    result = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 1)
    assert_equal(String(result), "1 day, 0:00:00")

    result = Morrow(2023, 10, 3, 10, 1, 1) - Morrow(2023, 10, 1, 10, 0, 0)
    assert_equal(result.days, 2)
    assert_equal(String(result), "2 days, 0:01:01")


def test_replace() raises:
    var tz = TimeZone.from_utc("+05:30")
    var m = Morrow(2024, 2, 29, 3, 4, 5, 123456, tz)
    var replaced = m.replace(year=2025, month=12, day=31, hour=23, minute=59)

    assert_equal(String(replaced), "2025-12-31T23:59:05.123456+05:30")
    assert_equal(replaced.tz.offset, tz.offset)


def test_shift_months_clamps_to_last_day() raises:
    var jan31 = Morrow(2024, 1, 31, 3, 4, 5, 123456)
    var feb = jan31.shift(months=1)
    assert_equal(String(feb), "2024-02-29T03:04:05.123456")

    var mar = feb.shift(years=1)
    assert_equal(String(mar), "2025-02-28T03:04:05.123456")


def test_shift_time_units() raises:
    var m = Morrow(2024, 2, 28, 23, 59, 59, 999999)
    var shifted = m.shift(microseconds=1)
    assert_equal(String(shifted), "2024-02-29T00:00:00.000000")

    shifted = shifted.shift(weeks=1, days=-1, hours=-1, minutes=-30)
    assert_equal(String(shifted), "2024-03-05T22:30:00.000000")


def test_floor_ceil_and_span() raises:
    var tz = TimeZone.from_utc("+05:30")
    var m = Morrow(2024, 2, 29, 13, 14, 15, 123456, tz)

    assert_equal(String(m.floor("hour")), "2024-02-29T13:00:00.000000+05:30")
    assert_equal(String(m.ceil("hour")), "2024-02-29T13:59:59.999999+05:30")

    var day_span = m.span("day")
    assert_equal(String(day_span.start), "2024-02-29T00:00:00.000000+05:30")
    assert_equal(String(day_span.end), "2024-02-29T23:59:59.999999+05:30")

    var two_days = m.span("day", count=2)
    assert_equal(String(two_days.start), "2024-02-29T00:00:00.000000+05:30")
    assert_equal(String(two_days.end), "2024-03-01T23:59:59.999999+05:30")

    var closed = m.span("day", bounds="[]")
    assert_equal(String(closed.start), "2024-02-29T00:00:00.000000+05:30")
    assert_equal(String(closed.end), "2024-03-01T00:00:00.000000+05:30")

    var open = m.span("day", bounds="()")
    assert_equal(String(open.start), "2024-02-29T00:00:00.000001+05:30")
    assert_equal(String(open.end), "2024-02-29T23:59:59.999999+05:30")


def test_week_and_quarter_spans() raises:
    var m = Morrow(2024, 2, 29, 13)

    var iso_week = m.span("week")
    assert_equal(String(iso_week.start), "2024-02-26T00:00:00.000000")
    assert_equal(String(iso_week.end), "2024-03-03T23:59:59.999999")

    var sunday_week = m.span("week", week_start=7)
    assert_equal(String(sunday_week.start), "2024-02-25T00:00:00.000000")
    assert_equal(String(sunday_week.end), "2024-03-02T23:59:59.999999")

    var quarter = Morrow(2024, 5, 17, 8).span("quarter")
    assert_equal(String(quarter.start), "2024-04-01T00:00:00.000000")
    assert_equal(String(quarter.end), "2024-06-30T23:59:59.999999")

    var month = Morrow(2024, 2, 17, 8).span("month")
    assert_equal(String(month.start), "2024-02-01T00:00:00.000000")
    assert_equal(String(month.end), "2024-02-29T23:59:59.999999")

    var instant = m.span("microsecond")
    assert_equal(String(instant.start), "2024-02-29T13:00:00.000000")
    assert_equal(String(instant.end), "2024-02-29T13:00:00.000000")


def test_timestamp_and_timezone_conversion() raises:
    var utc = TimeZone.from_utc("UTC")
    var epoch = Morrow(1970, 1, 1, 0, 0, 0, 0, utc)
    assert_equal(epoch.timestamp(), 0.0)
    assert_equal(epoch.float_timestamp(), 0.0)

    var beijing_epoch = Morrow(
        1970, 1, 1, 8, 0, 0, 500000, TimeZone.from_utc("+08:00")
    )
    assert_equal(beijing_epoch.timestamp(), 0.5)

    var before_epoch = Morrow(1969, 12, 31, 23, 59, 59, 250000, utc)
    assert_equal(before_epoch.timestamp(), -0.75)

    var base = Morrow(2024, 2, 29, 16, 30, 0, 123456, utc)
    var shanghai = base.to("+08:00")
    assert_equal(String(shanghai), "2024-03-01T00:30:00.123456+08:00")
    assert_equal(String(shanghai.to("UTC")), "2024-02-29T16:30:00.123456+00:00")

    var fixed = base.to(TimeZone.from_utc("-05:00"))
    assert_equal(String(fixed), "2024-02-29T11:30:00.123456-05:00")


def test_clone_weekday_and_naive() raises:
    var m = Morrow(2024, 2, 29, 3, 4, 5, 6, TimeZone.from_utc("+05:30"))

    assert_equal(String(m.clone()), "2024-02-29T03:04:05.000006+05:30")
    assert_equal(m.weekday(), 3)
    assert_equal(m.isoweekday(), 4)
    assert_equal(String(m.naive()), "2024-02-29T03:04:05.000006")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
