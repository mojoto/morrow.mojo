---
sidebar_position: 5
---

# 时区

`TimeZone` 表示固定偏移时区。`Morrow` 默认使用 UTC，大多数接收时区的 API 都支持 `TimeZone` 值或 UTC 偏移字符串。

```text
from morrow import Morrow, TimeZone

var utc = Morrow(2026, 1, 1, 16, 30, 0, 123456, TimeZone.from_utc("UTC"))

print(utc.to("+08:00"))
print(utc.astimezone("-05:00"))
print(utc.utcoffset().total_seconds())
```

## 偏移解析

```text
print(TimeZone.from_utc("UTC+08:00").offset)
print(TimeZone.from_utc("+05:30").format())
print(TimeZone.from_utc("-05:30:15").format())
```

支持 `UTC`、`GMT`、`Z`、紧凑偏移写法如 `+0530`，以及带秒的偏移写法如 `+05:30:15`。

## 本地时间

```text
var local_now = Morrow.now("local")
print(local_now.tz.name)
```

本地时区会从宿主环境读取。
