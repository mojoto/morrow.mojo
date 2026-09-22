---
sidebar_position: 11
---

# Stability and Distribution

## Version 1 contract

The APIs listed in the [API reference](./api-reference.md), their documented defaults, and documented behavior form Morrow's 1.x source compatibility contract. Additive functionality is released in minor versions; fixes are released in patch versions. Intentional incompatible changes to this contract require a major version and migration notes. Underscore-prefixed helpers and undocumented implementation state are not part of the contract.

Dates use the proleptic Gregorian calendar, years 1–9999, and microsecond resolution. UTC is the default; naive values are explicit. Invalid calendar fields and unsupported timezone/locale inputs raise errors. Leap seconds are not represented. See [timezones](./timezones.md) for repeated/missing local time and elapsed versus calendar arithmetic, and [parsing](./parsing.md) for timestamp unit rules.

Locale support covers English, Simplified Chinese and Traditional Chinese. General natural-language parsing, arbitrary regular expressions, and Windows distributions are outside the supported surface.

Timezone rules belong to the installed ICU data. A rule update can change a historical or future offset without a Morrow API change. Use the same ICU data version when identical rules across machines are required.

## Compiler and platform support

| Platform | Mojo versions |
| --- | --- |
| Linux x86-64 | 1.0.0, 1.1.0 |
| Linux ARM64 | 1.0.0, 1.1.0 |
| macOS ARM64 | 1.0.0, 1.1.0 |

Precompiled `.mojoc` files are tied to the compiler and target platform. Source compatibility does not imply binary compatibility between Mojo versions. Select the release archive matching both; a new compiler version is supported after validation and publication of matching artifacts.

Named and local timezones require ICU. macOS provides it; on Debian/Ubuntu install `libicu-dev`. Conda declares ICU as a runtime dependency. UTC and fixed-offset operations do not require ICU.

## Release verification

Each release contains six archives and `SHA256SUMS`. Every archive is extracted on its target platform and tested by a consumer outside the source checkout before upload. The consumer exercises construction, parsing, formatting, duration arithmetic, DST folds, localization, lazy iteration, and expected errors.

```sh
sha256sum --check SHA256SUMS
# macOS:
shasum -a 256 --check SHA256SUMS
```

The checksum commands above expect all listed archives in the same directory. For a single downloaded archive, compare its hash with that filename's entry in `SHA256SUMS`.

For local development:

```sh
make test-package
python3 tools/check_package.py path/to/archive.tar.gz --mojo /absolute/path/to/mojo
make benchmark
```

`test-package` builds the library and runs the same isolated consumer check. Override `MOJO` and `MOJO_BIN` together when using a compiler outside `.venv`. The benchmark emits five samples each for UTC shifts, ISO round trips, IANA conversions and lazy ranges. Compilation time is outside the measured sections; checksums keep results observable. Compare medians on the same machine/compiler. Timings are informational, with no cross-machine CI threshold.

For test coverage and tooling limits, see [testing](./testing.md).
