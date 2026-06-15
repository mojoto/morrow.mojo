---
sidebar_position: 3
---

# Parsing

Morrow accepts ISO 8601 strings, timestamps, component values, Arrow-style format strings, and format fallback lists.

## ISO and timestamps

```text
print(str(Morrow.get("2013-05-05")))
print(str(Morrow.fromisoformat("20160413T133656.456289Z")))
print(str(Morrow.get(1700000000.0)))
print(str(Morrow.get("2024-02-29 03:04:05Z")))
```

ISO parsing supports extended and basic calendar dates, ordinal dates, ISO week dates, comma or dot subseconds, `24:00` end-of-day notation, and fixed-offset time zones.

## Arrow-style formats

```text
print(str(Morrow.get("2023-01-20 15:49:10.123456 +05:30", "YYYY-MM-DD HH:mm:ss.SSSSSS ZZ")))
print(str(Morrow.get("jan 2nd, 2023", "MMM Do, YYYY")))
print(str(Morrow.get("Thursday 2024-02-29", "dddd YYYY-MM-DD")))
print(str(Morrow.get("1709175845123456", "x")))
```

When input text may include extra content, Morrow searches for a valid token match with parse boundaries:

```text
print(str(Morrow.get("June was born in May 1980", "MMMM YYYY")))
```

## Multiple formats

```text
from std.collections import List

var formats = List[String]()
formats.append("YYYY/MM/DD")
formats.append("YYYY-MM-DD HH:mm:ss")

print(str(Morrow.get("2023-01-20 15:49:10", formats)))
```
