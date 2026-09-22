from std.testing import assert_equal, assert_true, assert_raises, TestSuite
from morrow import Morrow


def test_chinese_format_and_parse() raises:
    var dt = Morrow(2024, 11, 5, 15, 4)
    var fmt = "YYYY MMMM Do dddd A hh:mm [literal MMMM]"
    var text = dt.format(fmt, locale="zh-CN")
    assert_equal(text, "2024 十一月 5日 星期二 下午 03:04 literal MMMM")
    assert_equal(String(Morrow.get(text, fmt, locale="zh-CN")), String(dt))
    var short = dt.format("YYYY MMM DD ddd a hh:mm", locale="zh-TW")
    assert_equal(short, "2024 11月 05 週二 下午 03:04")
    assert_equal(
        String(Morrow.get(short, "YYYY MMM DD ddd a hh:mm", locale="zh-TW")),
        String(dt),
    )
    assert_equal(dt.format("MMMM", locale="en"), "November")
    var rejected = False
    try:
        _ = dt.format(locale="not-a-language")
    except e:
        rejected = True
    assert_true(rejected)


def test_chinese_relative_time() raises:
    var base = Morrow(2024, 1, 1)
    assert_equal(base.shift(hours=-2).humanize(base, locale="zh-CN"), "2小时前")
    assert_equal(base.shift(hours=2).humanize(base, locale="zh-TW"), "2小時後")
    assert_equal(base.humanize(base, locale="zh-CN"), "刚刚")
    assert_equal(
        base.shift(hours=2).humanize(base, only_distance=True, locale="zh-CN"),
        "2小时",
    )
    var units: List[String] = ["hour", "minute"]
    assert_equal(
        base.shift(minutes=66).humanize(
            base, granularity=units, locale="zh-TW"
        ),
        "1小時6分鐘後",
    )
    assert_true(base.dehumanize("2天前", locale="zh-CN") == base.shift(days=-2))
    assert_true(base.dehumanize("1個月後", locale="zh-TW") == base.shift(months=1))
    assert_true(
        base.dehumanize("1小时6分钟后", locale="zh-CN") == base.shift(minutes=66)
    )


def test_unicode_literals_and_whitespace() raises:
    var dt = Morrow(2024, 11, 5)
    assert_equal(dt.format("YYYY年MM月DD日[ 🌙]"), "2024年11月05日 🌙")
    assert_equal(dt.strftime("%Y年%m月%d日 🌙"), "2024年11月05日 🌙")
    assert_true(Morrow.get("2024年11月05日 🌙", "YYYY年MM月DD日[ 🌙]") == dt)
    assert_true(
        Morrow.get(
            "  2024  十一月  05  ",
            "YYYY MMMM DD",
            locale="zh-CN",
            normalize_whitespace=True,
        )
        == dt
    )
    var formats: List[String] = ["YYYY-MM-DD", "YYYY MMMM DD"]
    assert_true(Morrow.get("2024 十一月 05", formats, locale="zh-CN") == dt)


def test_all_month_names_round_trip() raises:
    var locales: List[String] = ["en", "zh-CN", "zh-TW"]
    var formats: List[String] = ["YYYY MMM DD", "YYYY MMMM DD"]
    for locale in locales:
        for fmt in formats:
            for month in range(1, 13):
                var dt = Morrow(2024, month, 15)
                assert_true(
                    Morrow.get(
                        dt.format(fmt, locale=locale), fmt, locale=locale
                    )
                    == dt
                )


def test_all_weekday_names_round_trip() raises:
    var locales: List[String] = ["en", "zh-CN", "zh-TW"]
    var formats: List[String] = ["YYYY-MM-DD ddd", "YYYY-MM-DD dddd"]
    for locale in locales:
        for fmt in formats:
            for day in range(1, 8):
                var dt = Morrow(2024, 1, day)
                assert_true(
                    Morrow.get(
                        dt.format(fmt, locale=locale), fmt, locale=locale
                    )
                    == dt
                )


def test_meridiem_midnight_and_noon() raises:
    for hour in [0, 1, 11, 12, 13, 23]:
        var dt = Morrow(2024, 1, 1, hour)
        var fmt = "YYYY-MM-DD A hh:mm"
        assert_true(
            Morrow.get(dt.format(fmt, locale="zh-CN"), fmt, locale="zh-CN")
            == dt
        )


def test_locale_aliases() raises:
    var dt = Morrow(2024, 1, 1)
    var simplified: List[String] = [
        "zh",
        "zh-cn",
        "zh-CN",
        "zh-hans",
        "zh-Hans",
    ]
    for locale in simplified:
        assert_equal(dt.format("ddd", locale=locale), "周一")
    var traditional: List[String] = ["zh-tw", "zh-TW", "zh-hant", "zh-Hant"]
    for locale in traditional:
        assert_equal(dt.format("ddd", locale=locale), "週一")


def test_unknown_locale_rejected_by_every_entrypoint() raises:
    var dt = Morrow(2024, 1, 1)
    with assert_raises(contains="unsupported locale"):
        _ = dt.format("YYYY", locale="unknown")
    with assert_raises(contains="unsupported locale"):
        _ = Morrow.get("2024", "YYYY", locale="unknown")
    with assert_raises(contains="unsupported locale"):
        _ = dt.humanize(dt, locale="unknown")
    with assert_raises(contains="unsupported locale"):
        _ = dt.dehumanize("1天前", locale="unknown")


def test_localized_invalid_month_and_meridiem() raises:
    with assert_raises():
        _ = Morrow.get("2024 十三月 01", "YYYY MMMM DD", locale="zh-CN")
    with assert_raises():
        _ = Morrow.get("2024-01-01 中午 12", "YYYY-MM-DD A hh", locale="zh-CN")
    with assert_raises():
        _ = Morrow.get("2024-01-01 下午 25", "YYYY-MM-DD A hh", locale="zh-CN")


def test_localized_literal_mismatch_and_trailing_input() raises:
    with assert_raises():
        _ = Morrow.get("2024年01月01错", "YYYY年MM月DD日")
    with assert_raises():
        _ = Morrow.get("2024 十一月 05extra", "YYYY MMMM DD", locale="zh-CN")
    assert_equal(
        Morrow(2024, 1, 1).format("[MMMM dddd A] YYYY", locale="zh-CN"),
        "MMMM dddd A 2024",
    )


def test_chinese_relative_unit_round_trips() raises:
    var dt = Morrow(2024, 1, 15)
    var units: List[String] = ["second", "minute", "hour", "day", "week"]
    var seconds: List[Int] = [1, 60, 3600, 86400, 604800]
    var locales: List[String] = ["zh-CN", "zh-TW"]
    for locale in locales:
        for i in range(len(units)):
            for sign in [-1, 1]:
                var shifted = dt.shift(seconds=seconds[i] * 2 * sign)
                var text = shifted.humanize(
                    dt, granularity=units[i], locale=locale
                )
                assert_true(dt.dehumanize(text, locale=locale) == shifted)


def test_invalid_chinese_relative_input() raises:
    var dt = Morrow(2024, 1, 1)
    var values: List[String] = ["", "🌙", "明天", "一天后", "3火星后", "1小时", "后"]
    for value in values:
        with assert_raises():
            _ = dt.dehumanize(value, locale="zh-CN")


def test_chinese_calendar_relative_units() raises:
    var dt = Morrow(2024, 1, 31)
    assert_true(dt.dehumanize("1个月后", locale="zh-CN") == Morrow(2024, 2, 29))
    assert_true(dt.dehumanize("1個季度後", locale="zh-TW") == Morrow(2024, 4, 30))
    assert_true(dt.dehumanize("1年前", locale="zh-CN") == Morrow(2023, 1, 31))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
