---
sidebar_position: 7
---

# Humanize

Morrow can describe date-time distances in English and apply those distances back to a base value.

## Humanize

```text
from std.collections import List

var present = Morrow(2024, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))

print(present.shift(hours=2).humanize(present))

var granularity = List[String]()
granularity.append("hour")
granularity.append("minute")

print(present.shift(minutes=66).humanize(present, granularity=granularity))
```

Use `only_distance=True` to omit the direction phrase.

## Dehumanize

```text
var present = Morrow(2024, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))

print(str(present.dehumanize("2 days ago")))
print(str(present.dehumanize("in a minute and 6 seconds")))
```

Supported units include years, quarters, months, weeks, days, hours, minutes, and seconds.
