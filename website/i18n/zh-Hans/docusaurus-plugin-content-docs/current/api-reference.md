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

格式化和转换：

- `format(fmt)`
- `strftime(fmt)`
- `isoformat(sep="T", timespec="auto")`
- `for_json()`
- `timestamp()`、`float_timestamp()`、`int_timestamp()`
- `to(tz)`、`astimezone(tz)`、`naive()`

日期时间操作：

- `replace(...)`
- `shift(...)`
- `floor(frame)`、`ceil(frame)`、`span(frame)`
- `range(...)`、`span_range(...)`、`interval(...)`
- `is_between(start, end, bounds="()")`

视图和日历字段：

- `date()`、`time()`、`timetz()`、`datetime()`
- `weekday()`、`isoweekday()`、`isocalendar()`
- `timetuple()`、`utctimetuple()`
- `quarter()`、`week()`、`ctime()`

相对时间：

- `humanize(...)`
- `dehumanize(input_string)`

## TimeZone

- `TimeZone(offset, name="")`
- `TimeZone.none()`
- `TimeZone.local()`
- `TimeZone.from_utc(value)`
- `format(sep=":")`
- `is_none()`

## TimeDelta

- `TimeDelta(days=0, seconds=0, microseconds=0, milliseconds=0, minutes=0, hours=0, weeks=0)`
- `total_seconds()`
- 算术、比较、布尔和字符串转换操作
