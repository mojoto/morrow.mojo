---
sidebar_position: 6
---

# Ranges and Spans

Morrow can shift dates, find frame boundaries, and iterate through points or spans.

## Shift

```text
var shifted = Morrow(2026, 1, 1).shift(months=1, weeks=1, hours=2)
print(shifted)
```

Month, quarter, and year shifts clamp to the last valid day of the target month.

## Floor, ceiling, and span

```text
var value = Morrow(2026, 1, 1, 13, 14, 15)
var hour = value.span("hour")

print(hour.start)
print(hour.end)
print(value.floor("day"))
print(value.span("hour", exact=True).start)
```

Supported frames include year, quarter, month, week, day, hour, minute, second, and microsecond.

## Ranges

```text
var start = Morrow(2026, 1, 1, 12, 30, 0, 0, TimeZone.from_utc("UTC"))
var end = Morrow(2026, 1, 1, 17, 15, 0, 0, TimeZone.from_utc("UTC"))

var points = Morrow.range("hour", start, end)
var spans = Morrow.span_range("hour", start, end)

print(points[0])
print(spans[0].start)
```

Use `limit`, `bounds`, `exact`, and `week_start` to tune iteration behavior.
