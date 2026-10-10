<p align="center">
  <img src="website/static/img/morrow-logo.png" alt="Morrow logo" width="128" height="128" />
</p>

# Morrow.mojo

面向 Mojo 的友好日期时间工具库。Morrow 提供日期时间 API，用于创建、解析、格式化、偏移、比较和人性化展示日期时间值。

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

该包会把与编译器版本兼容的 `morrow.mojoc` 安装到当前 Pixi 环境，无需复制源码即可导入。channel 上的 Morrow 1.1 基于 Mojo 1.1 构建；使用 Mojo 1.0 的项目在该 channel 上会解析到 Morrow 0.7.0，如需在 Mojo 1.0 上使用 1.1，请下载对应的 [release 包](https://github.com/mojoto/morrow.mojo/releases)。

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

Morrow 默认使用 UTC，支持 IANA 和固定偏移时区，可以解析 ISO 8601 字符串和 POSIX 时间戳，并支持 日期时间 token 与 Python 风格 `strftime` 格式化。

## 开发

源码支持 Mojo 1.0.0 和 1.1.0。使用 `make install MOJO_VERSION=1.0.0`
选择 1.0（默认是 1.1.0），然后运行 `make test build`。
CI 在 Linux x86-64、Linux ARM64 和 macOS ARM64 上测试并预编译两个版本。
Release 按编译器版本分别构建，请选择匹配的归档。
为兼容 1.0 保留的字符串 API 会在 Mojo 1.1 下产生弃用警告。

`make package` 会为每个支持的编译器各构建一个 Conda 包，分别精确依赖对应的 Mojo 编译器版本。
Modular Community channel 的每个配方只构建一个编译器版本，目前发布的是 Mojo 1.1 构建。


运行 `make help` 可以查看所有可用目标。

| 目标 | 说明 |
| --- | --- |
| `make install` | 使用 uv 创建或复用 `.venv` 并安装锁定版本的 Mojo |
| `make test` | 运行所有 `tests/test_*.mojo` 文件 |
| `make test-package` | 构建预编译包并在源码目录之外验证 |
| `make benchmark` | 每项性能基准运行五组样本 |
| `make format` | 格式化 `morrow` 和 `tests` 目录 |
| `make build` | 将 `morrow` 预编译为 `morrow.mojoc` |
| `make package` | 使用 `rattler-build` 构建可分发的 Conda 包 |
| `make clean` | 删除 `morrow.mojoc` |
| `make doc-install` | 安装 Docusaurus 依赖 |
| `make doc-build` | 构建 Docusaurus 静态站点 |
| `make doc-serve` | 预览已构建的 Docusaurus 站点 |
| `make doc-clean` | 删除 Docusaurus 生成文件 |

文档相关目标需要 Node.js 和 npm。先运行 `make doc-install` 安装依赖，再依次运行 `make doc-build` 和 `make doc-serve` 预览构建结果。

格式化、解析和相对时间支持 81 种语言，也可以用 `Locale` 自定义语言。命名时区和本地时区读取系统 tzdata，缺少时区文件时回退到 ICU（macOS 自带，Debian/Ubuntu 可安装 `libicu-dev`）。

验证命令、编译器兼容性和分发约定见[测试指南](https://mojoto.github.io/morrow.mojo/docs/testing)及 [1.x 稳定性约定](https://mojoto.github.io/morrow.mojo/docs/stability)。
