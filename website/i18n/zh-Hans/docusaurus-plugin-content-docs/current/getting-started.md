---
sidebar_position: 2
---

# 快速开始

## 安装

从 GitHub releases 页面下载 `morrow.mojopkg`，或者从本仓库构建：

```bash
make install
make build
```

如果希望直接 vendoring 源码，也可以把 `morrow` 目录复制到你的 Mojo 项目中。

## 导入

```text
from morrow import Morrow, TimeDelta, TimeZone
```

## 创建值

```text
var now = Morrow.now()
var utc_now = Morrow.utcnow()
var from_timestamp = Morrow.utcfromtimestamp("1767225600.5")
var from_iso = Morrow.fromisoformat("20260101T030405.123456Z")
var fixed = Morrow.get(1767225600.5, "+05:30")
```

## 格式化输出

```text
var value = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))

print(value)
print(value.isoformat())
print(value.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(value.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))
```
