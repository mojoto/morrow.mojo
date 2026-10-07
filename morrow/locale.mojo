"""Locale data and rules shared by formatting, parsing and relative time text."""
from ._text import utf8_width, starts_at, find_byte, pad
from ._locale_data import (
    LOCALE_ZH_CN,
    LOCALE_ZH_TW,
    _locale_aliases,
    _locale_index,
    _locale_names,
    _locale_record,
)
from std.format import Writable, Writer


# Record layout of _locale_data: 0 name; 1-12 months; 13-24 month
# abbreviations; 25-31 weekdays (Monday first); 32-38 weekday abbreviations;
# 39-42 am, pm, AM, PM; 43 past; 44 future; 45 and-word; 46 separator;
# 47 plural rule; 48 relative rule; 49 multi-part rule; 50 "instantly" text;
# 51 year offset; 52 ordinals 1..31; 53 extra parsed ordinals "day\x1ftext";
# 54 whether Do accepts digits; 55-56 special day/year words "offset\x1ftext";
# 57-73 timeframes and 74-90 distance-only timeframes in _frame_names() order.
comptime _FIELD = "\x1f"
comptime _ITEM = "\x1e"
comptime _FRAME_COUNT = 17
comptime _RECORD_TIMEFRAMES = 57
comptime _RECORD_DISTANCE = 74


def _frame_names() -> List[String]:
    return [
        "now",
        "second",
        "seconds",
        "minute",
        "minutes",
        "hour",
        "hours",
        "day",
        "days",
        "week",
        "weeks",
        "month",
        "months",
        "quarter",
        "quarters",
        "year",
        "years",
    ]


def frame_index(frame: String) raises -> Int:
    """Return the index of a humanize timeframe such as "hours"."""
    if frame == "now":
        return 0
    var plural = (
        frame.byte_length() > 0
        and frame.as_bytes()[frame.byte_length() - 1] == 115
    )
    var unit = String(
        frame[byte = 0 : frame.byte_length() - 1]
    ) if plural else frame
    var base = -1
    if unit == "second":
        base = 1
    elif unit == "minute":
        base = 3
    elif unit == "hour":
        base = 5
    elif unit == "day":
        base = 7
    elif unit == "week":
        base = 9
    elif unit == "month":
        base = 11
    elif unit == "quarter":
        base = 13
    elif unit == "year":
        base = 15
    if base < 0:
        raise Error("unsupported timeframe: " + frame)
    return base + 1 if plural else base


def is_english_locale(name: String) -> Bool:
    return _locale_index(name) == 0


def locale_grammar(name: String) raises -> Int:
    """1 for English and 2 for Chinese 1.0 relative grammar, else 0."""
    var index = _locale_index(name)
    if index < 0:
        raise Error("unsupported locale: " + name)
    if index == 0:
        return 1
    if index == LOCALE_ZH_CN or index == LOCALE_ZH_TW:
        return 2
    return 0


def _is_char_boundary(value: String, position: Int) -> Bool:
    if position <= 0 or position >= value.byte_length():
        return True
    var byte = Int(value.as_bytes()[position])
    return byte < 128 or byte >= 192


def starts_at_ignore_case(value: String, position: Int, token: String) -> Bool:
    """Match token at position, ignoring Unicode case when lengths agree."""
    if token.byte_length() == 0:
        return False
    if starts_at(value, position, token):
        return True
    var end = position + token.byte_length()
    if end > value.byte_length() or not _is_char_boundary(value, end):
        return False
    return String(value[byte=position:end]).lower() == token.lower()


def _starts_with_range(
    value: String, position: Int, token: String, start: Int, end: Int
) -> Bool:
    """Whether token[start:end] occurs at position in value."""
    if position < 0 or position + end - start > value.byte_length():
        return False
    for i in range(end - start):
        if value.as_bytes()[position + i] != token.as_bytes()[start + i]:
            return False
    return True


def _ascii_int(value: String, start: Int, end: Int) -> Int:
    var sign = 1
    var i = start
    if i < end and value.as_bytes()[i] == 45:
        sign = -1
        i += 1
    var number = 0
    while i < end:
        number = number * 10 + Int(value.as_bytes()[i]) - 48
        i += 1
    return sign * number


def _pair_text(encoded: String, number: Int) -> String:
    """Text paired with number in "n\x1ftext\x1e..." data, or empty."""
    var start = 0
    var length = encoded.byte_length()
    while start < length:
        var end = find_byte(encoded, 0x1E, start, length)
        var field = find_byte(encoded, 0x1F, start, end)
        if _ascii_int(encoded, start, field) == number:
            return String(encoded[byte = field + 1 : end])
        start = end + 1
    return ""


def _pair_number(encoded: String, text: String) -> Int:
    """Number paired with exactly text, or -9999 when absent."""
    var start = 0
    var length = encoded.byte_length()
    while start < length:
        var end = find_byte(encoded, 0x1E, start, length)
        var field = find_byte(encoded, 0x1F, start, end)
        if end - field - 1 == text.byte_length() and starts_at(
            encoded, field + 1, text
        ):
            return _ascii_int(encoded, start, field)
        start = end + 1
    return -9999


def _nth_field(encoded: String, index: Int) -> String:
    var start = 0
    var length = encoded.byte_length()
    var current = 0
    while start <= length:
        var end = find_byte(encoded, 0x1F, start, length)
        if current == index:
            return String(encoded[byte=start:end])
        current += 1
        start = end + 1
    return ""


def _decimal(value: Int, width: Int) -> String:
    var sign = "-" if value < 0 else ""
    return sign + pad(abs(value), width)


struct TimeFrame(Copyable, Movable):
    """Text for one humanize timeframe; keyed forms select plural or tense.

    A plain timeframe has one `{0}` template. Keyed timeframes hold forms such
    as "singular"/"dual"/"plural" or "past"/"future", chosen by the locale's
    `plural_rule`.
    """

    var _data: String

    def __init__(out self):
        self._data = ""

    def __init__(out self, form: String) raises:
        Self._check_text(form)
        if form.byte_length() == 0:
            raise Error("timeframe text is empty")
        self._data = form

    def __init__(out self, keys: List[String], forms: List[String]) raises:
        if len(keys) != len(forms) or len(keys) == 0:
            raise Error("timeframe keys and forms must be non-empty and equal")
        self._data = ""
        for i in range(len(keys)):
            Self._check_text(keys[i])
            Self._check_text(forms[i])
            if i > 0:
                self._data += _ITEM
            self._data += keys[i] + _FIELD + forms[i]

    def __init__(out self, *, copy: Self):
        self._data = copy._data

    def __init__(out self, *, deinit move: Self):
        self._data = move._data^

    @staticmethod
    def _check_text(text: String) raises:
        if text.find(_FIELD) >= 0 or text.find(_ITEM) >= 0:
            raise Error("timeframe text contains a reserved control character")

    @staticmethod
    def _decode(encoded: String) -> TimeFrame:
        var result = TimeFrame()
        result._data = encoded
        return result^

    def is_missing(self) -> Bool:
        return self._data.byte_length() == 0

    def is_plain(self) -> Bool:
        return not self.is_missing() and self._data.find(_FIELD) < 0

    def _item_count(self) -> Int:
        if self.is_missing():
            return 0
        var count = 1
        for i in range(self._data.byte_length()):
            if self._data.as_bytes()[i] == 0x1E:
                count += 1
        return count

    def _form_range(self, index: Int) -> Tuple[Int, Int]:
        """Byte range of the form at index."""
        var length = self._data.byte_length()
        var start = 0
        for _ in range(index):
            start = find_byte(self._data, 0x1E, start, length) + 1
        var end = find_byte(self._data, 0x1E, start, length)
        var field = find_byte(self._data, 0x1F, start, end)
        if field == end:
            return (start, end)
        return (field + 1, end)

    def _key_range(self, index: Int) -> Tuple[Int, Int]:
        var length = self._data.byte_length()
        var start = 0
        for _ in range(index):
            start = find_byte(self._data, 0x1E, start, length) + 1
        var end = find_byte(self._data, 0x1E, start, length)
        var field = find_byte(self._data, 0x1F, start, end)
        if field == end:
            return (start, start)
        return (start, field)

    def keys(self) -> List[String]:
        var result = List[String]()
        for i in range(self._item_count()):
            var span = self._key_range(i)
            result.append(String(self._data[byte = span[0] : span[1]]))
        return result^

    def forms(self) -> List[String]:
        var result = List[String]()
        for i in range(self._item_count()):
            result.append(self._form_at(i))
        return result^

    def _form_at(self, index: Int) -> String:
        var span = self._form_range(index)
        return String(self._data[byte = span[0] : span[1]])

    def _key_index(self, key: String) -> Int:
        for i in range(self._item_count()):
            var span = self._key_range(i)
            if span[1] - span[0] == key.byte_length() and _starts_with_range(
                self._data, span[0], key, 0, key.byte_length()
            ):
                return i
        return -1

    def has_key(self, key: String) -> Bool:
        return self._key_index(key) >= 0

    def form(self, key: String) raises -> String:
        var index = self._key_index(key)
        if index < 0:
            raise Error("timeframe form is missing: " + key)
        return self._form_at(index)


struct LocaleMatch(Copyable, ImplicitlyCopyable, Movable):
    var value: Int
    var pos: Int

    def __init__(out self, value: Int, pos: Int):
        self.value = value
        self.pos = pos


struct RelativeParts(Copyable, Movable):
    """Signed calendar units parsed from a humanized string."""

    var units: List[String]
    var counts: List[Int]

    def __init__(out self):
        self.units = List[String]()
        self.counts = List[Int]()

    def __init__(out self, *, copy: Self):
        self.units = copy.units.copy()
        self.counts = copy.counts.copy()

    def __init__(out self, *, deinit move: Self):
        self.units = move.units^
        self.counts = move.counts^

    def append(mut self, unit: String, count: Int):
        self.units.append(unit)
        self.counts.append(count)

    def count(self, unit: String) -> Int:
        var total = 0
        for i in range(len(self.units)):
            if self.units[i] == unit:
                total += self.counts[i]
        return total


struct Locale(Copyable, Movable, Writable):
    """Language data for formatting, parsing and humanizing.

    Construct a built-in locale by name, for example `Locale("fr")`, then edit
    its public fields to define a custom locale. Name lists are zero-based:
    `month_names[0]` is January and `day_names[0]` is Monday.
    """

    var name: String
    var month_names: List[String]
    var month_abbreviations: List[String]
    var day_names: List[String]
    var day_abbreviations: List[String]
    var meridians: List[String]
    """AM/PM markers in the order am, pm, AM, PM."""
    var past: String
    var future: String
    var and_word: String
    var separator: String
    var plural_rule: String
    var relative_rule: String
    var multi_rule: String
    var instantly: String
    var year_offset: Int
    var ordinals: List[String]
    """Custom day ordinals 1..31; empty uses the built-in ordinals."""
    var ordinal_digits: Bool
    """Whether `Do` also parses plain digits."""
    var timeframes: List[TimeFrame]
    var distance_timeframes: List[TimeFrame]
    var _ordinal_data: String
    var _ordinal_parse: String
    var _special_days: String
    var _special_years: String
    var _english_fast: Bool

    def __init__(out self, name: String) raises:
        """Load a built-in locale; names are case-insensitive and accept `_` or `-`.
        """
        self = Self(name, _names=True, _relative=True)

    def __init__(
        out self, name: String, *, _names: Bool, _relative: Bool
    ) raises:
        """Load only the data an operation needs; skipped lists stay empty."""
        var index = _locale_index(name)
        if index < 0:
            raise Error("unsupported locale: " + name)
        var r = _locale_record(index)
        self.name = r[0]
        self.month_names = List[String]()
        self.month_abbreviations = List[String]()
        self.day_names = List[String]()
        self.day_abbreviations = List[String]()
        self.meridians = List[String]()
        if _names:
            self.month_names.reserve(12)
            self.month_abbreviations.reserve(12)
            self.day_names.reserve(7)
            self.day_abbreviations.reserve(7)
            for i in range(12):
                self.month_names.append(r[1 + i])
                self.month_abbreviations.append(r[13 + i])
            for i in range(7):
                self.day_names.append(r[25 + i])
                self.day_abbreviations.append(r[32 + i])
            self.meridians = [r[39], r[40], r[41], r[42]]
        self.past = r[43]
        self.future = r[44]
        self.and_word = r[45]
        self.separator = r[46]
        self.plural_rule = r[47]
        self.relative_rule = r[48]
        self.multi_rule = r[49]
        self.instantly = r[50]
        self.year_offset = Int(r[51])
        self.ordinals = List[String]()
        self._ordinal_data = r[52]
        self._ordinal_parse = r[53]
        self.ordinal_digits = r[54] == "1"
        self._special_days = r[55]
        self._special_years = r[56]
        self.timeframes = List[TimeFrame]()
        self.distance_timeframes = List[TimeFrame]()
        if _relative:
            self.timeframes.reserve(_FRAME_COUNT)
            self.distance_timeframes.reserve(_FRAME_COUNT)
            for i in range(_FRAME_COUNT):
                self.timeframes.append(
                    TimeFrame._decode(r[_RECORD_TIMEFRAMES + i])
                )
                self.distance_timeframes.append(
                    TimeFrame._decode(r[_RECORD_DISTANCE + i])
                )
        self._english_fast = False

    def __init__(out self, *, copy: Self):
        self.name = copy.name
        self.month_names = copy.month_names.copy()
        self.month_abbreviations = copy.month_abbreviations.copy()
        self.day_names = copy.day_names.copy()
        self.day_abbreviations = copy.day_abbreviations.copy()
        self.meridians = copy.meridians.copy()
        self.past = copy.past
        self.future = copy.future
        self.and_word = copy.and_word
        self.separator = copy.separator
        self.plural_rule = copy.plural_rule
        self.relative_rule = copy.relative_rule
        self.multi_rule = copy.multi_rule
        self.instantly = copy.instantly
        self.year_offset = copy.year_offset
        self.ordinals = copy.ordinals.copy()
        self.ordinal_digits = copy.ordinal_digits
        self.timeframes = copy.timeframes.copy()
        self.distance_timeframes = copy.distance_timeframes.copy()
        self._ordinal_data = copy._ordinal_data
        self._ordinal_parse = copy._ordinal_parse
        self._special_days = copy._special_days
        self._special_years = copy._special_years
        self._english_fast = copy._english_fast

    def __init__(out self, *, deinit move: Self):
        self.name = move.name^
        self.month_names = move.month_names^
        self.month_abbreviations = move.month_abbreviations^
        self.day_names = move.day_names^
        self.day_abbreviations = move.day_abbreviations^
        self.meridians = move.meridians^
        self.past = move.past^
        self.future = move.future^
        self.and_word = move.and_word^
        self.separator = move.separator^
        self.plural_rule = move.plural_rule^
        self.relative_rule = move.relative_rule^
        self.multi_rule = move.multi_rule^
        self.instantly = move.instantly^
        self.year_offset = move.year_offset
        self.ordinals = move.ordinals^
        self.ordinal_digits = move.ordinal_digits
        self.timeframes = move.timeframes^
        self.distance_timeframes = move.distance_timeframes^
        self._ordinal_data = move._ordinal_data^
        self._ordinal_parse = move._ordinal_parse^
        self._special_days = move._special_days^
        self._special_years = move._special_years^
        self._english_fast = move._english_fast

    @staticmethod
    def _fast_english() -> Locale:
        """Placeholder used by string APIs that keep the built-in English path.
        """
        return Locale(_english_fast=True)

    def __init__(out self, *, _english_fast: Bool):
        self.name = "en"
        self.month_names = List[String]()
        self.month_abbreviations = List[String]()
        self.day_names = List[String]()
        self.day_abbreviations = List[String]()
        self.meridians = List[String]()
        self.past = ""
        self.future = ""
        self.and_word = ""
        self.separator = ""
        self.plural_rule = ""
        self.relative_rule = ""
        self.multi_rule = ""
        self.instantly = ""
        self.year_offset = 0
        self.ordinals = List[String]()
        self.ordinal_digits = False
        self.timeframes = List[TimeFrame]()
        self.distance_timeframes = List[TimeFrame]()
        self._ordinal_data = ""
        self._ordinal_parse = ""
        self._special_days = ""
        self._special_years = ""
        self._english_fast = _english_fast

    @staticmethod
    def available() -> List[String]:
        """Return the canonical names of all built-in locales."""
        return _locale_names()

    @staticmethod
    def aliases(name: String) raises -> List[String]:
        """Return every accepted name of the built-in locale matching name."""
        var index = _locale_index(name)
        if index < 0:
            raise Error("unsupported locale: " + name)
        return _locale_aliases(index)

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.name)

    def is_fast_english(self) -> Bool:
        return self._english_fast

    # Names and numbers.

    def month_name(self, month: Int) raises -> String:
        if month < 1 or month > 12:
            raise Error("month must be in 1..12")
        return self.month_names[month - 1]

    def month_abbreviation(self, month: Int) raises -> String:
        if month < 1 or month > 12:
            raise Error("month must be in 1..12")
        return self.month_abbreviations[month - 1]

    def day_name(self, isoweekday: Int) raises -> String:
        if isoweekday < 1 or isoweekday > 7:
            raise Error("weekday must be in 1..7")
        return self.day_names[isoweekday - 1]

    def day_abbreviation(self, isoweekday: Int) raises -> String:
        if isoweekday < 1 or isoweekday > 7:
            raise Error("weekday must be in 1..7")
        return self.day_abbreviations[isoweekday - 1]

    def meridian(self, hour: Int, token: String) raises -> String:
        """Return the AM/PM marker for token "a" (lower) or "A" (upper)."""
        var offset = 0 if hour < 12 else 1
        if token == "a":
            return self.meridians[offset]
        if token == "A":
            return self.meridians[2 + offset]
        raise Error("meridian token must be 'a' or 'A'")

    def ordinal_number(self, n: Int) -> String:
        if n >= 1 and n <= len(self.ordinals):
            return self.ordinals[n - 1]
        if n >= 1 and n <= 31 and self._ordinal_data.byte_length() > 0:
            return _nth_field(self._ordinal_data, n - 1)
        return String(n)

    def year_full(self, year: Int) -> String:
        return _decimal(year + self.year_offset, 4)

    def year_abbreviation(self, year: Int) -> String:
        var full = self.year_full(year)
        return String(full[byte=2:])

    # Humanize.

    def set_timeframe(mut self, frame: String, form: String) raises:
        """Replace a timeframe such as "hours" with a `{0}` template."""
        self.timeframes[frame_index(frame)] = TimeFrame(form)

    def set_timeframe(
        mut self, frame: String, keys: List[String], forms: List[String]
    ) raises:
        """Replace a timeframe with keyed forms selected by `plural_rule`."""
        self.timeframes[frame_index(frame)] = TimeFrame(keys, forms)

    def has_timeframe(self, frame: String) raises -> Bool:
        return not self.timeframes[frame_index(frame)].is_missing()

    def describe(
        self, frame: String, delta: Int = 0, only_distance: Bool = False
    ) raises -> String:
        """Describe a signed delta in one timeframe, like "in 2 hours"."""
        return self._describe(
            frame_index(frame), delta, delta < 0, only_distance
        )

    def describe_multi(
        self,
        frames: List[String],
        deltas: List[Int],
        only_distance: Bool = False,
    ) raises -> String:
        """Describe signed deltas in several timeframes."""
        if len(frames) != len(deltas) or len(frames) == 0:
            raise Error("frames and deltas must be non-empty and equal length")
        var indexes = List[Int]()
        var negative = False
        for i in range(len(frames)):
            indexes.append(frame_index(frames[i]))
            if deltas[i] != 0 and not negative:
                negative = deltas[i] < 0
        return self._describe_multi(indexes, deltas, negative, only_distance)

    def _missing(self, frame: Int) -> String:
        return (
            "humanization of the '"
            + _frame_names()[frame]
            + "' granularity is not translated in the '"
            + self.name
            + "' locale"
        )

    def _describe(
        self, frame: Int, delta: Int, negative: Bool, only_distance: Bool
    ) raises -> String:
        if only_distance:
            if frame == 0 and self.instantly.byte_length() > 0:
                return self.instantly
            if len(self.distance_timeframes) > frame:
                ref distance = self.distance_timeframes[frame]
                if distance.is_plain():
                    return distance._data.replace("{0}", String(abs(delta)))
        var humanized = self._format_timeframe(frame, delta)
        if only_distance:
            return humanized
        return self._format_relative(humanized, frame, delta, negative)

    def _describe_multi(
        self,
        frames: List[Int],
        deltas: List[Int],
        negative: Bool,
        only_distance: Bool,
    ) raises -> String:
        var parts = List[String]()
        for i in range(len(frames)):
            parts.append(self._format_timeframe(frames[i], deltas[i]))
        var humanized = String("")
        if self.multi_rule == "hebrew" and len(parts) > 1:
            for i in range(len(parts)):
                if i == 0:
                    humanized = parts[i]
                elif i == len(parts) - 1:
                    humanized += " " + self.and_word
                    var first = parts[i].as_bytes()[0]
                    if first >= 48 and first <= 57:
                        humanized += "־"
                    humanized += parts[i]
                else:
                    humanized += ", " + parts[i]
        else:
            if self.and_word.byte_length() > 0 and len(parts) > 1:
                parts.insert(len(parts) - 1, self.and_word)
            for i in range(len(parts)):
                if i > 0:
                    humanized += self.separator
                humanized += parts[i]
        if only_distance:
            return humanized
        # The relative rule is chosen as for a seconds frame, as in Arrow.
        return self._format_relative(humanized, 2, 0, negative)

    def _format_timeframe(self, frame: Int, delta: Int) raises -> String:
        ref timeframe = self.timeframes[frame]
        if timeframe.is_missing():
            var message = self._missing(frame)
            raise Error(message)
        var count = abs(delta)
        var number = String(count)
        if timeframe.is_plain():
            return timeframe._data.replace("{0}", number)
        var key: String
        var rule = self.plural_rule
        if rule == "arabic" or rule == "hebrew":
            if count == 2:
                key = "2"
            elif (count > 2 and count <= 10) or (
                rule == "hebrew" and count == 0
            ):
                key = "ten"
            else:
                key = "higher"
        elif rule == "slavic":
            if count % 10 == 1 and count % 100 != 11:
                key = "singular"
            elif (
                count % 10 >= 2
                and count % 10 <= 4
                and (count % 100 < 10 or count % 100 >= 20)
            ):
                key = "dual"
            else:
                key = "plural"
        elif rule == "double":
            key = "double" if count > 1 and count <= 4 else "higher"
        elif rule == "maltese":
            key = "dual" if count == 2 else "plural"
        elif rule == "czech":
            if delta == 0:
                key = "zero"
            elif delta < 0:
                key = "past"
            elif not timeframe.has_key("future-singular"):
                key = "future"
            elif (
                count % 10 >= 2
                and count % 10 <= 4
                and (count % 100 < 10 or count % 100 >= 20)
            ):
                key = "future-singular"
            else:
                key = "future-paucal"
        elif rule == "future_if_positive":
            key = "future" if delta > 0 else "past"
        elif rule == "past_if_negative":
            key = "past" if delta < 0 else "future"
        elif rule == "icelandic":
            if delta == 0:
                raise Error(
                    "the '"
                    + self.name
                    + "' locale has no text for a zero delta"
                )
            key = "past" if delta < 0 else "future"
        else:
            raise Error("keyed timeframes need a plural_rule")
        return timeframe.form(key).replace("{0}", number)

    def _format_relative(
        self, humanized: String, frame: Int, delta: Int, negative: Bool
    ) raises -> String:
        if frame == 0:
            return humanized
        if self.relative_rule == "korean":
            var special = String("")
            if frame == 7 or frame == 8:
                special = _pair_text(self._special_days, delta)
            elif frame == 15 or frame == 16:
                special = _pair_text(self._special_years, delta)
            if special.byte_length() > 0:
                return special
        var direction = self.past if negative else self.future
        var result = direction.replace("{0}", humanized)
        if self.relative_rule == "compact_seconds" and frame == 2:
            return result.replace(" ", "")
        return result

    # Formatting.

    def _localize_format(
        self,
        fmt: String,
        year: Int,
        month: Int,
        day: Int,
        isoweekday: Int,
        hour: Int,
    ) raises -> String:
        """Replace locale-dependent tokens with bracketed literal text."""
        var result = String("")
        var i = 0
        var literal = False
        while i < fmt.byte_length():
            if fmt.as_bytes()[i] == 91:
                literal = True
            elif fmt.as_bytes()[i] == 93:
                literal = False
            if not literal:
                var consumed = 0
                var text = String("")
                if starts_at(fmt, i, "MMMM"):
                    text = self.month_name(month)
                    consumed = 4
                elif starts_at(fmt, i, "MMM"):
                    text = self.month_abbreviation(month)
                    consumed = 3
                elif starts_at(fmt, i, "dddd"):
                    text = self.day_name(isoweekday)
                    consumed = 4
                elif starts_at(fmt, i, "ddd"):
                    text = self.day_abbreviation(isoweekday)
                    consumed = 3
                elif starts_at(fmt, i, "Do"):
                    text = self.ordinal_number(day)
                    consumed = 2
                elif fmt.as_bytes()[i] == 65:
                    text = self.meridian(hour, "A")
                    consumed = 1
                elif fmt.as_bytes()[i] == 97:
                    text = self.meridian(hour, "a")
                    consumed = 1
                elif self.year_offset != 0 and starts_at(fmt, i, "YYYY"):
                    text = self.year_full(year)
                    consumed = 4
                elif self.year_offset != 0 and starts_at(fmt, i, "YY"):
                    text = self.year_abbreviation(year)
                    consumed = 2
                if consumed > 0:
                    result += "[" + text + "]"
                    i += consumed
                    continue
            var width = utf8_width(fmt, i)
            result += fmt[byte = i : i + width]
            i += width
        return result

    # Parsing.

    @staticmethod
    def _match_longest(
        value: String, pos: Int, names: List[String]
    ) raises -> LocaleMatch:
        var best = -1
        var best_end = -1
        for i in range(len(names)):
            if starts_at_ignore_case(value, pos, names[i]):
                var end = pos + names[i].byte_length()
                if end > best_end:
                    best = i
                    best_end = end
        if best < 0:
            raise Error("name is invalid")
        return LocaleMatch(best + 1, best_end)

    def _match_month(
        self, value: String, pos: Int, abbreviated: Bool
    ) raises -> LocaleMatch:
        try:
            return Self._match_longest(
                value,
                pos,
                self.month_abbreviations if abbreviated else self.month_names,
            )
        except e:
            raise Error("month name is invalid")

    def _match_weekday(
        self, value: String, pos: Int, abbreviated: Bool
    ) raises -> LocaleMatch:
        try:
            return Self._match_longest(
                value,
                pos,
                self.day_abbreviations if abbreviated else self.day_names,
            )
        except e:
            raise Error("weekday name is invalid")

    def _match_meridian(self, value: String, pos: Int) raises -> LocaleMatch:
        """Return 1 for AM or 2 for PM and the position after the marker."""
        var has_marker = False
        for i in range(len(self.meridians)):
            if self.meridians[i].byte_length() > 0:
                has_marker = True
        if not has_marker:
            # Like Arrow, a locale without markers formats and parses them as
            # empty text meaning AM.
            return LocaleMatch(1, pos)
        var result = LocaleMatch(0, -1)
        for i in range(len(self.meridians)):
            if starts_at_ignore_case(value, pos, self.meridians[i]):
                var end = pos + self.meridians[i].byte_length()
                if end > result.pos:
                    result = LocaleMatch(1 + i % 2, end)
        if result.value == 0:
            raise Error("AM/PM marker is invalid")
        return result

    def _match_ordinal(self, value: String, pos: Int) raises -> LocaleMatch:
        var result = LocaleMatch(0, -1)
        for i in range(len(self.ordinals)):
            if starts_at_ignore_case(value, pos, self.ordinals[i]):
                var end = pos + self.ordinals[i].byte_length()
                if end > result.pos:
                    result = LocaleMatch(i + 1, end)
        var start = 0
        var length = self._ordinal_parse.byte_length()
        while start < length:
            var end = find_byte(self._ordinal_parse, 0x1E, start, length)
            var field = find_byte(self._ordinal_parse, 0x1F, start, end)
            var text_length = end - field - 1
            if pos + text_length > result.pos and (
                starts_at_ignore_case(
                    value,
                    pos,
                    String(self._ordinal_parse[byte = field + 1 : end]),
                )
            ):
                result = LocaleMatch(
                    _ascii_int(self._ordinal_parse, start, field),
                    pos + text_length,
                )
            start = end + 1
        if result.value > 0:
            return result
        if self.ordinal_digits:
            var end = pos
            var number = 0
            while (
                end < value.byte_length()
                and end - pos < 2
                and value.as_bytes()[end] >= 48
                and value.as_bytes()[end] <= 57
            ):
                number = number * 10 + Int(value.as_bytes()[end]) - 48
                end += 1
            if end > pos and not (
                end - pos > 1 and value.as_bytes()[pos] == 48
            ):
                return LocaleMatch(number, end)
        raise Error("ordinal day is invalid")

    # Dehumanize.

    @staticmethod
    def _unit_name(frame: Int) -> String:
        var names: List[String] = [
            "seconds",
            "minutes",
            "hours",
            "days",
            "weeks",
            "months",
            "quarters",
            "years",
        ]
        return names[(frame - 1) // 2]

    def _implied_count(self, frame: Int, form: String, negative: Bool) -> Int:
        if frame % 2 == 1:
            return 1
        for count in range(1, 21):
            try:
                if (
                    self._format_timeframe(frame, -count if negative else count)
                    == form
                ):
                    return count
            except e:
                pass
        return 1

    @staticmethod
    def _match_form(
        text: String, pos: Int, form: String, start: Int, end: Int
    ) -> LocaleMatch:
        """Match template form[start:end] at pos; value is the count, or -1."""
        var placeholder = -1
        for i in range(start, end - 2):
            if (
                form.as_bytes()[i] == 123
                and form.as_bytes()[i + 1] == 48
                and form.as_bytes()[i + 2] == 125
            ):
                placeholder = i
                break
        if placeholder < 0:
            if end > start and _starts_with_range(text, pos, form, start, end):
                return LocaleMatch(-1, pos + end - start)
            return LocaleMatch(0, -1)
        if not _starts_with_range(text, pos, form, start, placeholder):
            return LocaleMatch(0, -1)
        var digit = pos + placeholder - start
        var digits_end = digit
        var count = 0
        while (
            digits_end < text.byte_length()
            and digits_end - digit < 9
            and text.as_bytes()[digits_end] >= 48
            and text.as_bytes()[digits_end] <= 57
        ):
            count = count * 10 + Int(text.as_bytes()[digits_end]) - 48
            digits_end += 1
        if digits_end == digit or not _starts_with_range(
            text, digits_end, form, placeholder + 3, end
        ):
            return LocaleMatch(0, -1)
        return LocaleMatch(count, digits_end + end - placeholder - 3)

    def _match_part(
        self, text: String, pos: Int, negative: Bool, compact: Bool
    ) -> LocaleMatch:
        """Longest timeframe form at pos; value encodes frame * 10^9 + count."""
        var best = LocaleMatch(-1, -1)
        var best_frame = 0
        var best_form = 0
        var best_count = 0
        for frame in range(1, _FRAME_COUNT):
            ref data = self.timeframes[frame]._data
            var length = data.byte_length()
            var start = 0
            var i = 0
            while start < length:
                var end = find_byte(data, 0x1E, start, length)
                var field = find_byte(data, 0x1F, start, end)
                var form_start = start if field == end else field + 1
                var matched: LocaleMatch
                if compact:
                    var form = String(data[byte=form_start:end]).replace(
                        " ", ""
                    )
                    matched = Self._match_form(
                        text, pos, form, 0, form.byte_length()
                    )
                else:
                    matched = Self._match_form(text, pos, data, form_start, end)
                if matched.pos > best.pos:
                    best = matched
                    best_frame = frame
                    best_form = i
                    best_count = matched.value
                start = end + 1
                i += 1
        if best.pos < 0:
            return best
        if best_count < 0:
            best_count = self._implied_count(
                best_frame,
                self.timeframes[best_frame]._form_at(best_form),
                negative,
            )
        return LocaleMatch(best_frame * 1000000000 + best_count, best.pos)

    @staticmethod
    def _skip_separators(text: String, pos: Int) -> Int:
        var result = pos
        while result < text.byte_length():
            var byte = text.as_bytes()[result]
            if byte == 32 or byte == 44 or byte == 9:
                result += 1
            elif starts_at(text, result, "،") or starts_at(text, result, "、"):
                result += utf8_width(text, result)
            else:
                break
        return result

    def _parse_parts(
        self, text: String, negative: Bool, compact: Bool
    ) raises -> RelativeParts:
        var parts = RelativeParts()
        var pos = 0
        while True:
            pos = Self._skip_separators(text, pos)
            if pos >= text.byte_length():
                break
            var matched = self._match_part(text, pos, negative, compact)
            if matched.pos < 0 and self.and_word.byte_length() > 0:
                var after = pos
                if starts_at(text, after, self.and_word):
                    after += self.and_word.byte_length()
                    if starts_at(text, after, "־"):
                        after += utf8_width(text, after)
                    after = Self._skip_separators(text, after)
                    matched = self._match_part(text, after, negative, compact)
            if matched.pos < 0:
                raise Error("humanized distance is invalid")
            var frame = matched.value // 1000000000
            var count = matched.value % 1000000000
            parts.append(Self._unit_name(frame), -count if negative else count)
            pos = matched.pos
        if len(parts.units) == 0:
            raise Error("humanized distance is invalid")
        return parts^

    def _parse_relative(self, text: String) raises -> RelativeParts:
        """Parse text produced by this locale's humanize into signed units."""
        for i in range(self.timeframes[0]._item_count()):
            if text == self.timeframes[0]._form_at(i):
                return RelativeParts()
        if self.instantly.byte_length() > 0 and text == self.instantly:
            return RelativeParts()
        var special_day = _pair_number(self._special_days, text)
        if special_day != -9999:
            var parts = RelativeParts()
            parts.append("days", special_day)
            return parts^
        var special_year = _pair_number(self._special_years, text)
        if special_year != -9999:
            var parts = RelativeParts()
            parts.append("years", special_year)
            return parts^
        var modes = 2 if self.relative_rule == "compact_seconds" else 1
        for mode in range(modes):
            var compact = mode == 1
            for direction in range(2):
                var negative = direction == 0
                var template = self.past if negative else self.future
                if compact:
                    template = template.replace(" ", "")
                var placeholder = template.find("{0}")
                if placeholder < 0:
                    continue
                var prefix = String(template[byte=0:placeholder])
                var suffix = String(template[byte = placeholder + 3 :])
                var inner_end = text.byte_length() - suffix.byte_length()
                if (
                    inner_end <= prefix.byte_length()
                    or not starts_at(text, 0, prefix)
                    or not starts_at(text, inner_end, suffix)
                ):
                    continue
                try:
                    return self._parse_parts(
                        String(text[byte = prefix.byte_length() : inner_end]),
                        negative,
                        compact,
                    )
                except e:
                    pass
        raise Error(
            "humanized string is not valid for the '" + self.name + "' locale"
        )


def english_relative(text: String) raises -> String:
    """Translate Morrow's Chinese relative text into its English grammar."""
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
