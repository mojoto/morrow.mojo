from std.collections import List
from std.testing import assert_equal, assert_true, TestSuite

from morrow._libc import c_localtime, CTm
from morrow import Morrow, MorrowIsoCalendar, TimeDelta
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


def assert_get_raises(date_str: String, fmt: String) raises:
    try:
        _ = Morrow.get(date_str, fmt)
    except e:
        return
    assert_true(False)


def assert_string_get_raises(date_str: String) raises:
    try:
        _ = Morrow.get(date_str)
    except e:
        return
    assert_true(False)


def assert_component_get_raises(year: Int, month: Int, day: Int) raises:
    try:
        _ = Morrow.get(year, month, day)
    except e:
        return
    assert_true(False)


def assert_isoformat_sep_raises(sep: String) raises:
    try:
        _ = Morrow(2024, 2, 29, 3, 4, 5).isoformat(sep=sep)
    except e:
        return
    assert_true(False)


def assert_replace_second_raises(second: Int) raises:
    try:
        _ = Morrow(2024, 2, 29, 3, 4, 5).replace(second=second)
    except e:
        return
    assert_true(False)


def assert_replace_year_raises(year: Int) raises:
    try:
        _ = Morrow(2024, 1, 1).replace(year=year)
    except e:
        return
    assert_true(False)


def assert_strptime_raises(date_str: String, fmt: String) raises:
    try:
        _ = Morrow.strptime(date_str, fmt)
    except e:
        return
    assert_true(False)


def assert_fromordinal_raises(ordinal: Int) raises:
    try:
        _ = Morrow.fromordinal(ordinal)
    except e:
        return
    assert_true(False)


def assert_int_get_raises(timestamp: Int) raises:
    try:
        _ = Morrow.get(timestamp)
    except e:
        return
    assert_true(False)


def assert_humanize_granularity_raises(
    value: Morrow, other: Morrow, granularity: String
) raises:
    try:
        _ = value.humanize(other, granularity=granularity)
    except e:
        return
    assert_true(False)


def assert_humanize_granularity_raises(
    value: Morrow, other: Morrow, granularity: List[String]
) raises:
    try:
        _ = value.humanize(other, granularity=granularity)
    except e:
        return
    assert_true(False)


def assert_dehumanize_raises(value: Morrow, input_string: String) raises:
    try:
        _ = value.dehumanize(input_string)
    except e:
        return
    assert_true(False)


def assert_shift_weekday_raises(value: Morrow, weekday: Int) raises:
    try:
        _ = value.shift(weekday=weekday)
    except e:
        return
    assert_true(False)


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
    var result = Morrow.fromtimestamp(timestamp)
    assert_tm_equal(result, c_localtime(timestamp))


def test_utcfromtimestamp() raises:
    var result = Morrow.utcfromtimestamp(1700000000)
    assert_equal(result.year, 2023)
    assert_equal(result.month, 11)
    assert_equal(result.day, 14)
    assert_equal(result.hour, 22)
    assert_equal(result.minute, 13)
    assert_equal(result.second, 20)
    assert_equal(result.tz.offset, 0)

    var millisecond_result = Morrow.utcfromtimestamp(1709175845123)
    assert_equal(String(millisecond_result), "2024-02-29T03:04:05.123000+00:00")

    var microsecond_result = Morrow.utcfromtimestamp(1709175845123456)
    assert_equal(String(microsecond_result), "2024-02-29T03:04:05.123456+00:00")


def test_iso_format() raises:
    var d0 = Morrow(2023, 10, 1, 0, 0, 0, 1234)
    assert_equal(d0.isoformat(), "2023-10-01T00:00:00.001234")
    assert_equal(d0.isoformat(timespec="seconds"), "2023-10-01T00:00:00")
    assert_equal(
        d0.isoformat(timespec="milliseconds"), "2023-10-01T00:00:00.001"
    )

    var d1 = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, "Beijing"))
    assert_equal(d1.isoformat(timespec="seconds"), "2023-10-01T00:00:00+08:00")

    var whole_second = Morrow(2024, 2, 29, 3, 4, 5)
    assert_equal(whole_second.isoformat(), "2024-02-29T03:04:05")
    assert_equal(
        whole_second.isoformat(timespec="microseconds"),
        "2024-02-29T03:04:05.000000",
    )

    var whole_second_tz = Morrow(
        2024, 2, 29, 3, 4, 5, tz=TimeZone.from_utc("UTC")
    )
    assert_equal(whole_second_tz.isoformat(), "2024-02-29T03:04:05+00:00")
    assert_equal(
        whole_second_tz.isoformat(sep=" "), "2024-02-29 03:04:05+00:00"
    )
    assert_isoformat_sep_raises("")
    assert_isoformat_sep_raises("xx")


def test_strptime() raises:
    var m = Morrow.strptime(
        "20-01-2023 15:49:10", "%d-%m-%Y %H:%M:%S", TimeZone.none()
    )
    assert_equal(String(m), "2023-01-20T15:49:10.000000+00:00")

    m = Morrow.strptime("2023-10-18 15:49:10 +0800", "%Y-%m-%d %H:%M:%S %z")
    assert_equal(String(m), "2023-10-18T15:49:10.000000+08:00")

    m = Morrow.strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", "+09:00")
    assert_equal(String(m), "2023-10-18T15:49:10.000000+09:00")
    var local_tz = TimeZone.local()
    m = Morrow.strptime("2023-10-18 15:49:10", "%Y-%m-%d %H:%M:%S", "local")
    assert_equal(m.tz.offset, local_tz.offset)
    assert_equal(m.tz.name, "local")
    assert_equal(m.hour, 15)
    assert_strptime_raises("2024-02-29 23:59:60", "%Y-%m-%d %H:%M:%S")
    assert_strptime_raises("2024-02-29abc", "%Y-%m-%d")
    assert_strptime_raises("2024-02-29 24:00", "%Y-%m-%d %H:%M")


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

    var min_ordinal = Morrow.fromordinal(1)
    assert_equal(String(min_ordinal), "0001-01-01T00:00:00.000000")

    var max_ordinal = Morrow.fromordinal(3652059)
    assert_equal(String(max_ordinal), "9999-12-31T00:00:00.000000")

    assert_fromordinal_raises(0)
    assert_fromordinal_raises(3652060)


def test_iso_calendar_creation() raises:
    var sunday = Morrow.fromisocalendar(2013, 18, 7)
    assert_equal(String(sunday), "2013-05-05T00:00:00.000000+00:00")

    var iso = MorrowIsoCalendar(2020, 53, 7)
    assert_equal(String(Morrow.get(iso)), "2021-01-03T00:00:00.000000+00:00")


def test_sub() raises:
    var result = Morrow(2023, 10, 1, 10, 0, 0, 1) - Morrow(
        2023, 10, 1, 10, 0, 0
    )
    assert_equal(result.microseconds, 1)
    assert_equal(String(result), "0:00:00.000001")

    result = Morrow(2023, 10, 1, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0, 1)
    assert_equal(String(result), "-1 day, 23:59:59.999999")

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

    var utc = Morrow(2024, 2, 29, 16, 30, 0, 123456, TimeZone.from_utc("UTC"))
    var shanghai = Morrow(
        2024, 3, 1, 0, 30, 0, 123456, TimeZone.from_utc("+08:00")
    )
    result = shanghai - utc
    assert_equal(result.days, 0)
    assert_equal(result.seconds, 0)
    assert_equal(result.microseconds, 0)

    var later_shanghai = Morrow(
        2024, 3, 1, 0, 30, 1, 123457, TimeZone.from_utc("+08:00")
    )
    result = later_shanghai - utc
    assert_equal(result.days, 0)
    assert_equal(result.seconds, 1)
    assert_equal(result.microseconds, 1)

    result = utc - later_shanghai
    assert_equal(result.days, -1)
    assert_equal(result.seconds, 86398)
    assert_equal(result.microseconds, 999999)


def test_timedelta_arithmetic() raises:
    var base = Morrow(
        2024, 2, 28, 23, 59, 59, 999999, TimeZone.from_utc("+05:30")
    )
    var delta = TimeDelta(days=1, seconds=2, microseconds=3)

    var added = base + delta
    assert_equal(String(added), "2024-03-01T00:00:02.000002+05:30")

    var reverse_added = delta + base
    assert_equal(String(reverse_added), "2024-03-01T00:00:02.000002+05:30")

    var subtracted = base - delta
    assert_equal(String(subtracted), "2024-02-27T23:59:57.999996+05:30")

    var borrowed = Morrow(
        2024, 3, 1, 0, 0, 0, 0, TimeZone.from_utc("UTC")
    ) - TimeDelta(microseconds=1)
    assert_equal(String(borrowed), "2024-02-29T23:59:59.999999+00:00")

    var diff = added - base
    assert_equal(diff.days, 1)
    assert_equal(diff.seconds, 2)
    assert_equal(diff.microseconds, 3)


def test_replace() raises:
    var tz = TimeZone.from_utc("+05:30")
    var m = Morrow(2024, 2, 29, 3, 4, 5, 123456, tz)
    var replaced = m.replace(year=2025, month=12, day=31, hour=23, minute=59)

    assert_equal(String(replaced), "2025-12-31T23:59:05.123456+05:30")
    assert_equal(replaced.tz.offset, tz.offset)

    var replaced_tz = m.replace(tzinfo=TimeZone.from_utc("+08:00"))
    assert_equal(String(replaced_tz), "2024-02-29T03:04:05.123456+08:00")

    replaced_tz = m.replace(tzinfo="UTC")
    assert_equal(String(replaced_tz), "2024-02-29T03:04:05.123456+00:00")

    var replaced_fields_tz = m.replace(
        year=2025, month=12, day=31, tzinfo=TimeZone.from_utc("UTC")
    )
    assert_equal(String(replaced_fields_tz), "2025-12-31T03:04:05.123456+00:00")

    var replaced_fields_tz_str = m.replace(hour=23, minute=59, tzinfo="-03:00")
    assert_equal(
        String(replaced_fields_tz_str), "2024-02-29T23:59:05.123456-03:00"
    )

    var local_tz = TimeZone.local()
    var replaced_local = m.replace(tzinfo="local")
    assert_equal(replaced_local.tz.offset, local_tz.offset)
    assert_equal(replaced_local.tz.name, "local")
    assert_equal(replaced_local.hour, 3)

    assert_replace_year_raises(0)
    assert_replace_year_raises(10000)
    assert_replace_second_raises(60)


def test_shift_months_clamps_to_last_day() raises:
    var jan31 = Morrow(2024, 1, 31, 3, 4, 5, 123456)
    var feb = jan31.shift(months=1)
    assert_equal(String(feb), "2024-02-29T03:04:05.123456")

    var mar = feb.shift(years=1)
    assert_equal(String(mar), "2025-02-28T03:04:05.123456")

    var quarter = jan31.shift(quarters=1)
    assert_equal(String(quarter), "2024-04-30T03:04:05.123456")

    var previous_quarter = jan31.shift(quarters=-1)
    assert_equal(String(previous_quarter), "2023-10-31T03:04:05.123456")


def test_shift_time_units() raises:
    var m = Morrow(2024, 2, 28, 23, 59, 59, 999999)
    var shifted = m.shift(microseconds=1)
    assert_equal(String(shifted), "2024-02-29T00:00:00.000000")

    shifted = shifted.shift(weeks=1, days=-1, hours=-1, minutes=-30)
    assert_equal(String(shifted), "2024-03-05T22:30:00.000000")


def test_shift_weekday() raises:
    var saturday = Morrow(
        2013, 5, 11, 22, 27, 34, 787885, TimeZone.from_utc("UTC")
    )

    assert_equal(
        String(saturday.shift(weekday=5)), "2013-05-11T22:27:34.787885+00:00"
    )
    assert_equal(
        String(saturday.shift(weekday=0)), "2013-05-13T22:27:34.787885+00:00"
    )
    assert_equal(
        String(saturday.shift(weekday=6)), "2013-05-12T22:27:34.787885+00:00"
    )
    assert_equal(
        String(saturday.shift(weekday=-1)), "2013-05-12T22:27:34.787885+00:00"
    )
    assert_equal(
        String(saturday.shift(weekday=-2)), "2013-05-11T22:27:34.787885+00:00"
    )
    assert_equal(
        String(saturday.shift(weekday=-7)), "2013-05-13T22:27:34.787885+00:00"
    )
    assert_shift_weekday_raises(saturday, -8)


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

    var exact = m.span("hour", count=2, exact=True)
    assert_equal(String(exact.start), "2024-02-29T13:14:15.123456+05:30")
    assert_equal(String(exact.end), "2024-02-29T15:14:15.123455+05:30")

    var zero_count = m.span("hour", count=0)
    assert_equal(String(zero_count.start), "2024-02-29T13:00:00.000000+05:30")
    assert_equal(String(zero_count.end), "2024-02-29T12:59:59.999999+05:30")

    var negative_count = m.span("hour", count=-1)
    assert_equal(
        String(negative_count.start), "2024-02-29T13:00:00.000000+05:30"
    )
    assert_equal(String(negative_count.end), "2024-02-29T11:59:59.999999+05:30")


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
    assert_equal(before_epoch.int_timestamp(), 0)

    var one_microsecond_before_epoch = Morrow(
        1969, 12, 31, 23, 59, 59, 999999, utc
    )
    assert_equal(one_microsecond_before_epoch.timestamp(), -0.000001)
    assert_equal(one_microsecond_before_epoch.int_timestamp(), 0)

    var base = Morrow(2024, 2, 29, 16, 30, 0, 123456, utc)
    var shanghai = base.to("+08:00")
    assert_equal(String(shanghai), "2024-03-01T00:30:00.123456+08:00")
    assert_equal(String(shanghai.to("UTC")), "2024-02-29T16:30:00.123456+00:00")

    var fixed = base.to(TimeZone.from_utc("-05:00"))
    assert_equal(String(fixed), "2024-02-29T11:30:00.123456-05:00")


def test_datetime_interface_aliases() raises:
    var m = Morrow(2024, 2, 29, 16, 30, 0, 123456, TimeZone.from_utc("UTC"))

    assert_equal(String(m.datetime()), String(m))
    assert_equal(
        String(m.astimezone("+08:00")), "2024-03-01T00:30:00.123456+08:00"
    )
    assert_equal(
        String(m.astimezone(TimeZone.from_utc("-05:00"))),
        "2024-02-29T11:30:00.123456-05:00",
    )


def test_comparisons() raises:
    var utc = TimeZone.from_utc("UTC")
    var base = Morrow(2024, 2, 29, 16, 30, 0, 0, utc)
    var same = Morrow(2024, 3, 1, 0, 30, 0, 0, TimeZone.from_utc("+08:00"))
    var earlier = base.shift(microseconds=-1)
    var later = base.shift(seconds=1)

    assert_true(base.__eq__(same))
    assert_true(earlier.__lt__(base))
    assert_true(base.__le__(same))
    assert_true(later.__gt__(base))
    assert_true(later.__ge__(same))
    assert_true(not base.__lt__(same))


def test_clone_weekday_and_naive() raises:
    var m = Morrow(2024, 2, 29, 3, 4, 5, 6, TimeZone.from_utc("+05:30"))

    assert_equal(String(m.clone()), "2024-02-29T03:04:05.000006+05:30")
    assert_equal(m.weekday(), 3)
    assert_equal(m.isoweekday(), 4)
    assert_equal(String(m.naive()), "2024-02-29T03:04:05.000006")


def test_range_and_span_range() raises:
    var utc = TimeZone.from_utc("UTC")
    var start = Morrow(2013, 5, 5, 12, 30, 0, 0, utc)
    var end = Morrow(2013, 5, 5, 17, 15, 0, 0, utc)

    var values = Morrow.range("hour", start, end)
    assert_equal(len(values), 5)
    assert_equal(String(values[0]), "2013-05-05T12:30:00.000000+00:00")
    assert_equal(String(values[4]), "2013-05-05T16:30:00.000000+00:00")

    var capped = Morrow.range("hour", start, end, limit=2)
    assert_equal(len(capped), 2)
    assert_equal(String(capped[1]), "2013-05-05T13:30:00.000000+00:00")

    var inclusive = Morrow.range(
        "hour", start, Morrow(2013, 5, 5, 13, 30, 0, 0, utc)
    )
    assert_equal(len(inclusive), 2)
    assert_equal(String(inclusive[1]), "2013-05-05T13:30:00.000000+00:00")

    var spans = Morrow.span_range("hour", start, end)
    assert_equal(len(spans), 6)
    assert_equal(String(spans[0].start), "2013-05-05T12:00:00.000000+00:00")
    assert_equal(String(spans[0].end), "2013-05-05T12:59:59.999999+00:00")
    assert_equal(String(spans[5].start), "2013-05-05T17:00:00.000000+00:00")
    assert_equal(String(spans[5].end), "2013-05-05T17:59:59.999999+00:00")

    var beijing = TimeZone.from_utc("+08:00")
    var tz_values = Morrow.range(
        "hour", start.naive(), end.naive(), beijing, limit=2
    )
    assert_equal(len(tz_values), 2)
    assert_equal(String(tz_values[0]), "2013-05-05T12:30:00.000000+08:00")
    assert_equal(String(tz_values[1]), "2013-05-05T13:30:00.000000+08:00")

    var local_tz = TimeZone.local()
    var local_values = Morrow.range(
        "hour", start.naive(), end.naive(), "local", limit=1
    )
    assert_equal(local_values[0].tz.offset, local_tz.offset)
    assert_equal(local_values[0].tz.name, "local")
    assert_equal(local_values[0].hour, 12)

    var tz_spans = Morrow.span_range(
        "hour", start.naive(), end.naive(), beijing, limit=1
    )
    assert_equal(String(tz_spans[0].start), "2013-05-05T12:00:00.000000+08:00")
    assert_equal(String(tz_spans[0].end), "2013-05-05T12:59:59.999999+08:00")
    var local_spans = Morrow.span_range(
        "hour", start.naive(), end.naive(), "local", limit=1
    )
    assert_equal(local_spans[0].start.tz.offset, local_tz.offset)
    assert_equal(local_spans[0].start.tz.name, "local")
    assert_equal(local_spans[0].start.hour, 12)

    var limited = Morrow.range("hour", start, limit=3)
    assert_equal(len(limited), 3)
    assert_equal(String(limited[2]), "2013-05-05T14:30:00.000000+00:00")

    var tz_limited = Morrow.range("hour", start.naive(), beijing, limit=2)
    assert_equal(len(tz_limited), 2)
    assert_equal(String(tz_limited[0]), "2013-05-05T12:30:00.000000+08:00")

    var month_start = Morrow(2024, 1, 31, tz=utc)
    var month_end = Morrow(2024, 5, 31, tz=utc)
    var month_values = Morrow.range("month", month_start, month_end)
    assert_equal(String(month_values[0]), "2024-01-31T00:00:00.000000+00:00")
    assert_equal(String(month_values[1]), "2024-02-29T00:00:00.000000+00:00")
    assert_equal(String(month_values[2]), "2024-03-31T00:00:00.000000+00:00")
    assert_equal(String(month_values[3]), "2024-04-30T00:00:00.000000+00:00")
    assert_equal(String(month_values[4]), "2024-05-31T00:00:00.000000+00:00")

    var quarter_values = Morrow.range(
        "quarter", month_start, Morrow(2025, 1, 31, tz=utc)
    )
    assert_equal(String(quarter_values[1]), "2024-04-30T00:00:00.000000+00:00")
    assert_equal(String(quarter_values[2]), "2024-07-31T00:00:00.000000+00:00")
    assert_equal(String(quarter_values[3]), "2024-10-31T00:00:00.000000+00:00")

    var exact_month_spans = Morrow.span_range(
        "month", month_start, month_end, exact=True
    )
    assert_equal(
        String(exact_month_spans[2].start), "2024-03-31T00:00:00.000000+00:00"
    )
    assert_equal(
        String(exact_month_spans[2].end), "2024-04-29T23:59:59.999999+00:00"
    )


def test_interval_exact_range_and_is_between() raises:
    var utc = TimeZone.from_utc("UTC")
    var start = Morrow(2013, 5, 5, 12, 30, 0, 0, utc)
    var end = Morrow(2013, 5, 5, 17, 15, 0, 0, utc)

    var intervals = Morrow.interval("hour", start, end, interval=2)
    assert_equal(len(intervals), 3)
    assert_equal(String(intervals[0].start), "2013-05-05T12:00:00.000000+00:00")
    assert_equal(String(intervals[0].end), "2013-05-05T13:59:59.999999+00:00")
    assert_equal(String(intervals[2].start), "2013-05-05T16:00:00.000000+00:00")
    assert_equal(String(intervals[2].end), "2013-05-05T17:59:59.999999+00:00")

    var beijing = TimeZone.from_utc("+08:00")
    var tz_intervals = Morrow.interval(
        "hour", start.naive(), end.naive(), 2, beijing, limit=1
    )
    assert_equal(
        String(tz_intervals[0].start), "2013-05-05T12:00:00.000000+08:00"
    )
    assert_equal(
        String(tz_intervals[0].end), "2013-05-05T13:59:59.999999+08:00"
    )
    var local_tz = TimeZone.local()
    var local_intervals = Morrow.interval(
        "hour", start.naive(), end.naive(), 2, "local", limit=1
    )
    assert_equal(local_intervals[0].start.tz.offset, local_tz.offset)
    assert_equal(local_intervals[0].start.tz.name, "local")
    assert_equal(local_intervals[0].start.hour, 12)

    var exact = Morrow.span_range("hour", start, end, exact=True)
    assert_equal(len(exact), 5)
    assert_equal(String(exact[0].start), "2013-05-05T12:30:00.000000+00:00")
    assert_equal(String(exact[0].end), "2013-05-05T13:29:59.999999+00:00")
    assert_equal(String(exact[4].start), "2013-05-05T16:30:00.000000+00:00")
    assert_equal(String(exact[4].end), "2013-05-05T17:14:59.999999+00:00")

    var exact_empty = Morrow.span_range("hour", start, start, exact=True)
    assert_equal(len(exact_empty), 0)

    var exact_aligned_end = Morrow.span_range(
        "hour", start, start.shift(hours=1), exact=True
    )
    assert_equal(len(exact_aligned_end), 1)
    assert_equal(
        String(exact_aligned_end[0].end), "2013-05-05T13:29:59.999999+00:00"
    )

    var point = Morrow(2013, 5, 5, 12, 30, 27, 0, utc)
    var low = Morrow(2013, 5, 5, 12, 30, 10, 0, utc)
    var high = Morrow(2013, 5, 5, 12, 30, 36, 0, utc)
    assert_true(point.is_between(low, high))
    assert_true(high.is_between(low, high, bounds="[]"))
    assert_true(not high.is_between(low, high, bounds="[)"))


def test_object_properties_and_serialization() raises:
    var utc = TimeZone.from_utc("UTC")
    var m = Morrow(2019, 1, 24, 16, 35, 27, 276649, utc)

    assert_equal(String(Morrow.min()), "0001-01-01T00:00:00.000000+00:00")
    assert_equal(String(Morrow.max()), "9999-12-31T23:59:59.999999+00:00")
    assert_equal(Morrow.resolution().total_seconds(), 0.000001)

    assert_equal(m.int_timestamp(), 1548347727)
    assert_equal(m.for_json(), "2019-01-24T16:35:27.276649+00:00")
    assert_equal(m.ctime(), "Thu Jan 24 16:35:27 2019")

    var leap_day = Morrow(2024, 2, 29)
    assert_equal(leap_day.quarter(), 1)
    assert_equal(Morrow(2024, 4, 1).quarter(), 2)
    assert_equal(Morrow(2024, 9, 30).quarter(), 3)
    assert_equal(Morrow(2024, 12, 31).quarter(), 4)
    assert_equal(leap_day.week(), 9)

    var iso = leap_day.isocalendar()
    assert_equal(iso.year, 2024)
    assert_equal(iso.week, 9)
    assert_equal(iso.weekday, 4)

    var year_edge = Morrow(2018, 12, 31).isocalendar()
    assert_equal(Morrow(2018, 12, 31).week(), 1)
    assert_equal(year_edge.year, 2019)
    assert_equal(year_edge.week, 1)
    assert_equal(year_edge.weekday, 1)


def test_component_views() raises:
    var tz = TimeZone.from_utc("+05:30")
    var m = Morrow(2024, 2, 29, 3, 4, 5, 123456, tz)

    var date = m.date()
    assert_equal(date.year, 2024)
    assert_equal(date.month, 2)
    assert_equal(date.day, 29)
    assert_equal(String(date), "2024-02-29")

    var time = m.time()
    assert_equal(time.hour, 3)
    assert_equal(time.minute, 4)
    assert_equal(time.second, 5)
    assert_equal(time.microsecond, 123456)
    assert_true(time.tz.is_none())
    assert_equal(String(time), "03:04:05.123456")

    var timetz = m.timetz()
    assert_equal(timetz.tz.offset, 19800)
    assert_equal(String(timetz), "03:04:05.123456+05:30")

    assert_equal(m.tzinfo().offset, 19800)
    assert_equal(m.tzname(), "UTC+05:30")
    assert_equal(
        Morrow(2024, 1, 1, tz=TimeZone.from_utc("UTC")).tzname(), "UTC"
    )
    assert_equal(
        Morrow(2024, 1, 1, tz=TimeZone.from_utc("-05:00")).tzname(), "UTC-05:00"
    )
    assert_equal(m.utcoffset().total_seconds(), 19800.0)
    assert_equal(m.dst().total_seconds(), 0.0)

    var tuple = m.timetuple()
    assert_equal(tuple.year, 2024)
    assert_equal(tuple.mon, 2)
    assert_equal(tuple.mday, 29)
    assert_equal(tuple.hour, 3)
    assert_equal(tuple.min, 4)
    assert_equal(tuple.sec, 5)
    assert_equal(tuple.wday, 3)
    assert_equal(tuple.yday, 60)
    assert_equal(tuple.isdst, 0)

    var utc_tuple = m.utctimetuple()
    assert_equal(utc_tuple.year, 2024)
    assert_equal(utc_tuple.mon, 2)
    assert_equal(utc_tuple.mday, 28)
    assert_equal(utc_tuple.hour, 21)
    assert_equal(utc_tuple.min, 34)
    assert_equal(utc_tuple.sec, 5)
    assert_equal(utc_tuple.wday, 2)
    assert_equal(utc_tuple.yday, 59)
    assert_equal(utc_tuple.isdst, 0)


def test_timezone_status_flags() raises:
    var m = Morrow(2024, 2, 29, 3, 4, 5, 123456, TimeZone.from_utc("+05:30"))

    assert_equal(m.fold(), 0)
    assert_true(not m.ambiguous())
    assert_true(not m.imaginary())


def test_humanize_and_dehumanize() raises:
    var utc = TimeZone.from_utc("UTC")
    var present = Morrow(2024, 1, 1, 12, 0, 0, 0, utc)

    assert_equal(present.humanize(present), "just now")
    assert_equal(present.humanize(present, only_distance=True), "instantly")
    assert_equal(present.shift(seconds=9).humanize(present), "just now")
    assert_equal(
        present.shift(seconds=9).humanize(present, only_distance=True),
        "instantly",
    )
    assert_equal(
        present.shift(seconds=9).humanize(present, granularity="second"),
        "in 9 seconds",
    )
    assert_equal(
        present.shift(seconds=1).humanize(present, granularity="second"),
        "just now",
    )
    assert_equal(
        present.shift(seconds=1).humanize(
            present, only_distance=True, granularity="second"
        ),
        "instantly",
    )
    assert_humanize_granularity_raises(present, present, "seconds")
    assert_humanize_granularity_raises(
        present.shift(seconds=1), present, "seconds"
    )
    assert_equal(
        present.shift(seconds=2).humanize(present, granularity="second"),
        "in 2 seconds",
    )
    assert_equal(
        present.shift(seconds=30).humanize(present, granularity="minute"),
        "in 0 minutes",
    )
    assert_equal(
        present.shift(minutes=30).humanize(present, granularity="hour"),
        "in 0 hours",
    )
    assert_equal(
        present.shift(hours=1).humanize(present, granularity="day"),
        "in 0 days",
    )
    assert_equal(present.shift(hours=-1).humanize(present), "an hour ago")
    assert_equal(present.shift(hours=2).humanize(present), "in 2 hours")
    assert_equal(
        present.shift(hours=2).humanize(present, only_distance=True), "2 hours"
    )
    assert_equal(
        present.shift(minutes=66).humanize(present, granularity="minute"),
        "in 66 minutes",
    )
    assert_humanize_granularity_raises(
        present.shift(seconds=2), present, "seconds"
    )
    assert_humanize_granularity_raises(present.shift(hours=2), present, "hours")
    assert_humanize_granularity_raises(
        present.shift(months=6), present, "quarters"
    )
    assert_equal(
        present.shift(days=8).humanize(present, granularity="week"), "in a week"
    )
    assert_equal(present.shift(days=20).humanize(present), "in a month")
    assert_equal(present.shift(days=75).humanize(present), "in 3 months")
    assert_equal(present.shift(days=364).humanize(present), "in 12 months")
    assert_equal(present.shift(days=730).humanize(present), "in 2 years")

    assert_equal(Morrow.utcnow().shift(hours=-1).humanize(), "an hour ago")
    assert_equal(
        Morrow.utcnow().shift(hours=-2).humanize(only_distance=True), "2 hours"
    )

    var hour_minute = List[String]()
    hour_minute.append("hour")
    hour_minute.append("minute")
    var second_granularity = List[String]()
    second_granularity.append("second")
    assert_equal(
        present.humanize(present, granularity=second_granularity), "just now"
    )
    assert_equal(
        present.shift(seconds=1).humanize(
            present, granularity=second_granularity
        ),
        "just now",
    )
    assert_equal(
        present.shift(seconds=1).humanize(
            present, only_distance=True, granularity=second_granularity
        ),
        "instantly",
    )
    assert_equal(
        present.humanize(present, granularity=hour_minute),
        "in 0 hours and 0 minutes",
    )
    assert_equal(
        present.humanize(present, only_distance=True, granularity=hour_minute),
        "0 hours and 0 minutes",
    )
    assert_equal(
        present.shift(minutes=66).humanize(present, granularity=hour_minute),
        "in an hour and 6 minutes",
    )
    assert_equal(
        present.shift(hours=1).humanize(present, granularity=hour_minute),
        "in an hour and 0 minutes",
    )

    var hour_minute_second = List[String]()
    hour_minute_second.append("hour")
    hour_minute_second.append("minute")
    hour_minute_second.append("second")
    assert_equal(
        present.shift(seconds=3661).humanize(
            present, granularity=hour_minute_second
        ),
        "in an hour a minute and a second",
    )
    assert_equal(
        present.shift(seconds=61).humanize(
            present, granularity=hour_minute_second
        ),
        "in 0 hours a minute and a second",
    )
    assert_equal(
        present.shift(seconds=3600).humanize(
            present, granularity=hour_minute_second
        ),
        "in an hour 0 minutes and 0 seconds",
    )
    var plural_hour_minute = List[String]()
    plural_hour_minute.append("hour")
    plural_hour_minute.append("minutes")
    assert_humanize_granularity_raises(
        present.shift(minutes=66), present, plural_hour_minute
    )
    var minute_hour = List[String]()
    minute_hour.append("minute")
    minute_hour.append("hour")
    assert_equal(
        present.shift(minutes=125).humanize(present, granularity=minute_hour),
        "in 2 hours and 5 minutes",
    )
    var auto_granularity = List[String]()
    auto_granularity.append("auto")
    assert_equal(
        present.shift(hours=2).humanize(present, granularity=auto_granularity),
        "in 2 hours",
    )
    var duplicate_hour = List[String]()
    duplicate_hour.append("hour")
    duplicate_hour.append("hour")
    assert_humanize_granularity_raises(
        present.shift(hours=2), present, duplicate_hour
    )
    assert_equal(
        present.humanize(present.shift(minutes=66), granularity=hour_minute),
        "an hour and 6 minutes ago",
    )
    assert_equal(
        present.shift(minutes=66).humanize(
            present, only_distance=True, granularity=hour_minute
        ),
        "an hour and 6 minutes",
    )

    assert_equal(
        String(present.dehumanize("2 days ago")),
        "2023-12-30T12:00:00.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in a month")),
        "2024-02-01T12:00:00.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("an hour ago")),
        "2024-01-01T11:00:00.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in a minute and 6 seconds")),
        "2024-01-01T12:01:06.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in a minute, 6 seconds")),
        "2024-01-01T12:01:06.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in 1 hours")),
        "2024-01-01T13:00:00.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in a seconds")),
        "2024-01-01T12:00:01.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in an hours")),
        "2024-01-01T13:00:00.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("an hour and 6 minutes ago")),
        "2024-01-01T10:54:00.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in an hour a minute and a second")),
        "2024-01-01T13:01:01.000000+00:00",
    )
    assert_equal(
        String(present.dehumanize("in 0 hours a minute and a second")),
        "2024-01-01T12:01:01.000000+00:00",
    )
    assert_dehumanize_raises(present, "in a hour")
    assert_dehumanize_raises(present, "in an minute")
    assert_dehumanize_raises(present, "in 1 hour")
    assert_dehumanize_raises(present, "in 2 day")
    assert_dehumanize_raises(present, "2 day ago")


def test_creation_helpers() raises:
    assert_component_get_raises(0, 1, 1)
    assert_component_get_raises(10000, 1, 1)
    assert_string_get_raises("0000-01-01")

    var extended = Morrow.fromisoformat("2013-09-29T01:26:43.830580+08:00")
    assert_equal(String(extended), "2013-09-29T01:26:43.830580+08:00")

    var basic = Morrow.fromisoformat("20160413T133656.456289Z")
    assert_equal(String(basic), "2016-04-13T13:36:56.456289+00:00")

    var space_iso_utc = Morrow.get("2024-02-29 03:04:05Z")
    assert_equal(String(space_iso_utc), "2024-02-29T03:04:05.000000+00:00")

    var space_iso_tz = Morrow.get("2024-02-29 03:04:05+05:30")
    assert_equal(String(space_iso_tz), "2024-02-29T03:04:05.000000+05:30")

    var space_iso_naive = Morrow.get("2024-02-29 03:04:05")
    assert_equal(String(space_iso_naive), "2024-02-29T03:04:05.000000+00:00")

    var date_only = Morrow.get("2013-05-05")
    assert_equal(String(date_only), "2013-05-05T00:00:00.000000+00:00")

    var component_date = Morrow.get(2013, 5, 5)
    assert_equal(String(component_date), "2013-05-05T00:00:00.000000+00:00")

    var component_date_tz = Morrow.get(2013, 5, 5, TimeZone.from_utc("+05:30"))
    assert_equal(String(component_date_tz), "2013-05-05T00:00:00.000000+05:30")

    var component_date_tz_str = Morrow.get(2013, 5, 5, "-03:00")
    assert_equal(
        String(component_date_tz_str), "2013-05-05T00:00:00.000000-03:00"
    )

    var local_tz = TimeZone.local()
    var component_date_local = Morrow.get(2013, 5, 5, "local")
    assert_equal(component_date_local.tz.offset, local_tz.offset)
    assert_equal(component_date_local.tz.name, "local")
    assert_equal(component_date_local.hour, 0)

    var component_datetime = Morrow.get(2013, 5, 5, 12, 30, 45, 123456)
    assert_equal(String(component_datetime), "2013-05-05T12:30:45.123456+00:00")

    var component_datetime_tz = Morrow.get(
        2013, 5, 5, 12, 30, 45, 123456, TimeZone.from_utc("+05:30")
    )
    assert_equal(
        String(component_datetime_tz),
        "2013-05-05T12:30:45.123456+05:30",
    )

    var component_datetime_tz_str = Morrow.get(
        2013, 5, 5, 12, 30, 45, 123456, "-03:00"
    )
    assert_equal(
        String(component_datetime_tz_str),
        "2013-05-05T12:30:45.123456-03:00",
    )
    var component_datetime_local = Morrow.get(
        2013, 5, 5, 12, 30, 45, 123456, "local"
    )
    assert_equal(component_datetime_local.tz.offset, local_tz.offset)
    assert_equal(component_datetime_local.tz.name, "local")
    assert_equal(component_datetime_local.hour, 12)

    var ordinal_date = Morrow.get("2024-060")
    assert_equal(String(ordinal_date), "2024-02-29T00:00:00.000000+00:00")

    var basic_ordinal_date = Morrow.get("2024060")
    assert_equal(String(basic_ordinal_date), "2024-02-29T00:00:00.000000+00:00")

    var ordinal_datetime = Morrow.get("2024-060T03:04:05Z")
    assert_equal(String(ordinal_datetime), "2024-02-29T03:04:05.000000+00:00")

    var iso_week_date = Morrow.get("2024-W09-4")
    assert_equal(String(iso_week_date), "2024-02-29T00:00:00.000000+00:00")

    var basic_iso_week_date = Morrow.get("2024W094")
    assert_equal(
        String(basic_iso_week_date), "2024-02-29T00:00:00.000000+00:00"
    )

    var iso_week_datetime = Morrow.get("2024-W09T03:04:05Z")
    assert_equal(String(iso_week_datetime), "2024-02-26T03:04:05.000000+00:00")

    var iso_year = Morrow.get("2024")
    assert_equal(String(iso_year), "2024-01-01T00:00:00.000000+00:00")

    var iso_month = Morrow.get("2024-02")
    assert_equal(String(iso_month), "2024-02-01T00:00:00.000000+00:00")

    var iso_month_datetime = Morrow.get("2024-02T03:04:05Z")
    assert_equal(String(iso_month_datetime), "2024-02-01T03:04:05.000000+00:00")

    var slash_date = Morrow.get("2024/2/29")
    assert_equal(String(slash_date), "2024-02-29T00:00:00.000000+00:00")

    var dot_date = Morrow.get("2024.2.9")
    assert_equal(String(dot_date), "2024-02-09T00:00:00.000000+00:00")

    var short_dash_date = Morrow.get("2024-2-9")
    assert_equal(String(short_dash_date), "2024-02-09T00:00:00.000000+00:00")

    var slash_month = Morrow.get("2024/02")
    assert_equal(String(slash_month), "2024-02-01T00:00:00.000000+00:00")

    var hour_only_time = Morrow.get("2024-02-29T03Z")
    assert_equal(String(hour_only_time), "2024-02-29T03:00:00.000000+00:00")

    var basic_hour_minute_time = Morrow.get("2024-02-29T0304+08:00")
    assert_equal(
        String(basic_hour_minute_time), "2024-02-29T03:04:00.000000+08:00"
    )

    var comma_fraction = Morrow.get("2024-02-29T03:04:05,123456Z")
    assert_equal(String(comma_fraction), "2024-02-29T03:04:05.123456+00:00")

    var rounded_fraction = Morrow.get("2024-02-29T03:04:05.1234567Z")
    assert_equal(String(rounded_fraction), "2024-02-29T03:04:05.123457+00:00")

    var carry_fraction = Morrow.get("2024-02-29T03:04:05.9999995Z")
    assert_equal(String(carry_fraction), "2024-02-29T03:04:06.000000+00:00")

    var carry_fraction_date = Morrow.get("2024-02-29T23:59:59.9999995Z")
    assert_equal(
        String(carry_fraction_date), "2024-03-01T00:00:00.000000+00:00"
    )

    var iso_end_of_day = Morrow.get("2024-02-29T24:00")
    assert_equal(String(iso_end_of_day), "2024-03-01T00:00:00.000000+00:00")

    var iso_end_of_day_seconds = Morrow.get("2024-02-29T24:00:00Z")
    assert_equal(
        String(iso_end_of_day_seconds), "2024-03-01T00:00:00.000000+00:00"
    )

    var basic_iso_end_of_day = Morrow.get("2024-02-29T240000+05:30")
    assert_equal(
        String(basic_iso_end_of_day), "2024-03-01T00:00:00.000000+05:30"
    )

    assert_string_get_raises("2024-02-29T24:01")
    assert_string_get_raises("2024-02-29T24:00:01")
    assert_string_get_raises("2024-02-29T24:00:00.000001")
    assert_string_get_raises("2013-09-29t01:26:43.830580Z")
    assert_string_get_raises("2024-02-29T03:04:05z")

    var normalized_iso = Morrow.get(
        "\t \n  2013-05-05T12:30:45.123456 \t \n",
        normalize_whitespace=True,
    )
    assert_equal(String(normalized_iso), "2013-05-05T12:30:45.123456+00:00")

    var from_ts = Morrow.get(1700000000.0)
    assert_equal(String(from_ts), "2023-11-14T22:13:20.000000+00:00")

    var from_int_ts = Morrow.get(1700000000)
    assert_equal(String(from_int_ts), "2023-11-14T22:13:20.000000+00:00")

    var from_int_ms_ts = Morrow.get(1709175845123)
    assert_equal(String(from_int_ms_ts), "2024-02-29T03:04:05.123000+00:00")

    var from_int_us_ts = Morrow.get(1709175845123456)
    assert_equal(String(from_int_us_ts), "2024-02-29T03:04:05.123456+00:00")

    var beijing_now = Morrow.now("+08:00")
    assert_equal(beijing_now.tz.offset, 28800)
    assert_true(beijing_now.year >= 2020)


def test_flexible_get_creation_helpers() raises:
    var utc_now = Morrow.get()
    assert_true(utc_now.year >= 2020)
    assert_equal(utc_now.tz.offset, 0)

    var beijing_now = Morrow.get(TimeZone.from_utc("+08:00"))
    assert_true(beijing_now.year >= 2020)
    assert_equal(beijing_now.tz.offset, 28800)

    var formatted = Morrow.get(
        "2023-01-20 15:49:10.123456 +05:30",
        "YYYY-MM-DD HH:mm:ss.SSSSSS ZZ",
    )
    assert_equal(String(formatted), "2023-01-20T15:49:10.123456+05:30")

    var mixed_case_utc = Morrow.get("2024-02-29 Utc", "YYYY-MM-DD ZZZ")
    assert_equal(String(mixed_case_utc), "2024-02-29T00:00:00.000000+00:00")

    var lower_gmt = Morrow.get("2024-02-29 gmt", "YYYY-MM-DD ZZZ")
    assert_equal(String(lower_gmt), "2024-02-29T00:00:00.000000+00:00")

    var compact_offset = Morrow.get("2024-02-29 +0530", "YYYY-MM-DD Z")
    assert_equal(String(compact_offset), "2024-02-29T00:00:00.000000+05:30")

    var short_offset = Morrow.get("2024-02-29 +08", "YYYY-MM-DD Z")
    assert_equal(String(short_offset), "2024-02-29T00:00:00.000000+08:00")

    var colon_offset = Morrow.get("2024-02-29 +05:30", "YYYY-MM-DD ZZ")
    assert_equal(String(colon_offset), "2024-02-29T00:00:00.000000+05:30")

    var short_colon_offset = Morrow.get("2024-02-29 +08", "YYYY-MM-DD ZZ")
    assert_equal(String(short_colon_offset), "2024-02-29T00:00:00.000000+08:00")

    var end_of_day = Morrow.get("2024-02-29 24:00", "YYYY-MM-DD HH:mm")
    assert_equal(String(end_of_day), "2024-03-01T00:00:00.000000+00:00")

    var end_of_day_tz = Morrow.get(
        "2024-02-29 24:00 +05:30", "YYYY-MM-DD HH:mm ZZ"
    )
    assert_equal(String(end_of_day_tz), "2024-03-01T00:00:00.000000+05:30")

    assert_get_raises("2024-02-29 24:01", "YYYY-MM-DD HH:mm")
    assert_get_raises("2024-02-29 24:00:01", "YYYY-MM-DD HH:mm:ss")
    assert_get_raises("2024-02-29 23:59:60", "YYYY-MM-DD HH:mm:ss")
    assert_get_raises(
        "2024-02-29 24:00:00.000001", "YYYY-MM-DD HH:mm:ss.SSSSSS"
    )

    assert_get_raises("2024-02-29 +05:30", "YYYY-MM-DD Z")
    assert_get_raises("2024-02-29 UTC", "YYYY-MM-DD Z")
    assert_get_raises("2024-02-29 +0530", "YYYY-MM-DD ZZ")
    assert_get_raises("2024-02-29 +24:00", "YYYY-MM-DD ZZ")
    assert_get_raises("2024-02-29 UTC", "YYYY-MM-DD ZZ")
    assert_get_raises("2024-02-29 +0530", "YYYY-MM-DD ZZZ")
    assert_get_raises("2024-02-29 +05:30", "YYYY-MM-DD ZZZ")

    var formatted_tz = Morrow.get(
        "2023 year 1 month 20 day 3:4:5",
        "YYYY[ year ]M[ month ]D[ day ]H:m:s",
        "+05:30",
    )
    assert_equal(String(formatted_tz), "2023-01-20T03:04:05.000000+05:30")

    var compact = Morrow.get("23/1/2 3:04", "YY/M/D H:mm")
    assert_equal(String(compact), "2023-01-02T03:04:00.000000+00:00")

    var two_digit_year_68 = Morrow.get("68-01-02", "YY-MM-DD")
    assert_equal(String(two_digit_year_68), "2068-01-02T00:00:00.000000+00:00")

    var two_digit_year_69 = Morrow.get("69-01-02", "YY-MM-DD")
    assert_equal(String(two_digit_year_69), "1969-01-02T00:00:00.000000+00:00")

    var two_digit_year_99 = Morrow.get("99-01-02", "YY-MM-DD")
    assert_equal(String(two_digit_year_99), "1999-01-02T00:00:00.000000+00:00")

    var named = Morrow.get(
        "Jan 2nd, 2023 12:05 PM UTC", "MMM Do, YYYY h:mm A ZZZ"
    )
    assert_equal(String(named), "2023-01-02T12:05:00.000000+00:00")

    var lower_named = Morrow.get(
        "jan 2nd, 2023 12:05 PM UTC", "MMM Do, YYYY h:mm A ZZZ"
    )
    assert_equal(String(lower_named), "2023-01-02T12:05:00.000000+00:00")

    var no_year_month_day = Morrow.get("Jan 2", "MMM D")
    assert_equal(String(no_year_month_day), "0001-01-02T00:00:00.000000+00:00")

    var no_year_time = Morrow.get("23:04", "HH:mm")
    assert_equal(String(no_year_time), "0001-01-01T23:04:00.000000+00:00")

    var no_year_ordinal = Morrow.get("1st", "Do")
    assert_equal(String(no_year_ordinal), "0001-01-01T00:00:00.000000+00:00")

    var no_year_day_literal_o = Morrow.get("01o", "DDo")
    assert_equal(
        String(no_year_day_literal_o), "0001-01-01T00:00:00.000000+00:00"
    )

    assert_get_raises("060", "DDD")

    var weekday_name_only = Morrow.get("Mon", "ddd")
    assert_equal(String(weekday_name_only), "1970-01-05T00:00:00.000000+00:00")

    var weekday_name_with_time = Morrow.get("Sunday 23:04", "dddd HH:mm")
    assert_equal(
        String(weekday_name_with_time), "1970-01-04T23:04:00.000000+00:00"
    )

    var weekday_name_with_year = Morrow.get("2024 Tue", "YYYY ddd")
    assert_equal(
        String(weekday_name_with_year), "2024-01-02T00:00:00.000000+00:00"
    )

    var weekday_name_with_month = Morrow.get("02 Tue", "MM ddd")
    assert_equal(
        String(weekday_name_with_month), "1970-02-03T00:00:00.000000+00:00"
    )

    var weekday_name_with_day = Morrow.get("15 Tue", "D ddd")
    assert_equal(
        String(weekday_name_with_day), "0001-01-15T00:00:00.000000+00:00"
    )

    var midnight = Morrow.get(
        "January 2, 2023 12:05 am", "MMMM D, YYYY hh:mm a"
    )
    assert_equal(String(midnight), "2023-01-02T00:05:00.000000+00:00")

    var upper_midnight = Morrow.get(
        "JANUARY 2, 2023 12:05 am", "MMMM D, YYYY hh:mm a"
    )
    assert_equal(String(upper_midnight), "2023-01-02T00:05:00.000000+00:00")

    var lower_meridian = Morrow.get("2023-01-02 12:05 pm", "YYYY-MM-DD hh:mm A")
    assert_equal(String(lower_meridian), "2023-01-02T12:05:00.000000+00:00")

    var upper_meridian = Morrow.get("2023-01-02 12:05 AM", "YYYY-MM-DD hh:mm a")
    assert_equal(String(upper_meridian), "2023-01-02T00:05:00.000000+00:00")

    var hour_00_without_meridian = Morrow.get(
        "2023-01-02 00:05", "YYYY-MM-DD hh:mm"
    )
    assert_equal(
        String(hour_00_without_meridian), "2023-01-02T00:05:00.000000+00:00"
    )

    var hour_13_without_meridian = Morrow.get(
        "2023-01-02 13:05", "YYYY-MM-DD hh:mm"
    )
    assert_equal(
        String(hour_13_without_meridian), "2023-01-02T13:05:00.000000+00:00"
    )

    var hour_24_without_meridian = Morrow.get(
        "2023-01-02 24:00", "YYYY-MM-DD hh:mm"
    )
    assert_equal(
        String(hour_24_without_meridian), "2023-01-03T00:00:00.000000+00:00"
    )

    var hour_01_pm = Morrow.get("2023-01-02 01 PM", "YYYY-MM-DD HH A")
    assert_equal(String(hour_01_pm), "2023-01-02T13:00:00.000000+00:00")

    var hour_00_pm = Morrow.get("2023-01-02 00 PM", "YYYY-MM-DD HH A")
    assert_equal(String(hour_00_pm), "2023-01-02T12:00:00.000000+00:00")

    var hour_12_am = Morrow.get("2023-01-02 12 AM", "YYYY-MM-DD HH A")
    assert_equal(String(hour_12_am), "2023-01-02T00:00:00.000000+00:00")

    var hour_24_pm = Morrow.get("2023-01-02 24 PM", "YYYY-MM-DD HH A")
    assert_equal(String(hour_24_pm), "2023-01-03T00:00:00.000000+00:00")

    var hour_00_pm_12_token = Morrow.get("2023-01-02 00 PM", "YYYY-MM-DD hh A")
    assert_equal(
        String(hour_00_pm_12_token), "2023-01-02T12:00:00.000000+00:00"
    )
    assert_get_raises("2023-01-02 13 AM", "YYYY-MM-DD HH A")

    var searched_month = Morrow.get("June was born in May 1980", "MMMM YYYY")
    assert_equal(String(searched_month), "1980-05-01T00:00:00.000000+00:00")

    var searched_datetime = Morrow.get(
        "created at 2023-01-20 15:49:10 UTC", "YYYY-MM-DD HH:mm:ss"
    )
    assert_equal(String(searched_datetime), "2023-01-20T15:49:10.000000+00:00")

    var punctuated_datetime = Morrow.get(
        "Cool date: 2019-10-31T09:12:45.123456+04:30.",
        "YYYY-MM-DDTHH:mm:ss.SZZ",
    )
    assert_equal(
        String(punctuated_datetime), "2019-10-31T09:12:45.123456+04:30"
    )

    var fenced_date = Morrow.get(
        "Tomorrow (2019-10-31) is Halloween!", "YYYY-MM-DD"
    )
    assert_equal(String(fenced_date), "2019-10-31T00:00:00.000000+00:00")

    var internal_punctuation = Morrow.get(
        "Halloween is on 2019.10.31.", "YYYY.MM.DD"
    )
    assert_equal(
        String(internal_punctuation), "2019-10-31T00:00:00.000000+00:00"
    )

    assert_get_raises("It's Halloween tomorrow (2019-10-31)!", "YYYY-MM-DD")
    assert_get_raises("((2019-10-31)", "YYYY-MM-DD")
    assert_get_raises("2019-10-31..", "YYYY-MM-DD")
    assert_get_raises("date,2019-10-31", "YYYY-MM-DD")
    assert_get_raises("2019-10-31,text", "YYYY-MM-DD")
    assert_get_raises("date-2019-10-31", "YYYY-MM-DD")

    var whitespace_regex = Morrow.get(
        "Mon \t Sep 08   16:41:45     2014",
        "ddd[\\s+]MMM[\\s+]DD[\\s+]HH:mm:ss[\\s+]YYYY",
    )
    assert_equal(String(whitespace_regex), "2014-09-08T16:41:45.000000+00:00")

    var normalized_formatted = Morrow.get(
        "2013-05-05  T \n   12:30:45\t 123456",
        "YYYY-MM-DD T HH:mm:ss SSSSSS",
        normalize_whitespace=True,
    )
    assert_equal(
        String(normalized_formatted), "2013-05-05T12:30:45.123456+00:00"
    )

    var variable_subsecond = Morrow.get(
        "2013-05-05 12:30:45 123456", "YYYY-MM-DD HH:mm:ss S"
    )
    assert_equal(String(variable_subsecond), "2013-05-05T12:30:45.123456+00:00")

    var half_even_subsecond = Morrow.get(
        "2013-05-05 12:30:45 1234565", "YYYY-MM-DD HH:mm:ss S"
    )
    assert_equal(
        String(half_even_subsecond), "2013-05-05T12:30:45.123456+00:00"
    )

    var rounded_subsecond = Morrow.get(
        "2013-05-05 12:30:45 1234566", "YYYY-MM-DD HH:mm:ss S"
    )
    assert_equal(String(rounded_subsecond), "2013-05-05T12:30:45.123457+00:00")

    var day_of_year = Morrow.get("2024 60", "YYYY DDD")
    assert_equal(String(day_of_year), "2024-02-29T00:00:00.000000+00:00")

    var padded_day_of_year = Morrow.get(
        "2024 060 23:59:58", "YYYY DDDD HH:mm:ss"
    )
    assert_equal(String(padded_day_of_year), "2024-02-29T23:59:58.000000+00:00")
    var non_leap_day_366 = Morrow.get("2023 366", "YYYY DDDD")
    assert_equal(String(non_leap_day_366), "2024-01-01T00:00:00.000000+00:00")
    assert_get_raises("2024 000", "YYYY DDDD")
    assert_get_raises("2024 367", "YYYY DDDD")

    assert_get_raises("2024 1th", "YYYY Do")
    assert_get_raises("2024 2st", "YYYY Do")
    assert_get_raises("2024 11st", "YYYY Do")

    var iso_week = Morrow.get("2024-W09-4", "W")
    assert_equal(String(iso_week), "2024-02-29T00:00:00.000000+00:00")

    var basic_iso_week = Morrow.get("2024W094", "W")
    assert_equal(String(basic_iso_week), "2024-02-29T00:00:00.000000+00:00")

    var iso_week_monday = Morrow.get("2024-W09 23:59:58", "W HH:mm:ss")
    assert_equal(String(iso_week_monday), "2024-02-26T23:59:58.000000+00:00")

    var weekday_name = Morrow.get("Thursday 2024-02-29", "dddd YYYY-MM-DD")
    assert_equal(String(weekday_name), "2024-02-29T00:00:00.000000+00:00")

    var weekday_abbreviation = Morrow.get("Thu 2024-02-29", "ddd YYYY-MM-DD")
    assert_equal(
        String(weekday_abbreviation), "2024-02-29T00:00:00.000000+00:00"
    )

    var weekday_number = Morrow.get("4 2024-02-29", "d YYYY-MM-DD")
    assert_equal(String(weekday_number), "2024-02-29T00:00:00.000000+00:00")

    var mismatched_weekday = Morrow.get("Friday 2024-02-29", "dddd YYYY-MM-DD")
    assert_equal(String(mismatched_weekday), "2024-02-29T00:00:00.000000+00:00")

    var formats = List[String]()
    formats.append("YYYY/MM/DD")
    formats.append("YYYY-MM-DD HH:mm:ss")
    var multi = Morrow.get("2023-01-20 15:49:10", formats)
    assert_equal(String(multi), "2023-01-20T15:49:10.000000+00:00")

    var tz_formats = List[String]()
    tz_formats.append("YYYY/MM/DD")
    tz_formats.append("YYYY-MM-DD HH:mm:ss")
    var multi_tz = Morrow.get(
        "2023-01-20 15:49:10", tz_formats, TimeZone.from_utc("+08:00")
    )
    assert_equal(String(multi_tz), "2023-01-20T15:49:10.000000+08:00")
    var local_tz = TimeZone.local()
    var parsed_local = Morrow.get(
        "2023-01-20 15:49:10", "YYYY-MM-DD HH:mm:ss", "local"
    )
    assert_equal(parsed_local.tz.offset, local_tz.offset)
    assert_equal(parsed_local.tz.name, "local")
    assert_equal(parsed_local.hour, 15)
    var multi_local = Morrow.get("2023-01-20 15:49:10", tz_formats, "local")
    assert_equal(multi_local.tz.offset, local_tz.offset)
    assert_equal(multi_local.tz.name, "local")
    assert_equal(multi_local.hour, 15)

    assert_equal(
        String(Morrow.get("1709175845.123456", "X")),
        "2024-02-29T03:04:05.123456+00:00",
    )
    assert_equal(
        String(Morrow.get("1709175845123456", "x")),
        "2024-02-29T03:04:05.123456+00:00",
    )
    assert_equal(
        String(Morrow.get("1709175845123", "x")),
        "2024-02-29T03:04:05.123000+00:00",
    )


def test_date_and_datetime_creation_helpers() raises:
    var date = Morrow(2024, 2, 29).date()
    assert_equal(
        String(Morrow.fromdate(date)), "2024-02-29T00:00:00.000000+00:00"
    )
    assert_equal(
        String(Morrow.fromdate(date, "+05:30")),
        "2024-02-29T00:00:00.000000+05:30",
    )
    var local_tz = TimeZone.local()
    var local_date = Morrow.fromdate(date, "local")
    assert_equal(local_date.tz.offset, local_tz.offset)
    assert_equal(local_date.tz.name, "local")
    assert_equal(local_date.hour, 0)
    assert_equal(
        String(Morrow.get(date, TimeZone.from_utc("+09:00"))),
        "2024-02-29T00:00:00.000000+09:00",
    )

    var dt = Morrow(2024, 2, 29, 3, 4, 5, 123456, TimeZone.from_utc("+08:00"))
    assert_equal(String(Morrow.fromdatetime(dt)), String(dt))
    assert_equal(
        String(Morrow.fromdatetime(Morrow(2024, 2, 29, 3))),
        "2024-02-29T03:00:00.000000+00:00",
    )
    assert_equal(
        String(Morrow.fromdatetime(dt, "UTC")),
        "2024-02-29T03:04:05.123456+00:00",
    )
    var local_datetime = Morrow.fromdatetime(dt, "local")
    assert_equal(local_datetime.tz.offset, local_tz.offset)
    assert_equal(local_datetime.tz.name, "local")
    assert_equal(local_datetime.hour, 3)
    assert_equal(
        String(Morrow.get(dt, TimeZone.from_utc("+05:30"))),
        "2024-02-29T03:04:05.123456+05:30",
    )


def test_timestamp_creation_with_timezone() raises:
    var beijing = TimeZone.from_utc("+08:00")

    var from_timestamp = Morrow.fromtimestamp(1700000000.0, beijing)
    assert_equal(String(from_timestamp), "2023-11-15T06:13:20.000000+08:00")
    assert_equal(from_timestamp.timestamp(), 1700000000.0)

    var from_int_timestamp = Morrow.fromtimestamp(1700000000, "+05:30")
    assert_equal(String(from_int_timestamp), "2023-11-15T03:43:20.000000+05:30")
    assert_equal(from_int_timestamp.timestamp(), 1700000000.0)

    var from_get = Morrow.get(1700000000.5, "+05:30")
    assert_equal(String(from_get), "2023-11-15T03:43:20.500000+05:30")
    assert_equal(from_get.timestamp(), 1700000000.5)

    var from_int_get = Morrow.get(1700000000, TimeZone.from_utc("+05:30"))
    assert_equal(String(from_int_get), "2023-11-15T03:43:20.000000+05:30")
    assert_equal(from_int_get.timestamp(), 1700000000.0)

    var from_int_get_string_tz = Morrow.get(1700000000, "+05:30")
    assert_equal(
        String(from_int_get_string_tz), "2023-11-15T03:43:20.000000+05:30"
    )
    assert_equal(from_int_get_string_tz.timestamp(), 1700000000.0)

    var before_epoch = Morrow.utcfromtimestamp(-0.75)
    assert_equal(String(before_epoch), "1969-12-31T23:59:59.250000+00:00")

    assert_int_get_raises(-1000000000000)


def test_string_timestamp_creation() raises:
    var beijing = TimeZone.from_utc("+08:00")

    assert_equal(
        String(Morrow.utcfromtimestamp("1700000000.5")),
        "2023-11-14T22:13:20.500000+00:00",
    )
    assert_equal(
        String(Morrow.fromtimestamp("1700000000.5", beijing)),
        "2023-11-15T06:13:20.500000+08:00",
    )
    assert_equal(
        String(Morrow.fromtimestamp("1700000000.5", "+05:30")),
        "2023-11-15T03:43:20.500000+05:30",
    )
    assert_equal(
        String(Morrow.utcfromtimestamp("-0.75")),
        "1969-12-31T23:59:59.250000+00:00",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
