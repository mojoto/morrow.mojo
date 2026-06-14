# Morrow.mojo: Human-friendly date & time for Mojo 🔥

<p align="center">
  <a href="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml">
    <img src="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml/badge.svg" alt="Test" />
  </a>
  <a href="https://github.com/mojoto/morrow.mojo/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/mojoto/morrow.mojo">
  </a>
</p>

**Morrow** is a Mojo library that provides human-friendly method for managing, formatting, and transforming dates, times, and timestamps.

Morrow is heavily inspired by [arrow](https://github.com/arrow-py/arrow), and thanks for its elegant design.

## Features

- TimeZone-aware and UTC by default.
- Support format and parse strings.
- Support for the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard.

## Preparation

You have three ways to reference this library:

- Download morrow.mojopkg from [releases](https://github.com/mojoto/morrow.mojo/releases).
- Clone this project and execute `make build` to build morrow.mojopkg.
- Directly copy the `morrow` directory of this project to your own project.

## Usage

```mojo
from morrow import Morrow, TimeZone

# Get local date and time.
var now = Morrow.now()
print(str(now))  # 2023-10-01T20:10:25.188957+08:00

# Get UTC date and time.
var utcnow = Morrow.utcnow()
print(str(utcnow))  # 2023-10-01T20:10:25.954638+00:00

# Get local time from POSIX timestamp.
var t = Morrow.fromtimestamp(1696089600)
print(str(t))  # 2023-10-01T00:00:00.000000+08:00

# Get UTC time from POSIX timestamp.
var utc_t = Morrow.utcfromtimestamp(1696089600)
print(str(utc_t))  # 2023-09-30T16:00:00.000000+00:00

# Create from ISO 8601 strings and timestamps.
print(str(Morrow.get("2013-05-05")))  # 2013-05-05T00:00:00.000000+00:00
print(str(Morrow.fromisoformat("20160413T133656.456289Z")))  # 2016-04-13T13:36:56.456289+00:00
print(str(Morrow.get(1700000000.0)))  # 2023-11-14T22:13:20.000000+00:00
print(str(Morrow.get(1700000000.5, "+05:30")))  # 2023-11-15T03:43:20.500000+05:30
print(Morrow.now("+08:00").tz.offset)  # 28800
var date_view = Morrow(2024, 2, 29).date()
print(str(Morrow.fromdate(date_view, "+05:30")))  # 2024-02-29T00:00:00.000000+05:30
print(str(Morrow.fromdatetime(Morrow(2024, 2, 29, 3))))  # 2024-02-29T03:00:00.000000+00:00

# Get ISO format.
var m = Morrow(2023, 10, 1, 0, 0, 0, 1234)
print(m.isoformat())  # 2023-10-01T00:00:00.001234

# custom format
var m = Morrow(2023, 10, 1, 0, 0, 0, 1234)
print(m.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))  # 2023-10-01 00:00:00.001234 +00:00
print(m.format("dddd, DD MMM YYYY HH:mm:ss ZZZ"))  # Sunday, 01 Oct 2023 00:00:00 UTC
print(m.format("YYYY[Y]MM[M]DD[D]"))  # 2023Y10M01D
print(Morrow(2024, 2, 29, 3, 4, 5, 123456, TimeZone.from_utc("UTC")).format("DDD W X x"))  # 60 2024-W09-4 1709175845 1709175845123456
print(Morrow(2024, 2, 29, 3, 4, 5, 123456, TimeZone(19800, "IST")).strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))  # 2024-02-29 03:04:05.123456 +0530 IST

# Get ISO format with time zone.
var m_beijing = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, 'Bejing'))
print(m_beijing.isoformat(timespec="seconds"))  # 2023-10-01T00:00:00+08:00

# Replace selected fields.
var replaced = m.replace(year=2024, month=2, day=29)
print(str(replaced))  # 2024-02-29T00:00:00.001234
print(str(m.replace(tzinfo="+08:00")))  # 2023-10-01T00:00:00.001234+08:00

# Shift by relative offsets. Month and year shifts clamp to the last valid day.
var shifted = Morrow(2024, 1, 31).shift(months=1, weeks=1, hours=2)
print(str(shifted))  # 2024-03-07T02:00:00.000000

# Get the floor, ceiling, or span of a timeframe.
var hour = Morrow(2024, 2, 29, 13, 14, 15).span("hour")
print(str(hour.start))  # 2024-02-29T13:00:00.000000
print(str(hour.end))  # 2024-02-29T13:59:59.999999
print(str(Morrow(2024, 2, 29, 13, 14, 15).floor("day")))  # 2024-02-29T00:00:00.000000
print(str(Morrow(2024, 2, 29, 13, 14, 15).span("hour", exact=True).start))  # 2024-02-29T13:14:15.000000

# Iterate over ranges and span ranges.
var start = Morrow(2013, 5, 5, 12, 30, 0, 0, TimeZone.from_utc("UTC"))
var end = Morrow(2013, 5, 5, 17, 15, 0, 0, TimeZone.from_utc("UTC"))
var points = Morrow.range("hour", start, end)
print(str(points[0]))  # 2013-05-05T12:30:00.000000+00:00
var spans = Morrow.span_range("hour", start, end)
print(str(spans[0].start))  # 2013-05-05T12:00:00.000000+00:00

# Convert fixed-offset time zones and get POSIX timestamps.
var utc = Morrow(2024, 2, 29, 16, 30, 0, 123456, TimeZone.from_utc("UTC"))
print(str(utc.to("+08:00")))  # 2024-03-01T00:30:00.123456+08:00
print(utc.timestamp())  # 1709224200.123456
print(utc.int_timestamp())  # 1709224200
print(utc.for_json())  # 2024-02-29T16:30:00.123456+00:00

# Get ctime and ISO calendar fields.
print(utc.ctime())  # Thu Feb 29 16:30:00 2024
var iso = utc.isocalendar()
print(iso.week)  # 9

# Get date, time, and struct_time-style component views.
print(str(utc.date()))  # 2024-02-29
print(str(utc.time()))  # 16:30:00.123456
print(str(utc.timetz()))  # 16:30:00.123456+00:00
print(utc.timetuple().yday)  # 60
print(utc.utctimetuple().hour)  # 16
print(utc.utcoffset().total_seconds())  # 0.0

# Humanize and dehumanize English relative times.
var present = Morrow(2024, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))
print(present.shift(hours=2).humanize(present))  # in 2 hours
print(str(present.dehumanize("2 days ago")))  # 2023-12-30T12:00:00.000000+00:00

# Get time zone offset.
print(TimeZone.from_utc('UTC+08:00').offset)  # 28800

# Subtract two dates.
var timedelta = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
print(str(timedelta))  # 1 day, 0:00:00

# Return proleptic Gregorian ordinal for the year, month and day.
var m_10_1 = Morrow(2023, 10, 1)
var ordinal = m_10_1.toordinal()
print(ordinal)  # 738794

# Construct a Morrow from a proleptic Gregorian ordinal.
var m_10_1_ = Morrow.fromordinal(ordinal)
print(str(m_10_1_))  # 2023-10-01T00:00:00.000000

```
