# Morrow.mojo: Human-friendly date & time for Mojo 🔥

<p align="center">
  <a href="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml">
    <img src="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml/badge.svg" alt="Test" />
  </a>
  <a href="https://github.com/mojoto/morrow.mojo/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/mojoto/morrow.mojo">
  </a>
</p>

**Morrow** is a Mojo library that provides human-friendly method for managing, formatting, and transforming dates, times, and timestamps.

Morrow is heavily inspired by [arrow](https://github.com/arrow-py/arrow), and thanks for its elegant design.

## Features

- TimeZone-aware and UTC by default.
- Support format and parse strings.
- Support for the [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard.

## Preparation

You have three ways to reference this library:

- Download morrow.mojopkg from [releases](https://github.com/mojoto/morrow.mojo/releases).
- Clone this project and execute `make build` to build morrow.mojopkg.
- Directly copy the `morrow` directory of this project to your own project.

## Usage

```python
from morrow import Morrow, TimeZone

# Get local date and time.
var now = Morrow.now()
print(str(now))  # 2023-10-01T20:10:25.188957+08:00

# Get UTC date and time.
var utcnow = Morrow.utcnow()
print(str(utcnow))  # 2023-10-01T20:10:25.954638+00:00

# Get local time from POSIX timestamp.
var t = Morrow.fromtimestamp(1696089600)
print(str(t))  # 2023-10-01T00:00:00.000000+08:00

# Get UTC time from POSIX timestamp.
var utc_t = Morrow.utcfromtimestamp(1696089600)
print(str(utc_t))  # 2023-09-30T16:00:00.000000+00:00

# Get ISO format.
var m = Morrow(2023, 10, 1, 0, 0, 0, 1234)
print(m.isoformat())  # 2023-10-01T00:00:00.001234

# custom format
var m = Morrow(2023, 10, 1, 0, 0, 0, 1234)
print(m.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))  # 2023-10-01 00:00:00.001234 +00:00
print(m.format("dddd, DD MMM YYYY HH:mm:ss ZZZ"))  # Sunday, 01 Oct 2023 00:00:00 UTC
print(m.format("YYYY[Y]MM[M]DD[D]"))  # 2023Y10M01D

# Get ISO format with time zone.
var m_beijing = Morrow(2023, 10, 1, 0, 0, 0, 1234, TimeZone(28800, 'Bejing'))
print(m_beijing.isoformat(timespec="seconds"))  # 2023-10-01T00:00:00+08:00

# Get time zone offset.
print(TimeZone.from_utc('UTC+08:00').offset)  # 28800

# Subtract two dates.
var timedelta = Morrow(2023, 10, 2, 10, 0, 0) - Morrow(2023, 10, 1, 10, 0, 0)
print(str(timedelta))  # 1 day, 0:00:00

# Return proleptic Gregorian ordinal for the year, month and day.
var m_10_1 = Morrow(2023, 10, 1)
var ordinal = m_10_1.toordinal()
print(ordinal)  # 738794

# Construct a Morrow from a proleptic Gregorian ordinal.
var m_10_1_ = Morrow.fromordinal(ordinal)
print(str(m_10_1_))  # 2023-10-01T00:00:00.000000

# Convert Morrow to python datetime
var py_dt = now.to_py()
print(py_dt.isoformat())  # 2023-10-01T20:10:25.188957

# Convert python datetime to Morrow
var m_from_py = Morrow.from_py(py_dt)
print(m_from_py)  # 2023-10-01T20:10:25.188957

```
