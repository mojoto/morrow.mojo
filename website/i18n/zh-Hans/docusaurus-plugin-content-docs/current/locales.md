---
sidebar_position: 7
---

# 语言

Morrow 内置 81 种语言，用于格式化、解析、`humanize` 和 `dehumanize`。除简体中文和繁体中文外，各语言的文本与 Arrow 1.4.0 一致；两种中文保持 Morrow 1.0 的输出。

```text
from morrow import Locale, Morrow

var dt = Morrow(2026, 1, 1, 15)
print(dt.format("dddd Do MMMM YYYY", locale="fr"))   # jeudi 1er janvier 2026
print(dt.shift(hours=-5).humanize(dt, locale="ru"))  # 5 часов назад
print(dt.dehumanize("vor 2 Tagen", locale="de"))
print(Morrow.get("1 января 2026", "D MMMM YYYY", locale="ru"))
```

所有 `locale` 参数都可以传语言名称或 `Locale` 值。名称不区分大小写，`_` 和 `-` 等价，因此 `pt_BR`、`pt-br` 和 `PT-BR` 加载的是同一种语言。未知名称会报 `unsupported locale`。

## 复用语言对象

传入名称时，每次调用都会重新加载该语言的数据。在循环中，先加载一次 `Locale`，再传入这个值：

```text
var french = Locale("fr")
for day in Morrow.iter_range("day", start, limit=365):
    print(day.format("dddd D MMMM", locale=french))
```

`Locale.available()` 返回 81 个规范名称，`Locale.aliases("ar")` 返回某种语言接受的全部名称。

## 自定义语言

`Locale` 的字段都是公开的。以某种内置语言为基础，修改需要的部分：

```text
var pirate = Locale("en")
pirate.name = "en-pirate"
pirate.month_names[0] = "Janarrr"
pirate.meridians = ["ay", "pee", "AY", "PEE"]
pirate.set_timeframe("hours", "{0} bells")
pirate.past = "{0} back"

print(Morrow(2026, 1, 1, 15).format("MMMM D A", locale=pirate))  # Janarrr 1 PEE
```

名称列表从下标 0 开始：`month_names[0]` 是一月，`day_names[0]` 是星期一。`meridians` 依次为 am、pm、AM、PM。`ordinals` 可以覆盖内置的 1–31 日序数。

时间单位文本用 `{0}` 表示数量。需要按数量或方向选择不同形式时，设置 `plural_rule` 并传入对应的键：

| `plural_rule` | 键 |
| --- | --- |
| `slavic` | `singular`、`dual`、`plural` |
| `arabic`、`hebrew` | `2`、`ten`、`higher` |
| `double` | `double`、`higher` |
| `maltese` | `dual`、`plural` |
| `czech` | `zero`、`past`，以及 `future` 或 `future-singular`/`future-paucal` |
| `future_if_positive`、`past_if_negative`、`icelandic` | `past`、`future` |

```text
var keys: List[String] = ["singular", "dual", "plural"]
var forms: List[String] = ["{0} dzień", "{0} dni", "{0} dni"]
pirate.plural_rule = "slavic"
pirate.set_timeframe("days", keys, forms)
```

`Locale.describe(frame, delta)` 和 `describe_multi(frames, deltas)` 可以直接格式化一个或多个带符号的时间单位，例如 `describe("hours", -2)`。

## 内置语言

| 名称 | 语言 | 名称 | 语言 |
| --- | --- | --- | --- |
| `af` | 南非荷兰语 | `lo` | 老挝语 |
| `am` | 阿姆哈拉语 | `lt` | 立陶宛语 |
| `ar` | 阿拉伯语 | `lv` | 拉脱维亚语 |
| `ar-iq` | 黎凡特阿拉伯语 | `mk` | 马其顿语 |
| `ar-ma` | 摩洛哥阿拉伯语 | `mk-latn` | 马其顿语（拉丁字母） |
| `ar-mr` | 毛里塔尼亚阿拉伯语 | `ml` | 马拉雅拉姆语 |
| `ar-tn` | 阿尔及利亚/突尼斯阿拉伯语 | `mr` | 马拉地语 |
| `az` | 阿塞拜疆语 | `ms` | 马来语 |
| `be` | 白俄罗斯语 | `mt` | 马耳他语 |
| `bg` | 保加利亚语 | `nb` | 书面挪威语 |
| `bn` | 孟加拉语 | `ne` | 尼泊尔语 |
| `ca` | 加泰罗尼亚语 | `nl` | 荷兰语 |
| `cs` | 捷克语 | `nn` | 新挪威语 |
| `da` | 丹麦语 | `or` | 奥里亚语 |
| `de` | 德语 | `pl` | 波兰语 |
| `de-at` | 奥地利德语 | `pt` | 葡萄牙语 |
| `de-ch` | 瑞士德语 | `pt-br` | 巴西葡萄牙语 |
| `ee` | 爱沙尼亚语 | `rm` | 罗曼什语 |
| `el` | 希腊语 | `ro` | 罗马尼亚语 |
| `en` | 英语 | `ru` | 俄语 |
| `eo` | 世界语 | `se` | 萨米语 |
| `es` | 西班牙语 | `si` | 僧伽罗语 |
| `eu` | 巴斯克语 | `sk` | 斯洛伐克语 |
| `fa` | 波斯语 | `sl` | 斯洛文尼亚语 |
| `fi` | 芬兰语 | `sq` | 阿尔巴尼亚语 |
| `fr` | 法语 | `sr` | 塞尔维亚语 |
| `fr-ca` | 加拿大法语 | `sv` | 瑞典语 |
| `he` | 希伯来语 | `sw` | 斯瓦希里语 |
| `hi` | 印地语 | `ta` | 泰米尔语 |
| `hr` | 克罗地亚语 | `th` | 泰语 |
| `hu` | 匈牙利语 | `tl` | 他加禄语 |
| `hy` | 亚美尼亚语 | `tr` | 土耳其语 |
| `id` | 印度尼西亚语 | `ua` | 乌克兰语 |
| `is` | 冰岛语 | `ur` | 乌尔都语 |
| `it` | 意大利语 | `uz` | 乌兹别克语 |
| `ja` | 日语 | `vi` | 越南语 |
| `ka` | 格鲁吉亚语 | `zh-cn` | 简体中文 |
| `kk` | 哈萨克语 | `zh-hk` | 香港中文 |
| `ko` | 韩语 | `zh-tw` | 繁体中文 |
| `la` | 拉丁语 | `zu` | 祖鲁语 |
| `lb` | 卢森堡语 | | |

地区别名与 Arrow 一致，例如 `en-gb`、`es-es`、`ar-eg`、`sr-rs`。`zh`、`zh-hans` 和 `zh-hant` 选择对应的中文。

## 与 Arrow 的差异

- 泰语和老挝语按佛历（+543 年）格式化年份，解析时换算回公历年份。`YY` 的 00–99 对应佛历 2500–2599 年。
- 有 16 种语言没有“周”的文本。自动 `humanize` 在这些语言中改用天数，而 Arrow 会报错。显式指定周或季度粒度时，如果该语言没有对应文本，仍会报 `not translated`。
- `dehumanize` 支持全部内置语言，包括 Arrow 不支持的 18 种（如阿拉伯语、希伯来语、韩语、泰语），可以读取 `humanize` 生成的文本。冰岛语 “nokkrar sekúndur”（几秒）不含数字，按 1 秒处理。
- `Do` 也能解析 `format` 输出的序数，例如德语 `3.` 和韩语 `세번째`。
- 希伯来语多单位文本按整体距离判断方向，而不是按最后一个单位。
- 阿姆哈拉语将来时的“小时”使用小时一词；Arrow 1.4.0 在此处误用了“秒”。

英文和中文的 `dehumanize` 保持 1.0 的语法。
