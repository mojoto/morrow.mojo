---
sidebar_position: 5
---

# 时区

Morrow 支持 UTC、固定偏移、IANA 地区名称和宿主本地时区。日期构造默认使用 UTC。

```text
from morrow import Morrow, TimeZone, TimeDelta

var utc = Morrow(2024, 7, 1)
print(utc.to("America/New_York"))
print(utc.to("Asia/Shanghai"))
print(utc.to("+05:30"))

var ny = TimeZone.from_name("America/New_York")
var local = Morrow(2024, 7, 1, 12, tz=ny)
```

`TimeZone.from_utc(...)` 解析 UTC、GMT、Z 及带小时、分钟、秒的偏移。`TimeZone.from_name(...)` 校验地区名称。`TimeZone(offset, name)` 仍表示带显示名称的固定偏移，仅设置地区名称不会附加时区规则。

`to(...)` 保持同一时刻，`replace(tzinfo=...)` 保持墙上时间字段并按新时区解释。地区时区按每个日期解析偏移，包括历史规则。`get` 的 `ZZZ` 和 `strptime` 的 `%Z` 支持地区名称。

## 重复和不存在的时间

```text
var early = Morrow(2024, 11, 3, 1, 30, tz=ny, fold=0)
var late = early.replace(fold=1)
print(early.ambiguous())  # True
print((late - early).total_seconds())  # 3600

var missing = Morrow(2024, 3, 10, 2, 30, tz=ny)
print(missing.imaginary())  # True
print(missing.to(ny))  # 跳时后的 03:30
```

对于重复时间，fold 0 选择较早一次，fold 1 选择较晚一次。对于不存在的时间，fold 0 使用切换前偏移，fold 1 使用切换后偏移。构造时保留原字段供检查；转换到同一时区可将对应时刻解析为实际存在的时间。

## 日历偏移和实际时长

```text
var before = Morrow(2024, 3, 9, 12, tz=ny)
print(before.shift(days=1))   # 次日 12:00，实际经过 23 小时
print(before.shift(hours=24)) # 次日 13:00，实际经过 24 小时
print(before + TimeDelta(days=1)) # 同样为实际 24 小时
```

年、季度、月、周、日和星期使用日历运算。小时及更小单位，以及 TimeDelta 加减，使用实际经过的时长。混合偏移先处理日历字段。日历偏移默认修正不存在的时间，传入 `check_imaginary=False` 可保留。一天的区间可能有 23 或 25 小时，按小时迭代可以包含重复小时的两次出现。

## 运行依赖与时区数据

地区时区和本地时区通过原生 FFI 使用 ICU，无需 Python。macOS 自带 ICU；Linux 需要安装 ICU 运行库，例如 Debian/Ubuntu 可运行 `sudo apt-get install libicu-dev`。Conda 配方已声明 ICU 运行依赖。优先加载当前 Conda 环境的 ICU，其次使用系统库；UTC 和固定偏移计算不加载 ICU。

时区规则通过更新所选 ICU 包或操作系统更新。不同数据版本可能包含不同的政府规则变更。缺少库或地区名称无效时会报错，不会静默退回 UTC。

`now()` 和 `fromtimestamp()` 使用宿主本地时区。需要指定本地时区时，在启动进程前设置 `TZ`；不支持 ICU 初始化后修改进程时区。同一进程需要多个独立时区时，使用明确的地区名称。
