---
sidebar_position: 5
---

# Time Zones

`TimeZone` represents fixed-offset time zones. `Morrow` is UTC by default, and accepts `TimeZone` values or UTC offset strings in most APIs that take a time zone.

```text
from morrow import Morrow, TimeZone

var utc = Morrow(2026, 1, 1, 16, 30, 0, 123456, TimeZone.from_utc("UTC"))

print(utc.to("+08:00"))
print(utc.astimezone("-05:00"))
print(utc.utcoffset().total_seconds())
```

## Offset parsing

```text
print(TimeZone.from_utc("UTC+08:00").offset)
print(TimeZone.from_utc("+05:30").format())
print(TimeZone.from_utc("-05:30:15").format())
```

`UTC`, `GMT`, `Z`, compact offsets such as `+0530`, and second-level offsets such as `+05:30:15` are supported.

## Local time

```text
var local_now = Morrow.now("local")
print(local_now.tz.name)
```

The local zone is read from the host environment.
