# Morrow.mojo: Human-friendly date & time for Mojo 🔥


**Morrow** is Mojo library that provides human-friendly method for managing, formatting, and transforming dates, times, and timestamps.

Morrow is heavily inspired by [arrow](https://github.com/arrow-py/arrow), and thanks for its elegant design.


## Features

- Timezone-aware and UTC by default
- Support format and parse strings
- Support for the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard


## Usage

```python
from morrow import Morrow, TimeZone

# Get local date and time.
var result = Morrow.now()
print(result.__str__())

# Get UTC date and time.
result = Morrow.utcnow()
print(result.__str__())

# Get local time from POSIX timestamp.
result = Morrow.fromtimestamp(1696089600)
print(result.__str__())

# Get UTC time from POSIX timestamp.
result = Morrow.utcfromtimestamp(1696089600)
print(result.__str__())

# Get ISO format.
result = Morrow(2023, 10, 1, 0, 0, 0, 1234)
print(result.isoformat())  # "2023-10-01T00:00:00.001234"

# Get ISO format with time zone.
result = Morrow(2023, 10, 1, 0, 0, 0, 1234, Timezone(28800, 'Bejing'))
print(result.isoformat(timespec="seconds"))  # "2023-10-01T00:00:00+08:00"

# Get time zone offset.
print(Timezone.from_utc('UTC+08:00').offset)  # 28800

# Subtract two dates.
Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
```
