from .util import utf8_width

# Language data shared by formatting, parsing and relative time text.
from .constants import (
    month_name,
    month_abbreviation,
    day_name,
    day_abbreviation,
)


def locale_id(locale: String) raises -> Int:
    if locale == "en" or locale == "en-us" or locale == "en_US":
        return 0
    if (
        locale == "zh"
        or locale == "zh-cn"
        or locale == "zh-CN"
        or locale == "zh-hans"
        or locale == "zh-Hans"
    ):
        return 1
    if (
        locale == "zh-tw"
        or locale == "zh-TW"
        or locale == "zh-hant"
        or locale == "zh-Hant"
    ):
        return 2
    raise Error("unsupported locale: " + locale)


def localized_month(
    month: Int, abbreviated: Bool, locale: String
) raises -> String:
    var language = locale_id(locale)
    if language == 0:
        return month_abbreviation(month) if abbreviated else month_name(month)
    if abbreviated:
        return String(month) + "月"
    var names: List[String] = [
        "一月",
        "二月",
        "三月",
        "四月",
        "五月",
        "六月",
        "七月",
        "八月",
        "九月",
        "十月",
        "十一月",
        "十二月",
    ]
    return names[month - 1]


def localized_weekday(
    day: Int, abbreviated: Bool, locale: String
) raises -> String:
    var language = locale_id(locale)
    if language == 0:
        return day_abbreviation(day) if abbreviated else day_name(day)
    var names: List[String] = ["一", "二", "三", "四", "五", "六", "日"]
    var prefix = "星期"
    if abbreviated:
        prefix = "周" if language == 1 else "週"
    return prefix + names[day - 1]


def starts_at(value: String, position: Int, token: String) -> Bool:
    if position + token.byte_length() > value.byte_length():
        return False
    for i in range(token.byte_length()):
        if value.as_bytes()[position + i] != token.as_bytes()[i]:
            return False
    return True


def localized_format(
    fmt: String, month: Int, day: Int, weekday: Int, hour: Int, locale: String
) raises -> String:
    if locale_id(locale) == 0:
        return fmt
    var result = ""
    var i = 0
    var literal = False
    while i < fmt.byte_length():
        if fmt.as_bytes()[i] == 91:
            literal = True
        elif fmt.as_bytes()[i] == 93:
            literal = False
        if not literal:
            var consumed = 0
            var text = ""
            if starts_at(fmt, i, "MMMM"):
                text = localized_month(month, False, locale)
                consumed = 4
            elif starts_at(fmt, i, "MMM"):
                text = localized_month(month, True, locale)
                consumed = 3
            elif starts_at(fmt, i, "dddd"):
                text = localized_weekday(weekday, False, locale)
                consumed = 4
            elif starts_at(fmt, i, "ddd"):
                text = localized_weekday(weekday, True, locale)
                consumed = 3
            elif starts_at(fmt, i, "Do"):
                text = String(day) + "日"
                consumed = 2
            elif fmt.as_bytes()[i] == 65 or fmt.as_bytes()[i] == 97:
                text = "上午" if hour < 12 else "下午"
                consumed = 1
            if consumed > 0:
                result += "[" + text + "]"
                i += consumed
                continue
        var width = utf8_width(fmt, i)
        result += fmt[byte = i : i + width]
        i += width
    return result


def humanized_text(english: String, locale: String) raises -> String:
    var language = locale_id(locale)
    if language == 0:
        return english
    if english == "just now":
        return "刚刚" if language == 1 else "剛剛"
    if english == "instantly":
        return "立即"
    var result = english
    var suffix = ""
    if starts_at(result, 0, "in "):
        var trimmed = String(result[byte=3:])
        result = trimmed^
        suffix = "后" if language == 1 else "後"
    elif (
        result.byte_length() >= 4
        and result[byte = result.byte_length() - 4 :] == " ago"
    ):
        var trimmed = String(result[byte = 0 : result.byte_length() - 4])
        result = trimmed^
        suffix = "前"
    var source: List[String] = [
        "years",
        "year",
        "quarters",
        "quarter",
        "months",
        "month",
        "weeks",
        "week",
        "days",
        "day",
        "hours",
        "hour",
        "minutes",
        "minute",
        "seconds",
        "second",
    ]
    var target: List[String] = [
        "年",
        "年",
        "个季度",
        "个季度",
        "个月",
        "个月",
        "周",
        "周",
        "天",
        "天",
        "小时",
        "小时",
        "分钟",
        "分钟",
        "秒",
        "秒",
    ]
    result = (
        result.replace("an ", "1 ").replace("a ", "1 ").replace(" and ", " ")
    )
    for i in range(len(source)):
        result = result.replace(source[i], target[i])
    result = result.replace(" ", "")
    if language == 2:
        result = (
            result.replace("个", "個")
            .replace("周", "週")
            .replace("小时", "小時")
            .replace("分钟", "分鐘")
        )
    return result + suffix


def english_relative(text: String, locale: String) raises -> String:
    if locale_id(locale) == 0:
        return text
    if text == "刚刚" or text == "剛剛":
        return "just now"
    var result = (
        text.replace("後", "后")
        .replace("個", "个")
        .replace("週", "周")
        .replace("小時", "小时")
        .replace("分鐘", "分钟")
    )
    var length = result.byte_length()
    var future = False
    if length >= 3 and starts_at(result, length - 3, "后"):
        future = True
    elif length < 3 or not starts_at(result, length - 3, "前"):
        raise Error("relative time must end in 前 or 后/後")
    var trimmed = String(result[byte = 0 : length - 3])
    result = trimmed^
    var source: List[String] = ["个季度", "个月", "小时", "分钟", "年", "周", "天", "秒"]
    var target: List[String] = [
        " quarters ",
        " months ",
        " hours ",
        " minutes ",
        " years ",
        " weeks ",
        " days ",
        " seconds ",
    ]
    for i in range(len(source)):
        result = result.replace(source[i], target[i])
    # The existing parser validates numeric counts and supported units.
    return "in " + result if future else result + " ago"
