---
sidebar_position: 9
---

# Migration Guide

## Upgrading to 0.9

Named and local timezones now use ICU. Install the ICU runtime on Linux. Hours and smaller shifts, and TimeDelta arithmetic, use elapsed time; calendar-day shifts preserve wall time. Existing fixed-offset results remain unchanged. UTF-8 literals are now supported throughout token parsing and formatting.

## Upgrading to 0.8

### Construction and errors

`Morrow(...)` now validates all date/time fields and the UTC offset, and defaults to UTC. Constructors and helpers that create dates can now raise; propagate errors with `raises` or handle them with `try/except`.

For a wall time with no timezone, pass `tz=TimeZone.none()` or call `.naive()`. `now()` and `fromtimestamp()` retain their local-time behavior; `get()` and `utcnow()` use UTC.

Equality between a naive and an aware value is false. Ordering, subtraction, relative humanization, and interval membership reject mixed awareness. Use `.to(...)` to convert aware instants, or `.replace(tzinfo=...)` to attach a timezone to wall fields explicitly.

Calendar values outside years 1–9999 raise. Individual shift arguments larger than the supported calendar are rejected before integer multiplication, even if other arguments could cancel them. Overflow while producing an unrepresentable span also raises; use `limit` to stop before that boundary.

### Lazy ranges

Existing `range`, `span_range`, and `interval` return lists. Their new `iter_range`, `iter_span_range`, and `iter_interval` counterparts generate one result at a time, using constant auxiliary memory. They share the same algorithms and boundary semantics.

```text
for point in Morrow.iter_range("second", start, end, limit=10):
    print(point)

for span in Morrow.iter_interval("month", start, end, interval=3, exact=True):
    print(span)
```

`iter_range(frame, start, limit=...)` also supports an omitted end. Span iterators require an end. To apply a timezone before iteration, explicitly convert or replace the start and end first. Iterators return values, and iteration starts from a copy of their current state.

### Weekdays

`shift_weekday(weekday, nth=1)` uses Monday=0 through Sunday=6. Positive `nth` selects the nth occurrence on or after the current day; negative selects on or before it. Today is included when it matches. Zero is invalid. Existing `shift(weekday=...)` is unchanged.
