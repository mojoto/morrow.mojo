---
sidebar_position: 4
---

# 格式化

Morrow 支持 Arrow 风格 `format`、Python 风格 `strftime`，以及 ISO 输出辅助方法。

## ISO 输出

```text
var value = Morrow(2026, 1, 1, 0, 0, 0, 1234)

print(value.isoformat())
print(value.isoformat(timespec="milliseconds"))
```

## Arrow 风格 token

```text
from morrow import FORMAT_RSS, Morrow, TimeZone

var value = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone.from_utc("UTC"))

print(value.format("YYYY-MM-DD HH:mm:ss.SSSSSS ZZ"))
print(value.format("dddd, DD MMM YYYY HH:mm:ss ZZZ"))
print(value.format("DDD W X x"))
print(value.format("Do MMMM YYYY"))
print(value.format(FORMAT_RSS))
```

字面量文本可以放在方括号中：

```text
print(Morrow(2026, 1, 1).format("YYYY[Y]MM[M]DD[D]"))
```

## strftime

```text
var ist = Morrow(2026, 1, 1, 3, 4, 5, 123456, TimeZone(19800, "IST"))

print(ist.strftime("%Y-%m-%d %H:%M:%S.%f %z %Z"))
```
