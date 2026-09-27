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
- `Morrow.get(time_tuple)` for a `MorrowTimeTuple` in UTC

Formatting and conversion:

- `format(fmt, locale="en")`; `locale` also accepts a `Locale`
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
- `tzname()`, `tz_abbreviation()`, `utcoffset()`

Relative time:

- `humanize(...)`
- `dehumanize(input_string, locale="en")`

Comparison and hashing:

- `==` and `!=` compare instants; naive and aware values are never equal
- `Morrow` is `Hashable` and `Equatable`, so values can be `Dict` keys and `Set` members
- Ordering (`<`, `<=`, `>`, `>=`) raises for mixed naive and aware values

## Locale

- `Locale(name)` loads one of the 81 built-in locales; see [Locales](./locales.md)
- `Locale.available()`, `Locale.aliases(name)`
- Public fields: `name`, `month_names`, `month_abbreviations`, `day_names`, `day_abbreviations`, `meridians`, `past`, `future`, `and_word`, `separator`, `plural_rule`, `relative_rule`, `multi_rule`, `instantly`, `year_offset`, `ordinals`, `ordinal_digits`, `timeframes`, `distance_timeframes`
- `month_name(month)`, `month_abbreviation(month)`, `day_name(isoweekday)`, `day_abbreviation(isoweekday)`
- `meridian(hour, token)`, `ordinal_number(n)`, `year_full(year)`, `year_abbreviation(year)`
- `set_timeframe(frame, form)`, `set_timeframe(frame, keys, forms)`, `has_timeframe(frame)`
- `describe(frame, delta=0, only_distance=False)`, `describe_multi(frames, deltas, only_distance=False)`

## TimeFrame

- `TimeFrame(form)`, `TimeFrame(keys, forms)`
- `is_missing()`, `is_plain()`, `has_key(key)`, `form(key)`, `keys()`, `forms()`

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
- `total_seconds()`, `divmod(other)`
- `+`, `-`, `*` by `Int` or `Float64`, `/` and `//` by a `TimeDelta`, `Int`, or `Float64`, `%`
- `Comparable`, `Equatable`, and `Hashable`; boolean and string conversion
- Float scaling and `/` by a number round to the nearest microsecond, ties to even
