# Morrow.mojo: Human-friendly date & time for Mojo 🔥


**Morrow** is Mojo library that provides human-friendly method for managing, formatting, and transforming dates, times, and timestamps.

Morrow is heavily inspired by [arrow](https://github.com/arrow-py/arrow), and thanks for its elegant design.


## Features

- TimeZone-aware and UTC by default
- Support format and parse strings
- Support for the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard


## Usage

```python
from morrow import Morrow, TimeZone

# Get local date and time.
let now = Morrow.now()
print(now.__str__())  # 2023-10-01T20:10:25.188957+08:00

# Get UTC date and time.
let utcnow = Morrow.utcnow()
print(utcnow.__str__())  # 2023-10-01T20:10:25.954638+00:00

# Get local time from POSIX timestamp.
let t = Morrow.fromtimestamp(1696089600)
print(t.__str__())  # 2023-10-01T00:00:00.000000+08:00

# Get UTC time from POSIX timestamp.
let utc_t = Morrow.utcfromtimestamp(1696089600)
print(utc_t.__str__())  # 2023-09-30T16:00:00.000000+00:00

# Get ISO format.
let m = Morrow(2023, 10, 1, 0, 0, 0, 1234)
print(m.isoformat())  # 2023-10-01T00:00:00.001234

# Get ISO format with time zone.
let m_beijing = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, 'Bejing'))
print(m_beijing.isoformat(timespec="seconds"))  # 2023-10-01T00:00:00+08:00

# Get time zone offset.
print(TimeZone.from_utc('UTC+08:00').offset)  # 28800

# Subtract two dates.
let timedelta = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
print(timedelta.__str__())  # 1 day 0:00:00
```
