# Morrow.mojo

面向 Mojo 的友好日期时间工具库。Morrow 提供受 Arrow 启发的 API，用于创建、解析、格式化、偏移、比较和人性化展示日期时间值。

<p align="center">
  <a href="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml">
    <img src="https://github.com/mojoto/morrow.mojo/actions/workflows/test.yml/badge.svg" alt="Test" />
  </a>
  <a href="https://github.com/mojoto/morrow.mojo/actions/workflows/pages.yml">
    <img src="https://github.com/mojoto/morrow.mojo/actions/workflows/pages.yml/badge.svg" alt="Documentation" />
  </a>
  <a href="https://github.com/mojoto/morrow.mojo/releases">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/mojoto/morrow.mojo">
  </a>
</p>

语言：[English](README.md) | 中文

> 文档：https://mojoto.github.io/morrow.mojo/zh-Hans/

## 安装

可以从 [releases](https://github.com/mojoto/morrow.mojo/releases) 下载 `morrow.mojopkg`，也可以从本仓库构建，或者直接把 `morrow` 目录 vendoring 到你的 Mojo 项目中。

```bash
make install
make build
```

如果直接使用源码目录，需要把项目根目录加入 Mojo 的导入路径：

```bash
uv run mojo run -I . main.mojo
```

## 用法

```mojo
from morrow import FORMAT_RSS, Morrow, TimeZone


def main() raises:
    var now = Morrow.now()
    print(now)

    var utc = Morrow.utcnow()
    print(utc)

    var parsed = Morrow.get("2026-01-01 03:04:05Z")
    print(parsed)
    print(parsed.format("YYYY-MM-DD HH:mm:ss ZZ"))

    var beijing = parsed.to("+08:00")
    print(beijing)

    var hour = beijing.span("hour")
    print(hour)

    print(beijing.isocalendar())
    print(beijing.timetuple())

    var rss = Morrow(2026, 1, 1, 10, 30, 35, 0, TimeZone(0, "UTC"))
    print(rss.format(FORMAT_RSS))
```

Morrow 默认使用 UTC，支持固定偏移时区，可以解析 ISO 8601 字符串和 POSIX 时间戳，并支持 Arrow 风格 token 与 Python 风格 `strftime` 格式化。

## 贡献

先安装 [uv](https://docs.astral.sh/uv/getting-started/installation/)，然后：

```bash
make install      # 将 Mojo 安装到 .venv
make test         # 运行测试
make format       # 格式化源码和测试
make build        # 构建 morrow.mojopkg
make doc-install  # 安装文档依赖
make doc-serve    # 预览文档站点
```
