---
sidebar_position: 7
---

# Locales

Morrow ships 81 built-in locales for formatting, parsing, `humanize`, and `dehumanize`. Apart from Simplified and Traditional Chinese, their text matches Arrow 1.4.0. The Chinese locales keep Morrow's 1.0 output.

```text
from morrow import Locale, Morrow

var dt = Morrow(2026, 1, 1, 15)
print(dt.format("dddd Do MMMM YYYY", locale="fr"))   # jeudi 1er janvier 2026
print(dt.shift(hours=-5).humanize(dt, locale="ru"))  # 5 часов назад
print(dt.dehumanize("vor 2 Tagen", locale="de"))
print(Morrow.get("1 января 2026", "D MMMM YYYY", locale="ru"))
```

Every `locale` argument accepts a name or a `Locale` value. Names ignore case and accept `_` or `-`, so `pt_BR`, `pt-br`, and `PT-BR` all load the same locale. An unknown name raises `unsupported locale`.

## Reusing a locale

Passing a name loads that locale's data on every call. In a loop, load the `Locale` once and pass the value instead:

```text
var french = Locale("fr")
for day in Morrow.iter_range("day", start, limit=365):
    print(day.format("dddd D MMMM", locale=french))
```

`Locale.available()` returns the 81 canonical names. `Locale.aliases("ar")` returns every accepted name for a locale.

## Custom locales

`Locale` fields are public. Start from a built-in locale and change what you need:

```text
var pirate = Locale("en")
pirate.name = "en-pirate"
pirate.month_names[0] = "Janarrr"
pirate.meridians = ["ay", "pee", "AY", "PEE"]
pirate.set_timeframe("hours", "{0} bells")
pirate.past = "{0} back"

print(Morrow(2026, 1, 1, 15).format("MMMM D A", locale=pirate))  # Janarrr 1 PEE
```

Name lists start at index 0, so `month_names[0]` is January and `day_names[0]` is Monday. `meridians` holds am, pm, AM, and PM, in that order. `ordinals` can override the built-in day ordinals 1–31.

Timeframes use a `{0}` placeholder for the count. For keyed forms, set a `plural_rule` and pass matching keys:

| `plural_rule` | Keys |
| --- | --- |
| `slavic` | `singular`, `dual`, `plural` |
| `arabic`, `hebrew` | `2`, `ten`, `higher` |
| `double` | `double`, `higher` |
| `maltese` | `dual`, `plural` |
| `czech` | `zero`, `past`, `future` or `future-singular`/`future-paucal` |
| `future_if_positive`, `past_if_negative`, `icelandic` | `past`, `future` |

```text
var keys: List[String] = ["singular", "dual", "plural"]
var forms: List[String] = ["{0} dzień", "{0} dni", "{0} dni"]
pirate.plural_rule = "slavic"
pirate.set_timeframe("days", keys, forms)
```

`Locale.describe(frame, delta)` and `describe_multi(frames, deltas)` format one or more signed timeframes directly, such as `describe("hours", -2)`.

## Built-in locales

| Name | Language | Name | Language |
| --- | --- | --- | --- |
| `af` | Afrikaans | `lo` | Lao |
| `am` | Amharic | `lt` | Lithuanian |
| `ar` | Arabic | `lv` | Latvian |
| `ar-iq` | Levant Arabic | `mk` | Macedonian |
| `ar-ma` | Moroccan Arabic | `mk-latn` | Macedonian (Latin) |
| `ar-mr` | Mauritanian Arabic | `ml` | Malayalam |
| `ar-tn` | Algerian/Tunisian Arabic | `mr` | Marathi |
| `az` | Azerbaijani | `ms` | Malay |
| `be` | Belarusian | `mt` | Maltese |
| `bg` | Bulgarian | `nb` | Norwegian Bokmål |
| `bn` | Bengali | `ne` | Nepali |
| `ca` | Catalan | `nl` | Dutch |
| `cs` | Czech | `nn` | Norwegian Nynorsk |
| `da` | Danish | `or` | Odia |
| `de` | German | `pl` | Polish |
| `de-at` | Austrian German | `pt` | Portuguese |
| `de-ch` | Swiss German | `pt-br` | Brazilian Portuguese |
| `ee` | Estonian | `rm` | Romansh |
| `el` | Greek | `ro` | Romanian |
| `en` | English | `ru` | Russian |
| `eo` | Esperanto | `se` | Sami |
| `es` | Spanish | `si` | Sinhala |
| `eu` | Basque | `sk` | Slovak |
| `fa` | Persian | `sl` | Slovenian |
| `fi` | Finnish | `sq` | Albanian |
| `fr` | French | `sr` | Serbian |
| `fr-ca` | Canadian French | `sv` | Swedish |
| `he` | Hebrew | `sw` | Swahili |
| `hi` | Hindi | `ta` | Tamil |
| `hr` | Croatian | `th` | Thai |
| `hu` | Hungarian | `tl` | Tagalog |
| `hy` | Armenian | `tr` | Turkish |
| `id` | Indonesian | `ua` | Ukrainian |
| `is` | Icelandic | `ur` | Urdu |
| `it` | Italian | `uz` | Uzbek |
| `ja` | Japanese | `vi` | Vietnamese |
| `ka` | Georgian | `zh-cn` | Simplified Chinese |
| `kk` | Kazakh | `zh-hk` | Hong Kong Chinese |
| `ko` | Korean | `zh-tw` | Traditional Chinese |
| `la` | Latin | `zu` | Zulu |
| `lb` | Luxembourgish | | |

Region aliases follow Arrow, for example `en-gb`, `es-es`, `ar-eg`, and `sr-rs`. `zh`, `zh-hans`, and `zh-hant` select the Chinese locales.

## Differences from Arrow

- Thai and Lao format years in the Buddhist era (+543) and parse them back to Gregorian years. For `YY`, 00–99 map to 2500–2599 BE.
- Automatic `humanize` falls back to days in the 16 locales without week text, where Arrow raises. Explicit week or quarter granularity still raises `not translated` in locales without that text.
- `dehumanize` works in every built-in locale, including the 18 that Arrow rejects, such as Arabic, Hebrew, Korean, and Thai. It reads the text `humanize` produces. Icelandic "nokkrar sekúndur" ("a few seconds") has no count and reads as one second.
- `Do` also parses the ordinals that `format` writes, such as German `3.` and Korean `세번째`.
- Multi-unit Hebrew text takes its direction from the whole distance, not from the last unit.
- Amharic future hours use the hour word; Arrow 1.4.0 repeats the seconds word there.

English and Chinese `dehumanize` keep their 1.0 grammar.
