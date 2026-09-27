---
sidebar_position: 8
---

# API 参考

本页汇总公开 API。精确行为请参考仓库中的单元测试。

## Morrow

构造：

- `Morrow(...)`
- `Morrow.now()`、`Morrow.now(tz)`、`Morrow.utcnow()`
- `Morrow.fromtimestamp(...)`、`Morrow.utcfromtimestamp(...)`
- `Morrow.get(...)`
- `Morrow.fromisoformat(...)`
- `Morrow.strptime(...)`
- `Morrow.fromdate(...)`、`Morrow.fromdatetime(...)`
- `Morrow.fromordinal(...)`、`Morrow.fromisocalendar(...)`
- `Morrow.get(time_tuple)`：以 UTC 解释 `MorrowTimeTuple`

格式化和转换：

- `format(fmt, locale="en")`；`locale` 也接受 `Locale`
- `strftime(fmt)`
- `isoformat(sep="T", timespec="auto")`
- `for_json()`
- `timestamp()`、`float_timestamp()`、`int_timestamp()`
- `to(tz)`、`astimezone(tz)`、`naive()`

日期时间操作：

- `replace(...)`
- `shift(...)`, `shift_weekday(weekday, nth=1)`
- `floor(frame)`、`ceil(frame)`、`span(frame)`
- `range(...)`、`span_range(...)`、`interval(...)`
- `is_between(start, end, bounds="()")`

视图和日历字段：

- `date()`、`time()`、`timetz()`、`datetime()`
- `weekday()`、`isoweekday()`、`isocalendar()`
- `timetuple()`、`utctimetuple()`
- `quarter()`、`week()`、`ctime()`
- `fold()`、`ambiguous()`、`imaginary()`、`dst()`
- `tzname()`、`tz_abbreviation()`、`utcoffset()`

相对时间：

- `humanize(...)`
- `dehumanize(input_string, locale="en")`

比较和哈希：

- `==` 和 `!=` 比较时刻；无时区值与有时区值永不相等
- `Morrow` 实现 `Hashable` 和 `Equatable`，可以作为 `Dict` 的键和 `Set` 的元素
- 无时区值与有时区值混合排序（`<`、`<=`、`>`、`>=`）会报错

## Locale

- `Locale(name)` 加载 81 种内置语言之一，见[语言](./locales.md)
- `Locale.available()`、`Locale.aliases(name)`
- 公开字段：`name`、`month_names`、`month_abbreviations`、`day_names`、`day_abbreviations`、`meridians`、`past`、`future`、`and_word`、`separator`、`plural_rule`、`relative_rule`、`multi_rule`、`instantly`、`year_offset`、`ordinals`、`ordinal_digits`、`timeframes`、`distance_timeframes`
- `month_name(month)`、`month_abbreviation(month)`、`day_name(isoweekday)`、`day_abbreviation(isoweekday)`
- `meridian(hour, token)`、`ordinal_number(n)`、`year_full(year)`、`year_abbreviation(year)`
- `set_timeframe(frame, form)`、`set_timeframe(frame, keys, forms)`、`has_timeframe(frame)`
- `describe(frame, delta=0, only_distance=False)`、`describe_multi(frames, deltas, only_distance=False)`

## TimeFrame

- `TimeFrame(form)`、`TimeFrame(keys, forms)`
- `is_missing()`、`is_plain()`、`has_key(key)`、`form(key)`、`keys()`、`forms()`

## TimeZone

- `TimeZone(offset, name="")`
- `TimeZone.none()`
- `TimeZone.local()`, `TimeZone.local(timestamp)`
- `TimeZone.from_name(name)`
- `TimeZone.from_utc(value)`
- `format(sep=":")`
- `is_none()`

## TimeDelta

- `TimeDelta(days=0, seconds=0, microseconds=0, milliseconds=0, minutes=0, hours=0, weeks=0)`
- `total_seconds()`、`divmod(other)`
- `+`、`-`，乘以 `Int` 或 `Float64`，除以（`/`、`//`）`TimeDelta`、`Int` 或 `Float64`，`%`
- 实现 `Comparable`、`Equatable` 和 `Hashable`；支持布尔和字符串转换
- 乘以浮点数和除以数字时，结果四舍六入五成双到微秒
