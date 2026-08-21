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

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), then set up
the project-local Mojo environment:

```bash
make install
```

`make install` creates or reuses `.venv` with Python 3.14, installs Mojo with
prerelease versions allowed, and prints the installed version. All Mojo targets
in the Makefile run through `uv run mojo`.

Start the Mojo REPL from the project root to use the source package directly:

```bash
uv run mojo repl
```

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

## Using Morrow in another project

Copy the `morrow` source directory into your project, or build a precompiled
package:

```bash
make build
```

This creates `morrow.mojoc`. Precompiled Mojo packages are tied to the compiler
version that created them, so use the same Mojo version when importing one.
Matching artifacts may also be available from
[releases](https://github.com/mojoto/morrow.mojo/releases).

## Development

Run `make help` to list the available targets.

| Target | Description |
| --- | --- |
| `make install` | Create or reuse `.venv` and install Mojo with uv (prereleases allowed) |
| `make test` | Run every `tests/test_*.mojo` file |
| `make format` | Format the `morrow` and `tests` directories |
| `make build` | Precompile `morrow` as `morrow.mojoc` |
| `make clean` | Remove `morrow.mojoc` |
| `make doc-install` | Install Docusaurus dependencies |
| `make doc-build` | Build the Docusaurus static site |
| `make doc-serve` | Serve the built Docusaurus site |
| `make doc-clean` | Remove generated Docusaurus files |

The documentation targets require Node.js and npm. Run `make doc-install` before
building the documentation, then use `make doc-build` followed by
`make doc-serve` to preview the built site.
