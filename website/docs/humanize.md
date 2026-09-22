---
sidebar_position: 7
---

# Humanize

Morrow can describe date-time distances in English, Simplified Chinese, or Traditional Chinese and apply those distances back to a base value.

## Humanize

```text
from std.collections import List

var present = Morrow(2026, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))

print(present.shift(hours=2).humanize(present))

var granularity = List[String]()
granularity.append("hour")
granularity.append("minute")

print(present.shift(minutes=66).humanize(present, granularity=granularity))
```

Use `only_distance=True` to omit the direction phrase.

## Dehumanize

```text
var present = Morrow(2026, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))

print(present.dehumanize("2 days ago"))
print(present.dehumanize("in a minute and 6 seconds"))
```

Supported units include years, quarters, months, weeks, days, hours, minutes, and seconds.

## Locale

```text
print(present.shift(hours=-2).humanize(present, locale="zh-CN"))
print(present.shift(hours=2).humanize(present, locale="zh-TW"))
print(present.dehumanize("1小时6分钟后", locale="zh-CN"))
```

Supported locales: `en`, `zh-CN` / `zh-Hans`, and `zh-TW` / `zh-Hant`. Unknown locales raise. Chinese input uses numeric counts and explicit units, ending in 前 or 后/後; arbitrary natural language is not parsed. Multi-unit output and `only_distance` also support locales.
