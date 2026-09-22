from std.testing import assert_equal, assert_true, TestSuite
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


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
