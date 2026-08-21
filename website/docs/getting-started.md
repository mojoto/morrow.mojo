---
sidebar_position: 2
---

# Getting Started

## Install with Pixi

Add the Modular and Modular Community channels to your Pixi workspace, then
install Morrow:

```bash
pixi workspace channel add --prepend https://repo.prefix.dev/modular-community
pixi workspace channel add --prepend https://repo.prefix.dev/max
pixi add morrow
```

The package installs a compiler-compatible `morrow.mojoc` into the active
environment, so it is available to import from other Mojo packages.

## Set up the local environment

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), then run
the following commands from the repository root:

```bash
make install
uv run mojo repl
```

`make install` creates or reuses `.venv` with Python 3.14 and installs the
pinned Mojo version. Starting the REPL from the repository root makes the
`morrow` source package directly importable.

## Use Morrow in another project

Copy the `morrow` directory into your project, or build a precompiled package:

```bash
make build
```

This creates `morrow.mojoc`. A precompiled Mojo package must be imported with
the same Mojo compiler version that created it. Matching artifacts may also be
available from the [GitHub releases page](https://github.com/mojoto/morrow.mojo/releases).

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
