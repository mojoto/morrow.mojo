---
sidebar_position: 1
---

# Morrow.mojo

Morrow is a Mojo library for date and time work. It provides an Arrow-inspired API for constructing, parsing, formatting, shifting, comparing, and humanizing date-time values.

The library is UTC by default, supports fixed-offset time zones, and focuses on a compact API that works well inside Mojo projects.

## Core capabilities

- Create `Morrow` values from components, timestamps, ISO 8601 strings, date views, datetime values, and ISO calendar tuples.
- Parse and format strings with Arrow-style tokens and Python-style `strftime`.
- Convert between fixed-offset time zones.
- Shift values by years, quarters, months, weeks, days, hours, minutes, seconds, and microseconds.
- Calculate floor, ceiling, span, range, span range, and interval values.
- Humanize and dehumanize English relative distances.

## Package layout

```text
morrow/
  morrow.mojo       # Morrow date-time type and core APIs
  timezone.mojo     # TimeZone fixed-offset helper
  timedelta.mojo    # TimeDelta duration helper
  formatter.mojo    # format and strftime implementation
```
