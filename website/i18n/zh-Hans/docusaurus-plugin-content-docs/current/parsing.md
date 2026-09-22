---
sidebar_position: 3
---

# 解析

Morrow 可以接收 ISO 8601 字符串、时间戳、组件值、token 格式字符串，以及格式候选列表。

## ISO 和时间戳

```text
print(Morrow.get("2026-01-01"))
print(Morrow.fromisoformat("20260101T030405.123456Z"))
print(Morrow.get(1767225600.0))
print(Morrow.get("2026-01-01 03:04:05Z"))
```

ISO 解析支持扩展和基本日历日期、序数日期、ISO 周日期、逗号或点分隔的小数秒、`24:00` 日末写法，以及固定偏移时区。

## token 格式

```text
print(Morrow.get("2026-01-01 15:49:10.123456 +05:30", "YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(Morrow.get("Jan 1st, 2026", "MMM Do, YYYY"))
print(Morrow.get("Thursday 2026-01-01", "dddd YYYY-MM-DD"))
print(Morrow.get("1767236645123456", "x"))
```

当输入文本里包含额外内容时，Morrow 会按解析边界搜索有效的 token 匹配：

```text
print(Morrow.get("June was born in January 2026", "MMMM YYYY"))
```

## 多个格式

```text
from std.collections import List

var formats = List[String]()
formats.append("YYYY/MM/DD")
formats.append("YYYY-MM-DD HH:mm:ss")

print(Morrow.get("2026-01-01 15:49:10", formats))
```

## Locale

```text
var value = Morrow.get("2024 十一月 05 下午 03:00", "YYYY MMMM DD A hh:mm", locale="zh-CN")
```

月份、星期、日期序数和上午下午标记支持英文、简体中文及繁体中文，字面量支持 UTF-8。解析时通过关键字 `locale` 指定语言，`tz` 接收 TimeZone，可选 `normalize_whitespace` 归一化空白。

正数时间戳大于 32,503,737,600 时按数量级解释为毫秒或微秒；负数按秒处理。超过这一秒数阈值的日期请用日期组件或 ISO 文本创建，避免单位歧义。非有限数和超出日历范围的时间戳会报错。
