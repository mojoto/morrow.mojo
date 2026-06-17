---
sidebar_position: 7
---

# 人性化时间

Morrow 可以用英文描述日期时间距离，也可以把这些距离反向应用到基准值上。

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
