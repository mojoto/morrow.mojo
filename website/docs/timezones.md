---
sidebar_position: 5
---

# Time Zones

Morrow supports UTC, fixed offsets, IANA region names, and the host's local timezone. Date construction defaults to UTC.

```text
from morrow import Morrow, TimeZone, TimeDelta

var utc = Morrow(2024, 7, 1)
print(utc.to("America/New_York"))
print(utc.to("Asia/Shanghai"))
print(utc.to("+05:30"))

var ny = TimeZone.from_name("America/New_York")
var local = Morrow(2024, 7, 1, 12, tz=ny)
```

`TimeZone.from_utc(...)` parses `UTC`, `GMT`, `Z`, `+0530`, `+05:30`, and second-level offsets. `TimeZone.from_name(...)` validates a region identifier. `TimeZone(offset, name)` remains a fixed offset with a display label; labeling it with a region name does not attach timezone rules.

`to(...)` preserves the instant. `replace(tzinfo=...)` preserves the wall-clock fields and interprets them in the new timezone. Named-zone offsets are resolved for each date, including historical rules. `get(text, format)` and `strptime(text, format)` accept region names through `ZZZ` and `%Z` respectively.

## Repeated and missing times

```text
var early = Morrow(2024, 11, 3, 1, 30, tz=ny, fold=0)
var late = early.replace(fold=1)
print(early.ambiguous())  # True
print((late - early).total_seconds())  # 3600

var missing = Morrow(2024, 3, 10, 2, 30, tz=ny)
print(missing.imaginary())  # True
print(missing.to(ny))  # 03:30 after the gap
```

`fold=0` chooses the earlier occurrence of a repeated time; `fold=1` chooses the later occurrence. For a missing time, fold 0 uses the pre-transition offset and fold 1 the post-transition offset. Construction preserves missing wall fields so they can be inspected; converting to the same zone resolves the instant into an existing wall time.

## Calendar shifts and elapsed durations

```text
var before = Morrow(2024, 3, 9, 12, tz=ny)
print(before.shift(days=1))   # next day at 12:00, 23 elapsed hours
print(before.shift(hours=24)) # next day at 13:00, 24 elapsed hours
print(before + TimeDelta(days=1)) # also 24 elapsed hours
```

Years, quarters, months, weeks, days and weekdays use calendar arithmetic. Hours and smaller units, and `TimeDelta` addition/subtraction, use elapsed time. Mixed shifts apply calendar fields first. Calendar shifts resolve missing times by default; pass `check_imaginary=False` to preserve them. Day spans can contain 23 or 25 hours; hourly iterators can include both occurrences of a repeated hour.

## Runtime and timezone data

Named and local timezones use ICU's calendar and timezone data through native FFI; Python is not required. macOS provides ICU. Linux requires the ICU runtime (on Debian/Ubuntu, `sudo apt-get install libicu-dev` installs the library and linker name). The Conda recipe declares ICU as a runtime dependency. An active Conda environment's ICU library is preferred, followed by the system library. UTC and fixed-offset calculations do not load ICU.

Timezone rule updates come from updating the selected ICU package or the operating system. Different ICU data versions may reflect different government rule updates. If the library or timezone is unavailable, operations raise an error rather than falling back to UTC.

`now()` and `fromtimestamp()` use the host local timezone; set `TZ` before process startup when an explicit local zone is needed. Changing process timezone settings after ICU initialization is not supported. For independent zones in one process, use explicit region names.
