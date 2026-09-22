---
sidebar_position: 8
---

# API Reference

This page summarizes the public API surface. For exact behavior, see the unit tests in the repository.

## Morrow

Construction:

- `Morrow(...)`
- `Morrow.now()`, `Morrow.now(tz)`, `Morrow.utcnow()`
- `Morrow.fromtimestamp(...)`, `Morrow.utcfromtimestamp(...)`
- `Morrow.get(...)`
- `Morrow.fromisoformat(...)`
- `Morrow.strptime(...)`
- `Morrow.fromdate(...)`, `Morrow.fromdatetime(...)`
- `Morrow.fromordinal(...)`, `Morrow.fromisocalendar(...)`

Formatting and conversion:

- `format(fmt, locale="en")`
- `strftime(fmt)`
- `isoformat(sep="T", timespec="auto")`
- `for_json()`
- `timestamp()`, `float_timestamp()`, `int_timestamp()`
- `to(tz)`, `astimezone(tz)`, `naive()`

Date-time operations:

- `replace(...)`
- `shift(...)`, `shift_weekday(weekday, nth=1)`
- `floor(frame)`, `ceil(frame)`, `span(frame)`
- `range(...)`, `span_range(...)`, `interval(...)`
- `iter_range(...)`, `iter_span_range(...)`, `iter_interval(...)`
- `is_between(start, end, bounds="()")`

Views and calendar fields:

- `date()`, `time()`, `timetz()`, `datetime()`
- `weekday()`, `isoweekday()`, `isocalendar()`
- `timetuple()`, `utctimetuple()`
- `quarter()`, `week()`, `ctime()`
- `fold()`, `ambiguous()`, `imaginary()`, `dst()`

Relative time:

- `humanize(...)`
- `dehumanize(input_string, locale="en")`

## TimeZone

- `TimeZone(offset, name="")`
- `TimeZone.none()`
- `TimeZone.local()`, `TimeZone.local(timestamp)`
- `TimeZone.from_name(name)`
- `TimeZone.from_utc(value)`
- `format(sep=":")`
- `is_none()`

## TimeDelta

- `TimeDelta(days=0, seconds=0, microseconds=0, milliseconds=0, minutes=0, hours=0, weeks=0)`
- `total_seconds()`
- arithmetic, comparison, boolean, and string conversion operators
