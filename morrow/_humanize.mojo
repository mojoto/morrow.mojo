"""Relative-time helpers behind Morrow.humanize and Morrow.dehumanize."""
from ._calendar import US_PER_SECOND, days_in_month
from .locale import Locale, frame_index
from .morrow import Morrow

from std.collections import List


comptime _HUMANIZE_SECONDS_PER_MONTH = 2635200  # 30.5 days
comptime _HUMANIZE_SECONDS_PER_QUARTER = 7905600  # 91.5 days


def _relative_locale(name: String) raises -> Locale:
    return Locale(name, _names=False, _relative=True)


def _humanize_text(
    value: Morrow,
    other: Morrow,
    only_distance: Bool,
    granularity: String,
    locale: Locale,
) raises -> String:
    """
    Return a human-readable relative difference in the given locale.
    """
    value._check_awareness(other)
    var delta_us = value._utc_microseconds() - other._utc_microseconds()
    var unit = granularity
    if unit != "auto":
        _ = _humanize_unit_seconds(unit)

    if delta_us == 0:
        return locale._describe(0, 0, False, only_distance)

    var rounded_delta_seconds = _rounded_seconds(delta_us)
    var seconds = abs(rounded_delta_seconds)
    if unit == "auto":
        return _humanize_auto(value, other, delta_us, only_distance, locale)
    if unit == "second" and seconds < 2:
        return locale._describe(0, 0, False, only_distance)
    var count = _humanize_count(seconds, unit)
    return _describe_count(
        locale, rounded_delta_seconds, count, unit, only_distance
    )


def _humanize_frame(unit: String, count: Int) raises -> Int:
    if count == 1:
        return frame_index(unit)
    return frame_index(_plural_humanize_unit(unit))


def _describe_count(
    locale: Locale,
    delta_seconds: Int,
    count: Int,
    unit: String,
    only_distance: Bool,
) raises -> String:
    var negative = delta_seconds < 0
    return locale._describe(
        _humanize_frame(unit, count),
        -count if negative else count,
        negative,
        only_distance,
    )


def _dehumanize_en(value: Morrow, input_string: String) raises -> Morrow:
    """
    Shift this Morrow by an English human-readable relative difference.
    """
    if input_string == "just now":
        return value

    var future: Bool
    var phrase: String
    if input_string.byte_length() > 3 and input_string[byte=0:3] == "in ":
        future = True
        phrase = String(input_string[byte=3:])
    elif (
        input_string.byte_length() > 4
        and input_string[byte = input_string.byte_length() - 4 :] == " ago"
    ):
        future = False
        phrase = String(input_string[byte = 0 : input_string.byte_length() - 4])
    else:
        raise Error("humanized string must start with 'in ' or end with ' ago'")

    var result = value
    var parsed = False
    var pos = 0
    while pos < phrase.byte_length():
        while pos < phrase.byte_length() and phrase.as_bytes()[pos] == 32:
            pos += 1
        if pos >= phrase.byte_length():
            break

        var word_start = pos
        while pos < phrase.byte_length() and Int(phrase.as_bytes()[pos]) != ord(
            " "
        ):
            pos += 1
        var count_word = String(phrase[byte=word_start:pos])
        if count_word == "and":
            continue

        var count: Int
        if count_word == "a" or count_word == "an":
            count = 1
        else:
            count = Int(count_word)

        while pos < phrase.byte_length() and phrase.as_bytes()[pos] == 32:
            pos += 1
        if pos >= phrase.byte_length():
            raise Error("humanized distance is invalid")

        var unit_start = pos
        while pos < phrase.byte_length() and Int(phrase.as_bytes()[pos]) != ord(
            " "
        ):
            pos += 1
        var raw_unit = String(phrase[byte=unit_start:pos])
        try:
            var unit = _normalize_dehumanize_unit(count_word, count, raw_unit)
            if not future:
                count = -count
            result = _shift_humanize_unit(result, unit, count)
            parsed = True
        except e:
            if (
                count_word == "1"
                and count == 1
                and _is_singular_humanize_unit(raw_unit)
            ):
                continue
            raise Error("humanized distance is invalid")

    if not parsed:
        raise Error("humanized distance is invalid")
    return result


def _humanize_auto(
    value: Morrow,
    other: Morrow,
    delta_us: Int,
    only_distance: Bool,
    locale: Locale,
) raises -> String:
    var rounded_delta_seconds = _rounded_seconds(delta_us)
    var seconds = abs(rounded_delta_seconds)
    if seconds < 60:
        if seconds < 10:
            return locale._describe(0, 0, False, only_distance)
        return _describe_count(
            locale, rounded_delta_seconds, seconds, "second", only_distance
        )
    elif seconds < 3600:
        if seconds < 120:
            return _describe_count(
                locale, rounded_delta_seconds, 1, "minute", only_distance
            )
        var minutes = seconds // 60
        if minutes < 2:
            minutes = 2
        return _describe_count(
            locale, rounded_delta_seconds, minutes, "minute", only_distance
        )
    elif seconds < 86400:
        if seconds < 7200:
            return _describe_count(
                locale, rounded_delta_seconds, 1, "hour", only_distance
            )
        var hours = seconds // 3600
        if hours < 2:
            hours = 2
        return _describe_count(
            locale, rounded_delta_seconds, hours, "hour", only_distance
        )

    var calendar_months = _humanize_calendar_months(value, other)
    if seconds < 172800:
        return _describe_count(
            locale, rounded_delta_seconds, 1, "day", only_distance
        )
    elif seconds < 604800:
        var days = seconds // 86400
        if days < 2:
            days = 2
        return _describe_count(
            locale, rounded_delta_seconds, days, "day", only_distance
        )
    elif calendar_months >= 1 and seconds < 31536000:
        return _describe_count(
            locale,
            rounded_delta_seconds,
            calendar_months,
            "month",
            only_distance,
        )
    elif seconds < 2592000 and not locale.has_timeframe("weeks"):
        # Locales without week text fall back to days, unlike Arrow.
        return _describe_count(
            locale,
            rounded_delta_seconds,
            seconds // 86400,
            "day",
            only_distance,
        )
    elif seconds < 1209600:
        return _describe_count(
            locale, rounded_delta_seconds, 1, "week", only_distance
        )
    elif seconds < 2592000:
        var weeks = seconds // 604800
        if weeks < 2:
            weeks = 2
        return _describe_count(
            locale, rounded_delta_seconds, weeks, "week", only_distance
        )
    elif seconds < 63072000:
        return _describe_count(
            locale, rounded_delta_seconds, 1, "year", only_distance
        )

    var years = seconds // 31536000
    if years < 2:
        years = 2
    return _describe_count(
        locale, rounded_delta_seconds, years, "year", only_distance
    )


def _humanize_calendar_months(value: Morrow, other: Morrow) raises -> Int:
    var start = other
    var end = value
    if value._utc_microseconds() < other._utc_microseconds():
        start = value
        end = other

    var months = (end.year - start.year) * 12 + end.month - start.month
    var days: Int
    if end.day >= start.day:
        days = end.day - start.day
    else:
        months -= 1
        var previous_year = end.year
        var previous_month = end.month - 1
        if previous_month < 1:
            previous_month = 12
            previous_year -= 1
        days = (
            end.day + days_in_month(previous_year, previous_month) - start.day
        )

    if days > 14:
        months += 1
    if months > 12:
        return 12
    return months


def _rounded_seconds(delta_us: Int) -> Int:
    var sign = 1
    var abs_us = delta_us
    if abs_us < 0:
        sign = -1
        abs_us = -abs_us
    var seconds = abs_us // US_PER_SECOND
    var remainder = abs_us % US_PER_SECOND
    if remainder > US_PER_SECOND // 2:
        seconds += 1
    elif remainder == US_PER_SECOND // 2 and seconds % 2 == 1:
        seconds += 1
    return sign * seconds


def _humanize_count(seconds: Int, unit: String) raises -> Int:
    var unit_seconds = _humanize_unit_seconds(unit)
    return seconds // unit_seconds


def _humanize_unit_seconds(unit: String) raises -> Int:
    if unit == "second":
        return 1
    elif unit == "minute":
        return 60
    elif unit == "hour":
        return 3600
    elif unit == "day":
        return 86400
    elif unit == "week":
        return 604800
    elif unit == "month":
        return _HUMANIZE_SECONDS_PER_MONTH
    elif unit == "quarter":
        return _HUMANIZE_SECONDS_PER_QUARTER
    elif unit == "year":
        return 31536000
    else:
        raise Error("unsupported granularity")


def _normalize_dehumanize_unit(
    count_word: String, count: Int, raw_unit: String
) raises -> String:
    var unit = raw_unit
    if unit.byte_length() > 0 and unit.as_bytes()[unit.byte_length() - 1] == 44:
        var unit_without_comma = String(unit[byte = 0 : unit.byte_length() - 1])
        unit = unit_without_comma^

    if count_word == "a" or count_word == "an":
        if not _is_singular_humanize_unit(
            unit
        ) and not _is_plural_humanize_unit(unit):
            raise Error("humanized distance is invalid")
        var normalized = _normalize_humanize_unit(unit)
        if count_word == "an":
            if normalized != "hour":
                raise Error("humanized distance is invalid")
        elif normalized == "hour":
            raise Error("humanized distance is invalid")
        return normalized

    if not _is_plural_humanize_unit(unit):
        raise Error("humanized distance is invalid")
    return _normalize_humanize_unit(unit)


def _is_singular_humanize_unit(unit: String) -> Bool:
    return (
        unit == "second"
        or unit == "minute"
        or unit == "hour"
        or unit == "day"
        or unit == "week"
        or unit == "month"
        or unit == "quarter"
        or unit == "year"
    )


def _is_plural_humanize_unit(unit: String) -> Bool:
    return (
        unit == "seconds"
        or unit == "minutes"
        or unit == "hours"
        or unit == "days"
        or unit == "weeks"
        or unit == "months"
        or unit == "quarters"
        or unit == "years"
    )


def _normalize_humanize_granularity_list(
    granularity: List[String],
) raises -> List[String]:
    var has_year = False
    var has_quarter = False
    var has_month = False
    var has_week = False
    var has_day = False
    var has_hour = False
    var has_minute = False
    var has_second = False

    for i in range(len(granularity)):
        var unit = granularity[i]
        _ = _humanize_unit_seconds(unit)
        if unit == "year":
            if has_year:
                raise Error("unsupported granularity")
            has_year = True
        elif unit == "quarter":
            if has_quarter:
                raise Error("unsupported granularity")
            has_quarter = True
        elif unit == "month":
            if has_month:
                raise Error("unsupported granularity")
            has_month = True
        elif unit == "week":
            if has_week:
                raise Error("unsupported granularity")
            has_week = True
        elif unit == "day":
            if has_day:
                raise Error("unsupported granularity")
            has_day = True
        elif unit == "hour":
            if has_hour:
                raise Error("unsupported granularity")
            has_hour = True
        elif unit == "minute":
            if has_minute:
                raise Error("unsupported granularity")
            has_minute = True
        elif unit == "second":
            if has_second:
                raise Error("unsupported granularity")
            has_second = True

    var ordered = List[String]()
    if has_year:
        ordered.append("year")
    if has_quarter:
        ordered.append("quarter")
    if has_month:
        ordered.append("month")
    if has_week:
        ordered.append("week")
    if has_day:
        ordered.append("day")
    if has_hour:
        ordered.append("hour")
    if has_minute:
        ordered.append("minute")
    if has_second:
        ordered.append("second")
    return ordered^


def _normalize_humanize_unit(unit: String) raises -> String:
    if unit == "second" or unit == "seconds":
        return "second"
    elif unit == "minute" or unit == "minutes":
        return "minute"
    elif unit == "hour" or unit == "hours":
        return "hour"
    elif unit == "day" or unit == "days":
        return "day"
    elif unit == "week" or unit == "weeks":
        return "week"
    elif unit == "month" or unit == "months":
        return "month"
    elif unit == "quarter" or unit == "quarters":
        return "quarter"
    elif unit == "year" or unit == "years":
        return "year"
    else:
        raise Error("unsupported granularity")


def _plural_humanize_unit(unit: String) raises -> String:
    if unit == "quarter":
        return "quarters"
    return unit + "s"


def _shift_humanize_unit(
    value: Morrow, unit: String, count: Int
) raises -> Morrow:
    if unit == "second":
        return value.shift(seconds=count)
    elif unit == "minute":
        return value.shift(minutes=count)
    elif unit == "hour":
        return value.shift(hours=count)
    elif unit == "day":
        return value.shift(days=count)
    elif unit == "week":
        return value.shift(weeks=count)
    elif unit == "month":
        return value.shift(months=count)
    elif unit == "quarter":
        return value.shift(months=count * 3)
    elif unit == "year":
        return value.shift(years=count)
    else:
        raise Error("unsupported granularity")


def _humanize_granular(
    value: Morrow,
    other: Morrow,
    only_distance: Bool,
    granularity: List[String],
    locale: Locale,
) raises -> String:
    """Describe the distance split across the requested units."""
    if len(granularity) == 0:
        raise Error("granularity cannot be empty")
    if len(granularity) == 1 and granularity[0] == "auto":
        return _humanize_text(value, other, only_distance, "auto", locale)

    var ordered_granularity = _normalize_humanize_granularity_list(granularity)
    value._check_awareness(other)
    var delta_us = value._utc_microseconds() - other._utc_microseconds()
    var rounded_delta_seconds = _rounded_seconds(delta_us)
    var remaining = abs(rounded_delta_seconds)
    if (
        len(ordered_granularity) == 1
        and ordered_granularity[0] == "second"
        and remaining < 2
    ):
        return locale._describe(0, 0, False, only_distance)

    var negative = rounded_delta_seconds < 0
    var frames = List[Int]()
    var deltas = List[Int]()
    for i in range(len(ordered_granularity)):
        var unit = ordered_granularity[i]
        var unit_seconds = _humanize_unit_seconds(unit)
        var count = remaining // unit_seconds
        frames.append(_humanize_frame(unit, count))
        deltas.append(-count if negative else count)
        remaining = remaining % unit_seconds
    if len(frames) == 1:
        return locale._describe(frames[0], deltas[0], negative, only_distance)
    return locale._describe_multi(frames, deltas, negative, only_distance)
