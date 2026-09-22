---
sidebar_position: 3
---

# Parsing

Morrow accepts ISO 8601 strings, timestamps, component values, token-based format strings, and format fallback lists.

## ISO and timestamps

```text
print(Morrow.get("2026-01-01"))
print(Morrow.fromisoformat("20260101T030405.123456Z"))
print(Morrow.get(1767225600.0))
print(Morrow.get("2026-01-01 03:04:05Z"))
```

ISO parsing supports extended and basic calendar dates, ordinal dates, ISO week dates, comma or dot subseconds, `24:00` end-of-day notation, and fixed-offset time zones.

## token-based formats

```text
print(Morrow.get("2026-01-01 15:49:10.123456 +05:30", "YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(Morrow.get("Jan 1st, 2026", "MMM Do, YYYY"))
print(Morrow.get("Thursday 2026-01-01", "dddd YYYY-MM-DD"))
print(Morrow.get("1767236645123456", "x"))
```

When input text may include extra content, Morrow searches for a valid token match with parse boundaries:

```text
print(Morrow.get("June was born in January 2026", "MMMM YYYY"))
```

## Multiple formats

```text
from std.collections import List

var formats = List[String]()
formats.append("YYYY/MM/DD")
formats.append("YYYY-MM-DD HH:mm:ss")

print(Morrow.get("2026-01-01 15:49:10", formats))
```

## Locale

```text
var value = Morrow.get("2024 十一月 05 下午 03:00", "YYYY MMMM DD A hh:mm", locale="zh-CN")
```

Month and weekday names, ordinal days, and AM/PM markers support English, Simplified Chinese and Traditional Chinese. UTF-8 literal text is supported. For localized parsing, use the keyword `locale`; `tz` accepts a `TimeZone` and `normalize_whitespace` is optional.

Positive numeric timestamps above 32,503,737,600 are interpreted as milliseconds or microseconds by magnitude. Negative timestamps are seconds. For dates beyond this seconds cutoff, use calendar components or ISO text to avoid unit ambiguity. Non-finite and out-of-calendar timestamps raise.
