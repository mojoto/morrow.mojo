---
sidebar_position: 2
---

# Getting Started

## Install

Download `morrow.mojopkg` from the GitHub releases page, or build it from this repository:

```bash
make install
make build
```

You can also copy the `morrow` directory into a Mojo project when you want to vendor the source directly.

## Import

```text
from morrow import Morrow, TimeDelta, TimeZone
```

## Create values

```text
var now = Morrow.now()
var utc_now = Morrow.utcnow()
var from_timestamp = Morrow.utcfromtimestamp("1767225600.5")
var from_iso = Morrow.fromisoformat("20260101T030405.123456Z")
var fixed = Morrow.get(1767225600.5, "+05:30")
```

## Format output

```text
var value = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))

print(value)
print(value.isoformat())
print(value.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(value.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))
```
