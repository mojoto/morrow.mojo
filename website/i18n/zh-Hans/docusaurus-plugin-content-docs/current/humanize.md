---
sidebar_position: 7
---

# 人性化时间

Morrow 可以用英文、简体中文或繁体中文描述日期时间距离，也可以把这些距离反向应用到基准值上。

## Humanize

```text
from std.collections import List

var present = Morrow(2026, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))

print(present.shift(hours=2).humanize(present))

var granularity = List[String]()
granularity.append("hour")
granularity.append("minute")

print(present.shift(minutes=66).humanize(present, granularity=granularity))
```

使用 `only_distance=True` 可以省略方向短语。

## Dehumanize

```text
var present = Morrow(2026, 1, 1, 12, 0, 0, 0, TimeZone.from_utc("UTC"))

print(present.dehumanize("2 days ago"))
print(present.dehumanize("in a minute and 6 seconds"))
```

支持的单位包括 years、quarters、months、weeks、days、hours、minutes 和 seconds。

## Locale

```text
print(present.shift(hours=-2).humanize(present, locale="zh-CN"))
print(present.shift(hours=2).humanize(present, locale="zh-TW"))
print(present.dehumanize("1小时6分钟后", locale="zh-CN"))
```

支持 `en`、`zh-CN` / `zh-Hans`、`zh-TW` / `zh-Hant`。未知语言报错。中文输入使用数字和明确单位，以“前”或“后/後”结尾；不解析任意自然语言。多粒度输出和 `only_distance` 同样支持语言选择。
