# Morrow.mojo

Human-friendly date and time utilities for Mojo. Morrow provides an
date-time API for creating, parsing, formatting, shifting, comparing, and
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
environment, so it can be imported without copying source files. Morrow 1.1 on
the channel is built for Mojo 1.1; projects on Mojo 1.0 resolve Morrow 0.7.0
there, so use the matching
[release archive](https://github.com/mojoto/morrow.mojo/releases) to get 1.1
on Mojo 1.0.

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

Morrow is UTC by default, supports IANA and fixed-offset time zones, parses ISO 8601
strings and POSIX timestamps, and formats values with date/time tokens or
Python-style `strftime`. Formatting, parsing, and relative time support 81
languages, and custom locales can be defined with `Locale`. Named and local time
zones read the system tzdata, falling back to ICU when a zone file is missing
(ICU is provided by macOS; install `libicu-dev` on Debian/Ubuntu).

## Development

Source builds support Mojo 1.0.0 and 1.1.0. Use `make install MOJO_VERSION=1.0.0`
to select 1.0 (the default is 1.1.0), then run `make test build`.
CI tests and precompiles both versions on Linux x86-64, Linux ARM64, and macOS ARM64.
Release archives are built separately for each compiler version; choose the matching archive.
Mojo 1.1 emits deprecation warnings for the string API retained for 1.0 compatibility.

`make package` builds one Conda package per supported compiler, each requiring its
exact Mojo compiler version. The Modular Community channel builds a single compiler
per recipe and currently publishes the Mojo 1.1 build.


Run `make help` to list the available targets.

| Target | Description |
| --- | --- |
| `make install` | Create or reuse `.venv` and install the pinned Mojo version with uv |
| `make test` | Run every `tests/test_*.mojo` file |
| `make test-package` | Build and test the precompiled package outside the source checkout |
| `make benchmark` | Run five samples of each performance benchmark |
| `make format` | Format the `morrow` and `tests` directories |
| `make build` | Precompile `morrow` as `morrow.mojoc` |
| `make package` | Build the distributable Conda package with `rattler-build` |
| `make clean` | Remove `morrow.mojoc` |
| `make doc-install` | Install Docusaurus dependencies |
| `make doc-build` | Build the Docusaurus static site |
| `make doc-serve` | Serve the built Docusaurus site |
| `make doc-clean` | Remove generated Docusaurus files |

### Source layout

The public API is what `morrow/__init__.mojo` exports. Underscored modules are
private; the functions they share with other modules have no leading underscore.

| Module | Responsibility |
| --- | --- |
| `morrow.mojo` | The `Morrow` type: construction, accessors, conversion, arithmetic |
| `_values.mojo`, `_ranges.mojo` | Date, time and span views; lazy range iterators |
| `_parser.mojo` | ISO 8601, Arrow token and strptime parsing |
| `formatter.mojo` | Arrow token and strftime formatting |
| `_humanize.mojo`, `locale.mojo` | Relative time text and per-locale rules |
| `_locale_data.mojo` | Built-in locale records derived from Arrow 1.4.0 |
| `timezone.mojo`, `_tzif.mojo`, `_icu.mojo` | Fixed offsets, system tzdata, ICU fallback |
| `timedelta.mojo` | `TimeDelta` |
| `_calendar.mojo`, `_text.mojo`, `_libc.mojo` | Shared calendar math, byte-level text helpers, libc calls |

The documentation targets require Node.js and npm. Run `make doc-install` before
building the documentation, then use `make doc-build` followed by
`make doc-serve` to preview the built site.

See the [testing guide](https://mojoto.github.io/morrow.mojo/docs/testing) and
[1.x stability contract](https://mojoto.github.io/morrow.mojo/docs/stability) for
validation commands, compiler compatibility, and distribution guarantees.
