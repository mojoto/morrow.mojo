---
sidebar_position: 2
---

# 快速开始

## 使用 Pixi 安装

先把 Modular 和 Modular Community channel 添加到 Pixi 工作区，再安装 Morrow：

```bash
pixi workspace channel add --prepend https://repo.prefix.dev/modular-community
pixi workspace channel add --prepend https://repo.prefix.dev/max
pixi add morrow
```

该包会把与编译器版本兼容的 `morrow.mojoc` 安装到当前环境，其他 Mojo 包可以直接导入。

## 初始化本地环境

先安装 [uv](https://docs.astral.sh/uv/getting-started/installation/)，再在仓库根目录运行：

```bash
make install
uv run mojo repl
```

`make install` 会使用 Python 3.14 创建或复用 `.venv`，并安装锁定版本的 Mojo。从仓库根目录启动 REPL 后，可以直接导入 `morrow` 源码包。

## 在其他项目中使用 Morrow

可以把 `morrow` 源码目录复制到你的项目中，也可以构建预编译包：

```bash
make build
```

该命令会生成 `morrow.mojoc`。预编译包必须使用与构建时相同版本的 Mojo 编译器导入。也可以从
[GitHub releases 页面](https://github.com/mojoto/morrow.mojo/releases) 获取版本匹配的构建产物。

## 导入

```mojo
from morrow import Morrow, TimeDelta, TimeZone
```

## 创建值

```mojo
var now = Morrow.now()
var utc_now = Morrow.utcnow()
var from_timestamp = Morrow.utcfromtimestamp("1767225600.5")
var from_iso = Morrow.fromisoformat("20260101T030405.123456Z")
var fixed = Morrow.get(1767225600.5, "+05:30")
```

## 格式化输出

```mojo
var value = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))

print(value)
print(value.isoformat())
print(value.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(value.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))
```
