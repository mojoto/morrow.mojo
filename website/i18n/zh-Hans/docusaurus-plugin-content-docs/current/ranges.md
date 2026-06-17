---
sidebar_position: 6
---

# 范围和时间段

Morrow 可以偏移日期、查找时间框架边界，并遍历时间点或时间段。

## 偏移

```text
var shifted = Morrow(2026, 1, 1).shift(months=1, weeks=1, hours=2)
print(shifted)
```

按月、季度、年偏移时，如果目标月份没有对应日期，会夹到该月最后一天。

## floor、ceiling 和 span

```text
var value = Morrow(2026, 1, 1, 13, 14, 15)
var hour = value.span("hour")

print(hour.start)
print(hour.end)
print(value.floor("day"))
print(value.span("hour", exact=True).start)
```

支持的框架包括 year、quarter、month、week、day、hour、minute、second 和 microsecond。

## 范围

```text
var start = Morrow(2026, 1, 1, 12, 30, 0, 0, TimeZone.from_utc("UTC"))
var end = Morrow(2026, 1, 1, 17, 15, 0, 0, TimeZone.from_utc("UTC"))

var points = Morrow.range("hour", start, end)
var spans = Morrow.span_range("hour", start, end)

print(points[0])
print(spans[0].start)
```

可以使用 `limit`、`bounds`、`exact` 和 `week_start` 调整遍历行为。
