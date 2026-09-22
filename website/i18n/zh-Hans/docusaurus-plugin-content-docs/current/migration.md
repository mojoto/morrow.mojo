---
sidebar_position: 9
---

# 升级指南

## 升级到 1.0

1.0 保留已文档化的 0.9 API 和行为，发布包新增隔离消费者验证。支持的编译器、二进制兼容性和分发校验见[稳定性约定](./stability.md)。

## 升级到 0.9

地区时区和本地时区现在使用 ICU，Linux 需要安装 ICU 运行库。小时及更小单位和 TimeDelta 使用实际时长，日历日偏移保持墙上时间；原有固定偏移结果不变。token 解析和格式化现在支持 UTF-8 字面量。

## 升级到 0.8

### 构造和错误规则

`Morrow(...)` 现在校验日期、时间和 UTC 偏移，默认使用 UTC。构造和创建日期的辅助方法可能抛出错误，调用方需要声明 `raises` 或使用 `try/except`。

创建无时区的墙上时间时，显式传入 `tz=TimeZone.none()` 或调用 `.naive()`。`now()` 和 `fromtimestamp()` 保留本地时间语义；`get()` 和 `utcnow()` 使用 UTC。

无时区值和有时区值相等比较返回 false；排序、日期相减、相对时间展示和区间判断拒绝混用。转换同一时刻使用 `.to(...)`；给墙上时间附加时区使用 `.replace(tzinfo=...)`。

年份范围为 1–9999。单个偏移参数超过整个支持日历范围时，在整数乘法前报错，即使其他参数可能抵消它也不例外。生成越界区间时同样报错，可通过 `limit` 在边界前停止。

### 惰性区间

原有 `range/span_range/interval` 继续返回列表。新增的 `iter_range/iter_span_range/iter_interval` 按需产生一个结果，辅助内存为常数；列表和迭代接口共享生成逻辑及边界规则。

```text
for point in Morrow.iter_range("second", start, end, limit=10):
    print(point)

for span in Morrow.iter_interval("month", start, end, interval=3, exact=True):
    print(span)
```

`iter_range(frame, start, limit=...)` 可以省略终点，区间迭代需要终点。需要指定时区时，先显式转换或替换起止值的时区。迭代返回值，for 循环从迭代器当前状态的副本开始。

### 星期偏移

`shift_weekday(weekday, nth=1)` 使用周一=0、周日=6。正数 nth 向后寻找，负数向前寻找；当天符合星期时计入第一次，0 无效。原有 `shift(weekday=...)` 行为不变。
