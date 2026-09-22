---
sidebar_position: 10
---

# Testing

Run the unit tests with `make test`. Each `tests/test_*.mojo` file uses the standard library's `TestSuite` to discover its `test_` functions. CI runs the same suite with Mojo 1.0.0 and 1.1.0 on Linux x86-64, Linux ARM64, and macOS ARM64, sequentially per platform.

```sh
make test
make test TEST_FILES=tests/test_iana.mojo
uv run mojo run -I . tests/test_iana.mojo --only test_gap_fold_offsets_and_dst
uv run mojo run -I . tests/test_iana.mojo --skip-all
```

`--only` selects test functions; `--skip` excludes them; `--skip-all` collects them without executing their bodies. A collection-only run is not a passing validation run. Test failures make the command exit unsuccessfully.

## What is checked

| Suite | Main checks |
| --- | --- |
| Core and contracts | Construction, leap centuries, bounds, shifts, mixed timezone awareness, comparison, serialization |
| Parsing and formatting | ISO and token formats, fallback lists, extraction boundaries, Unicode literals, invalid inputs, timestamp unit normalization |
| Timezones | Historical offsets, DST folds/gaps, southern hemisphere seasons, half-hour transitions, skipped days, negative fractional instants |
| Locale | All months and weekdays, AM/PM boundaries, aliases, unsupported languages, Chinese relative units and malformed input |
| Iterators | Laziness, independent copies, exhaustion, zero limits, reversed ranges, clipping, partial groups, DST hour sequences |
| Properties | Ordinal, timestamp, duration, fixed-offset, localized date, and IANA conversion invariants |

The property suite runs 1,000 samples per property (6,000 total) with fixed seeds using `std.testing.prop.Rng`. Failures include relevant input context; seeds live beside each test. The same inputs run on both compiler versions. Explicit examples cover boundaries that random sampling may miss. One test function can contain many examples; neither function counts nor sample counts measure source coverage.

The official `PropTest` runner is available too. A minimal runner probe compiled on 1.1 but failed with a generic callback type error on the tested 1.0 compiler, so this project uses the shared seeded generator directly rather than different property suites per compiler.

## Coverage and tooling status

Checked against Mojo 1.0.0 and 1.1.0 on September 22, 2026:

- `TestSuite` provides discovery, selection, skips, timing, and result reports.
- `assert_raises(contains=...)` validates expected errors and their messages.
- `std.testing.prop` provides generators and property-test infrastructure.
- No supported line/branch coverage command or instrumentation option is documented in the CLI. Both tested compilers reject `mojo build --coverage`. This project does **not** publish a source-coverage percentage.
- `--sanitize address` and `--sanitize thread` are experimental runtime checks, not coverage measurement. The local macOS 1.1 probe could not link/load the required ASan runtime symbols; sanitizer checks are not claimed as passing or required CI checks.

Official references: [TestSuite](https://mojolang.org/docs/std/testing/suite/TestSuite/), [assert_raises](https://mojolang.org/docs/std/testing/testing/assert_raises/), [property testing](https://mojolang.org/docs/std/testing/prop/), [compiler options](https://mojolang.org/docs/cli/build/).
