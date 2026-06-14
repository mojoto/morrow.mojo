from std.collections import List
from std.testing import assert_equal, assert_true, TestSuite

from morrow._libc import c_localtime, CTm
from morrow import Morrow, MorrowIsoCalendar
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

    var replaced_tz = m.replace(tzinfo=TimeZone.from_utc("+08:00"))
    assert_equal(String(replaced_tz), "2024-02-29T03:04:05.123456+08:00")

    replaced_tz = m.replace(tzinfo="UTC")
    assert_equal(String(replaced_tz), "2024-02-29T03:04:05.123456+00:00")


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

    var tz_spans = Morrow.span_range(
        "hour", start.naive(), end.naive(), beijing, limit=1
    )
    assert_equal(String(tz_spans[0].start), "2013-05-05T12:00:00.000000+08:00")
    assert_equal(String(tz_spans[0].end), "2013-05-05T12:59:59.999999+08:00")

    var limited = Morrow.range("hour", start, limit=3)
    assert_equal(len(limited), 3)
    assert_equal(String(limited[2]), "2013-05-05T14:30:00.000000+00:00")

    var tz_limited = Morrow.range("hour", start.naive(), beijing, limit=2)
    assert_equal(len(tz_limited), 2)
    assert_equal(String(tz_limited[0]), "2013-05-05T12:30:00.000000+08:00")


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

    var exact = Morrow.span_range("hour", start, end, exact=True)
    assert_equal(len(exact), 5)
    assert_equal(String(exact[0].start), "2013-05-05T12:30:00.000000+00:00")
    assert_equal(String(exact[0].end), "2013-05-05T13:29:59.999999+00:00")
    assert_equal(String(exact[4].start), "2013-05-05T16:30:00.000000+00:00")
    assert_equal(String(exact[4].end), "2013-05-05T17:14:59.999999+00:00")

    var point = Morrow(2013, 5, 5, 12, 30, 27, 0, utc)
    var low = Morrow(2013, 5, 5, 12, 30, 10, 0, utc)
    var high = Morrow(2013, 5, 5, 12, 30, 36, 0, utc)
    assert_true(point.is_between(low, high))
    assert_true(high.is_between(low, high, bounds="[]"))
    assert_true(not high.is_between(low, high, bounds="[)"))


def test_object_properties_and_serialization() raises:
    var utc = TimeZone.from_utc("UTC")
    var m = Morrow(2019, 1, 24, 16, 35, 27, 276649, utc)

    assert_equal(m.int_timestamp(), 1548347727)
    assert_equal(m.for_json(), "2019-01-24T16:35:27.276649+00:00")
    assert_equal(m.ctime(), "Thu Jan 24 16:35:27 2019")

    var leap_day = Morrow(2024, 2, 29)
    var iso = leap_day.isocalendar()
    assert_equal(iso.year, 2024)
    assert_equal(iso.week, 9)
    assert_equal(iso.weekday, 4)

    var year_edge = Morrow(2018, 12, 31).isocalendar()
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
    assert_equal(present.shift(hours=-1).humanize(present), "an hour ago")
    assert_equal(present.shift(hours=2).humanize(present), "in 2 hours")
    assert_equal(
        present.shift(hours=2).humanize(present, only_distance=True), "2 hours"
    )
    assert_equal(
        present.shift(minutes=66).humanize(present, granularity="minute"),
        "in 66 minutes",
    )
    assert_equal(
        present.shift(days=8).humanize(present, granularity="week"), "in a week"
    )

    assert_equal(Morrow.utcnow().shift(hours=-1).humanize(), "an hour ago")
    assert_equal(
        Morrow.utcnow().shift(hours=-2).humanize(only_distance=True), "2 hours"
    )

    var hour_minute = List[String]()
    hour_minute.append("hour")
    hour_minute.append("minute")
    assert_equal(
        present.shift(minutes=66).humanize(present, granularity=hour_minute),
        "in an hour and 6 minutes",
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


def test_creation_helpers() raises:
    var extended = Morrow.fromisoformat("2013-09-29T01:26:43.830580+08:00")
    assert_equal(String(extended), "2013-09-29T01:26:43.830580+08:00")

    var basic = Morrow.fromisoformat("20160413T133656.456289Z")
    assert_equal(String(basic), "2016-04-13T13:36:56.456289+00:00")

    var date_only = Morrow.get("2013-05-05")
    assert_equal(String(date_only), "2013-05-05T00:00:00.000000+00:00")

    var from_ts = Morrow.get(1700000000.0)
    assert_equal(String(from_ts), "2023-11-14T22:13:20.000000+00:00")

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

    var formatted_tz = Morrow.get(
        "2023 year 1 month 20 day 3:4:5",
        "YYYY[ year ]M[ month ]D[ day ]H:m:s",
        "+05:30",
    )
    assert_equal(String(formatted_tz), "2023-01-20T03:04:05.000000+05:30")

    var compact = Morrow.get("23/1/2 3:04", "YY/M/D H:mm")
    assert_equal(String(compact), "2023-01-02T03:04:00.000000+00:00")

    var named = Morrow.get(
        "Jan 2nd, 2023 12:05 PM UTC", "MMM Do, YYYY h:mm A ZZZ"
    )
    assert_equal(String(named), "2023-01-02T12:05:00.000000+00:00")

    var lower_named = Morrow.get(
        "jan 2nd, 2023 12:05 PM UTC", "MMM Do, YYYY h:mm A ZZZ"
    )
    assert_equal(String(lower_named), "2023-01-02T12:05:00.000000+00:00")

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

    var day_of_year = Morrow.get("2024 60", "YYYY DDD")
    assert_equal(String(day_of_year), "2024-02-29T00:00:00.000000+00:00")

    var padded_day_of_year = Morrow.get(
        "2024 060 23:59:58", "YYYY DDDD HH:mm:ss"
    )
    assert_equal(String(padded_day_of_year), "2024-02-29T23:59:58.000000+00:00")

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

    assert_equal(
        String(Morrow.get("1709175845.123456", "X")),
        "2024-02-29T03:04:05.123456+00:00",
    )
    assert_equal(
        String(Morrow.get("1709175845123456", "x")),
        "2024-02-29T03:04:05.123456+00:00",
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
    assert_equal(
        String(Morrow.get(dt, TimeZone.from_utc("+05:30"))),
        "2024-02-29T03:04:05.123456+05:30",
    )


def test_timestamp_creation_with_timezone() raises:
    var beijing = TimeZone.from_utc("+08:00")

    var from_timestamp = Morrow.fromtimestamp(1700000000.0, beijing)
    assert_equal(String(from_timestamp), "2023-11-15T06:13:20.000000+08:00")
    assert_equal(from_timestamp.timestamp(), 1700000000.0)

    var from_get = Morrow.get(1700000000.5, "+05:30")
    assert_equal(String(from_get), "2023-11-15T03:43:20.500000+05:30")
    assert_equal(from_get.timestamp(), 1700000000.5)

    var before_epoch = Morrow.utcfromtimestamp(-0.75)
    assert_equal(String(before_epoch), "1969-12-31T23:59:59.250000+00:00")


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
