---
sidebar_position: 2
---

# Getting Started

## Install with Pixi

Morrow is available from the
[official Modular Community channel](https://prefix.dev/channels/modular-community/packages/morrow).
From a Pixi workspace
[already configured for Mojo](https://docs.modular.com/mojo/manual/install/),
add the Modular Community channel and install Morrow:

```bash
pixi workspace channel add --prepend https://repo.prefix.dev/modular-community
pixi add morrow
```

The package installs a compiler-compatible `morrow.mojoc` into the active
environment, so it is available to import from other Mojo packages.

## Develop from source

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), then run
the following commands from the repository root:

```bash
make install
uv run mojo repl
```

`make install` creates or reuses `.venv` with Python 3.14 and installs the
pinned Mojo version. Starting the REPL from the repository root makes the
`morrow` source package directly importable.

## Build a local package

For local testing or distribution without Pixi, build a precompiled package:

```bash
make build
```

This creates `morrow.mojoc`. A precompiled Mojo package must be imported with
the same Mojo compiler version that created it. For normal projects, prefer the
Modular Community package above so Pixi can resolve the declared Mojo
compatibility.

## Import

```mojo
from morrow import Morrow, TimeDelta, TimeZone
```

## Create values

```mojo
var now = Morrow.now()
var utc_now = Morrow.utcnow()
var from_timestamp = Morrow.utcfromtimestamp("1767225600.5")
var from_iso = Morrow.fromisoformat("20260101T030405.123456Z")
var fixed = Morrow.get(1767225600.5, "+05:30")
```

## Format output

```mojo
var value = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))

print(value)
print(value.isoformat())
print(value.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(value.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))
```
