from std.testing import assert_equal, assert_true, assert_raises, TestSuite
from morrow import Morrow


def test_invalid_iso_unicode_is_rejected() raises:
    var values: List[String] = [
        "年1",
        "🌙1",
        "年🌙-01-01",
        "2024-年-01",
        "2024-01-🌙",
        "2024-01-01T🌙:00",
        "2024-01-01T00:00:00+🌙",
    ]
    for value in values:
        with assert_raises():
            _ = Morrow.fromisoformat(value)


def test_invalid_iso_calendar_fields() raises:
    var values: List[String] = [
        "0000-01-01",
        "2024-00-01",
        "2024-13-01",
        "2024-02-30",
        "2023-02-29",
        "2024-01-00",
        "2024-01-32",
    ]
    for value in values:
        with assert_raises():
            _ = Morrow.fromisoformat(value)


def test_invalid_iso_time_fields() raises:
    var values: List[String] = [
        "2024-01-01T25:00",
        "2024-01-01T24:01",
        "2024-01-01T23:60",
        "2024-01-01T23:59:60",
    ]
    for value in values:
        with assert_raises():
            _ = Morrow.fromisoformat(value)


def test_iso_end_of_day_rollover() raises:
    assert_true(Morrow.fromisoformat("2024-02-29T24:00") == Morrow(2024, 3, 1))
    assert_true(Morrow.fromisoformat("2023-12-31T24:00Z") == Morrow(2024, 1, 1))
    with assert_raises():
        _ = Morrow.fromisoformat("9999-12-31T24:00")


def test_iso_week_year_boundaries() raises:
    assert_true(Morrow.fromisoformat("2020-W53-7") == Morrow(2021, 1, 3))
    assert_true(Morrow.fromisoformat("2021-W01-1") == Morrow(2021, 1, 4))
    with assert_raises():
        _ = Morrow.fromisoformat("2021-W53-1")


def test_format_fallback_exhaustion() raises:
    var formats: List[String] = ["YYYY/MM/DD", "YYYY-MM-DD"]
    with assert_raises():
        _ = Morrow.get("not a date", formats)
    var empty = List[String]()
    with assert_raises():
        _ = Morrow.get("2024-01-01", empty)


def test_strptime_unicode_literal_round_trip() raises:
    var dt = Morrow(2024, 2, 29, 15, 4, 5, 123456)
    var fmt = "%Y年%m月%d日 🌙 %H:%M:%S.%f %z"
    assert_true(Morrow.strptime(dt.strftime(fmt), fmt) == dt)


def test_strptime_requires_complete_input() raises:
    with assert_raises():
        _ = Morrow.strptime("2024-01-01 trailing", "%Y-%m-%d")
    with assert_raises():
        _ = Morrow.strptime("2024-01", "%Y-%m-%d")


def test_token_extraction_respects_boundaries() raises:
    assert_true(
        Morrow.get("date: 2024-02-29 done", "YYYY-MM-DD") == Morrow(2024, 2, 29)
    )
    with assert_raises():
        _ = Morrow.get("prefix2024-02-29suffix", "YYYY-MM-DD")


def test_timestamp_unit_normalization() raises:
    var expected = Morrow(2024, 1, 1)
    assert_true(Morrow.utcfromtimestamp(1704067200) == expected)
    assert_true(Morrow.utcfromtimestamp(1704067200000) == expected)
    assert_true(Morrow.utcfromtimestamp(1704067200000000) == expected)
    assert_equal(Morrow.utcfromtimestamp(32503737600).year, 3000)
    with assert_raises():
        _ = Morrow.utcfromtimestamp("not numeric")


def test_nonfinite_and_out_of_range_timestamps() raises:
    var invalid: List[String] = ["nan", "inf", "-inf", "-1e30"]
    for value in invalid:
        with assert_raises():
            _ = Morrow.utcfromtimestamp(value)
    with assert_raises():
        _ = Morrow.utcfromtimestamp(-9223372036854775807)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
