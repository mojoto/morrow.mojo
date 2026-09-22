---
sidebar_position: 4
---

# Formatting

Morrow supports Arrow-style `format`, Python-style `strftime`, and ISO output helpers.

## ISO output

```text
var value = Morrow(2026, 1, 1, 0, 0, 0, 1234)

print(value.isoformat())
print(value.isoformat(timespec="milliseconds"))
```

## Arrow-style tokens

```text
from morrow import FORMAT_RSS, Morrow, TimeZone

var value = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))

print(value.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(value.format("dddd, DD MMM YYYY HH:mm:ss ZZZ"))
print(value.format("DDD W X x"))
print(value.format("Do MMMM YYYY"))
print(value.format(FORMAT_RSS))
```

Literal text can be wrapped in brackets:

```text
print(Morrow(2026, 1, 1).format("YYYY[Y]MM[M]DD[D]"))
```

## strftime

```text
var ist = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone(19800, "IST"))

print(ist.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))
```

## Locale

```text
print(Morrow(2024, 11, 5, 15).format("MMMM Do dddd A hh", locale="zh-CN"))
```

Month and weekday names, ordinal days, and AM/PM markers support English, Simplified Chinese and Traditional Chinese. UTF-8 literal text is supported. For localized parsing, use the keyword `locale`; `tz` accepts a `TimeZone` and `normalize_whitespace` is optional.
