---
sidebar_position: 10
---

# 测试

运行 `make test` 执行单元测试。每个 `tests/test_*.mojo` 文件通过标准库 `TestSuite` 自动发现 `test_` 函数。CI 在 Linux x86-64、Linux ARM64 和 macOS ARM64 上运行同一套测试，每个平台依次验证 Mojo 1.0.0 和 1.1.0。

```sh
make test
make test TEST_FILES=tests/test_iana.mojo
uv run mojo run -I . tests/test_iana.mojo --only test_gap_fold_offsets_and_dst
uv run mojo run -I . tests/test_iana.mojo --skip-all
```

`--only` 选择测试函数，`--skip` 排除测试，`--skip-all` 只收集、不执行测试体。只收集测试不代表验证通过；实际测试失败时命令以非零状态退出。

## 检查范围

| 测试组 | 主要检查 |
| --- | --- |
| 核心与契约 | 构造、世纪闰年、边界、偏移、时区感知混用、比较及序列化 |
| 解析与格式化 | ISO 和 token、格式回退、文本匹配边界、Unicode 字面量、非法输入及时间戳单位归一化 |
| 时区 | 历史偏移、DST 重复/缺失、南半球季节、半小时切换、整日跳过、负数微秒时间戳 |
| 本地化 | 全部月份和星期、上下午边界、语言别名、非法语言、中文相对时间单位和错误输入 |
| 迭代器 | 惰性、独立副本、耗尽、零上限、反向范围、裁剪、末尾不足一组以及 DST 小时序列 |
| 性质测试 | 日期序号、时间戳、时长、固定偏移、本地化日期及 IANA 转换的不变量 |

性质测试通过标准库 `std.testing.prop.Rng` 使用固定种子，每项执行 1,000 组样本，共 6,000 组。失败信息带有相关输入，种子写在各测试旁。两个编译器运行相同的输入，并以显式边界用例补足随机采样不易命中的情况。一个测试函数可以包含多组样例；测试函数数和样本数都不是源码覆盖率。

官方还提供 `PropTest` 执行器。最小调用在本机 1.1 编译通过，但在 1.0 遇到泛型回调类型错误；本项目直接使用两个版本共有的固定种子生成器，保持性质测试一致。

## 覆盖率与工具状态

以下结论于 2026 年 9 月 22 日，结合官方文档及 Mojo 1.0.0、1.1.0 实测确认：

- `TestSuite` 支持自动发现、筛选、跳过、耗时与结果报告。
- `assert_raises(contains=...)` 可以检查异常及其消息。
- `std.testing.prop` 提供输入生成器和性质测试基础能力。
- 官方 CLI 未提供已支持的行/分支覆盖率命令或插桩选项；两个编译器均拒绝 `mojo build --coverage`。本项目不发布源码覆盖率百分比。
- `--sanitize address` 和 `--sanitize thread` 属于实验性运行时检查，不是覆盖率统计。本机 macOS 1.1 试跑因 ASan runtime 符号缺失而无法链接/加载，因此没有将其标记为已通过或设为 CI 门禁。

官方参考：[TestSuite](https://mojolang.org/docs/std/testing/suite/TestSuite/)、[assert_raises](https://mojolang.org/docs/std/testing/testing/assert_raises/)、[性质测试](https://mojolang.org/docs/std/testing/prop/)、[编译选项](https://mojolang.org/docs/cli/build/)。
