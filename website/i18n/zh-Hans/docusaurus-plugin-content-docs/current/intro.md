---
sidebar_position: 1
---

# Morrow.mojo

Morrow 是用于日期时间处理的 Mojo 库。它提供受 Arrow 启发的 API，用于构造、解析、格式化、偏移、比较和人性化展示日期时间值。

这个库默认使用 UTC，支持固定偏移时区，并专注于提供适合 Mojo 项目的紧凑 API。

## 核心能力

- 从组件、时间戳、ISO 8601 字符串、日期视图、日期时间值和 ISO 日历元组创建 `Morrow` 值。
- 使用 Arrow 风格 token 和 Python 风格 `strftime` 解析、格式化字符串。
- 在固定偏移时区之间转换。
- 按年、季度、月、周、日、小时、分钟、秒和微秒偏移时间。
- 计算 floor、ceiling、span、range、span range 和 interval。
- 人性化描述和反向解析英文相对时间。

## 包结构

```text
morrow/
  morrow.mojo       # Morrow 日期时间类型和核心 API
  timezone.mojo     # TimeZone 固定偏移时区辅助类型
  timedelta.mojo    # TimeDelta 时长辅助类型
  formatter.mojo    # format 和 strftime 实现
```
