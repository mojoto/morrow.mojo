---
sidebar_position: 9
---

# Migrating to 0.8

## Construction and errors

`Morrow(...)` now validates all date/time fields and the UTC offset, and defaults to UTC. Constructors and helpers that create dates can now raise; propagate errors with `raises` or handle them with `try/except`.

For a wall time with no timezone, pass `tz=TimeZone.none()` or call `.naive()`. `now()` and `fromtimestamp()` retain their local-time behavior; `get()` and `utcnow()` use UTC.

Equality between a naive and an aware value is false. Ordering, subtraction, relative humanization, and interval membership reject mixed awareness. Use `.to(...)` to convert aware instants, or `.replace(tzinfo=...)` to attach a timezone to wall fields explicitly.

Calendar values outside years 1–9999 raise. Individual shift arguments larger than the supported calendar are rejected before integer multiplication, even if other arguments could cancel them. Overflow while producing an unrepresentable span also raises; use `limit` to stop before that boundary.

## Lazy ranges

Existing `range`, `span_range`, and `interval` return lists. Their new `iter_range`, `iter_span_range`, and `iter_interval` counterparts generate one result at a time, using constant auxiliary memory. They share the same algorithms and boundary semantics.

```text
for point in Morrow.iter_range("second", start, end, limit=10):
    print(point)

for span in Morrow.iter_interval("month", start, end, interval=3, exact=True):
    print(span)
```

`iter_range(frame, start, limit=...)` also supports an omitted end. Span iterators require an end. To apply a timezone before iteration, explicitly convert or replace the start and end first. Iterators return values, and iteration starts from a copy of their current state.

## Weekdays

`shift_weekday(weekday, nth=1)` uses Monday=0 through Sunday=6. Positive `nth` selects the nth occurrence on or after the current day; negative selects on or before it. Today is included when it matches. Zero is invalid. Existing `shift(weekday=...)` is unchanged.

## Local timezone

`TimeZone.local()` uses today's offset; `TimeZone.local(timestamp)` returns the host offset at a particular instant. Converting to `local` resolves the target instant, and constructing local wall fields resolves that date. The resulting timezone still stores a fixed-offset snapshot. Ambiguous/nonexistent wall-time policy remains host-defined until full named timezone support is introduced.

## Arrow compatibility

Core parsing, formatting, calendar shifts, boundaries and intervals follow Arrow-style semantics. CI compares 400 deterministic core results against pinned Arrow 1.4.0, in addition to the edge-case tests. This is a bounded compatibility check, not a claim of complete equivalence.

In 0.8, locales remain English-only, IANA names and explicit DST disambiguation are not supported, general regex parsing is not supported, and Python objects/factories are not runtime dependencies. Morrow uses native Mojo structs and methods; its existing range APIs return lists.
