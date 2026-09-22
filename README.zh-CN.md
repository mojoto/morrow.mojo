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

Morrow 已发布到
[Modular 官方社区 channel](https://prefix.dev/channels/modular-community/packages/morrow)。
在[已经配置好 Mojo](https://docs.modular.com/mojo/manual/install/) 的 Pixi 工作区中，添加 Modular Community channel 后即可安装：

```bash
pixi workspace channel add --prepend https://repo.prefix.dev/modular-community
pixi add morrow
```

该包会把与编译器版本兼容的 `morrow.mojoc` 安装到当前 Pixi 环境，无需复制源码即可导入。

## 用法

将下面的示例粘贴到 REPL 中：

```mojo
from morrow import FORMAT_RSS, Morrow, TimeZone

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

## 开发

源码支持 Mojo 1.0.0 和 1.1.0。使用 `make install MOJO_VERSION=1.0.0`
选择 1.0（默认是 1.1.0），然后运行 `make test build`。
CI 在 Linux x86-64、Linux ARM64 和 macOS ARM64 上测试并预编译两个版本。
Release 按编译器版本分别构建，请选择匹配的归档。
为兼容 1.0 保留的字符串 API 会在 Mojo 1.1 下产生弃用警告。

运行 `make help` 可以查看所有可用目标。

| 目标 | 说明 |
| --- | --- |
| `make install` | 使用 uv 创建或复用 `.venv` 并安装锁定版本的 Mojo |
| `make test` | 运行所有 `tests/test_*.mojo` 文件 |
| `make format` | 格式化 `morrow` 和 `tests` 目录 |
| `make build` | 将 `morrow` 预编译为 `morrow.mojoc` |
| `make package` | 使用 `rattler-build` 构建可分发的 Conda 包 |
| `make clean` | 删除 `morrow.mojoc` |
| `make doc-install` | 安装 Docusaurus 依赖 |
| `make doc-build` | 构建 Docusaurus 静态站点 |
| `make doc-serve` | 预览已构建的 Docusaurus 站点 |
| `make doc-clean` | 删除 Docusaurus 生成文件 |

文档相关目标需要 Node.js 和 npm。先运行 `make doc-install` 安装依赖，再依次运行 `make doc-build` 和 `make doc-serve` 预览构建结果。
