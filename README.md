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

Download `morrow.mojopkg` from
[releases](https://github.com/mojoto/morrow.mojo/releases), build it from this
repository, or vendor the `morrow` directory in your Mojo project.

```bash
make install
make build
```

When using the source directory directly, add the project root to Mojo's import
path:

```bash
uv run mojo run -I . main.mojo
```

## Usage

```mojo
from morrow import FORMAT_RSS, Morrow, TimeZone


def main() raises:
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

## Contributing

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), then:

```bash
make install      # Install Mojo into .venv
make test         # Run tests
make format       # Format sources and tests
make build        # Build morrow.mojopkg
make doc-install  # Install documentation dependencies
make doc-serve    # Serve the built documentation site
```

Local docs are served under `/morrow.mojo/`; Chinese docs are at `http://localhost:3000/morrow.mojo/zh-Hans/`.
