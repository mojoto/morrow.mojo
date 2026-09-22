# Morrow.mojo

Human-friendly date and time utilities for Mojo. Morrow provides an
Arrow-inspired API for creating, parsing, formatting, shifting, comparing, and
humanizing date-time values.

<p align="center">
  <a href="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml">
    <img src="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml/badge.svg" alt="Test" />
  </a>
  <a href="https://github.com/mojoto/morrow.mojo/actions/workflows/pages.yml">
    <img src="https://github.com/mojoto/morrow.mojo/actions/workflows/pages.yml/badge.svg" alt="Documentation" />
  </a>
  <a href="https://github.com/mojoto/morrow.mojo/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/mojoto/morrow.mojo">
  </a>
</p>

Language: English | [中文](README.zh-CN.md)

> Documentation: https://mojoto.github.io/morrow.mojo/

## Installation

Morrow is available from the
[official Modular Community channel](https://prefix.dev/channels/modular-community/packages/morrow).
From a Pixi workspace
[already configured for Mojo](https://docs.modular.com/mojo/manual/install/),
add the Modular Community channel and install Morrow:

```bash
pixi workspace channel add --prepend https://repo.prefix.dev/modular-community
pixi add morrow
```

The package installs a compiler-compatible `morrow.mojoc` into the active Pixi
environment, so it can be imported without copying source files.

## Usage

Paste the following example into the REPL:

```mojo
from morrow import FORMAT_RSS, Morrow, TimeZone

var now = Morrow.now()
print(now)

var utc = Morrow.utcnow()
print(utc)

var parsed = Morrow.get("2026-01-01 03:04:05Z")
print(parsed)
print(parsed.format("YYYY-MM-DD HH:mm:ss ZZ"))

var beijing = parsed.to("+08:00")
print(beijing)

var hour = beijing.span("hour")
print(hour)

print(beijing.isocalendar())
print(beijing.timetuple())

var rss = Morrow(2026, 1, 1, 10, 30, 35, 0, TimeZone(0, "UTC"))
print(rss.format(FORMAT_RSS))
```

Morrow is UTC by default, supports fixed-offset time zones, parses ISO 8601
strings and POSIX timestamps, and formats values with Arrow-style tokens or
Python-style `strftime`.

## Development

Source builds support Mojo 1.0.0 and 1.1.0. Use `make install MOJO_VERSION=1.0.0`
to select 1.0 (the default is 1.1.0), then run `make test build`.
CI tests and precompiles both versions on Linux x86-64, Linux ARM64, and macOS ARM64.
Release archives are built separately for each compiler version; choose the matching archive.
Mojo 1.1 emits deprecation warnings for the string API retained for 1.0 compatibility.

Run `make help` to list the available targets.

| Target | Description |
| --- | --- |
| `make install` | Create or reuse `.venv` and install the pinned Mojo version with uv |
| `make test` | Run every `tests/test_*.mojo` file |
| `make format` | Format the `morrow` and `tests` directories |
| `make build` | Precompile `morrow` as `morrow.mojoc` |
| `make package` | Build the distributable Conda package with `rattler-build` |
| `make clean` | Remove `morrow.mojoc` |
| `make doc-install` | Install Docusaurus dependencies |
| `make doc-build` | Build the Docusaurus static site |
| `make doc-serve` | Serve the built Docusaurus site |
| `make doc-clean` | Remove generated Docusaurus files |

The documentation targets require Node.js and npm. Run `make doc-install` before
building the documentation, then use `make doc-build` followed by
`make doc-serve` to preview the built site.
