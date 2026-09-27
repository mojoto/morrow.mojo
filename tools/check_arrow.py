"""Run with: uv run --with arrow==1.4.0 python tools/check_arrow.py.

Arrow is a development oracle only, never a Morrow runtime dependency.
"""
import json
import os
from pathlib import Path
import random
import shlex
import subprocess
import tempfile

import arrow
import arrow.locales

rng = random.Random(808)
lines = ["from std.testing import assert_equal", "from morrow import Morrow", "def main() raises:"]
checks = 0

def check(expression, expected):
    global checks
    lines.append(f"    assert_equal({expression}, {json.dumps(expected)})")
    checks += 1

for _ in range(80):
    value = arrow.get(rng.randrange(1900, 2099), rng.randrange(1, 13), rng.randrange(1, 29), rng.randrange(24), rng.randrange(60), rng.randrange(60))
    ctor = f"Morrow({value.year}, {value.month}, {value.day}, {value.hour}, {value.minute}, {value.second})"
    fmt = "YYYY-MM-DD HH:mm:ss ZZ"
    check(f'{ctor}.format("{fmt}")', value.format(fmt))
    months, days = rng.randrange(-18, 19), rng.randrange(-40, 41)
    check(f'{ctor}.shift(months={months}, days={days}).format("{fmt}")', value.shift(months=months, days=days).format(fmt))
    frame = rng.choice(["year", "quarter", "month", "week", "day", "hour", "minute", "second"])
    check(f'{ctor}.floor("{frame}").format("{fmt}")', value.floor(frame).format(fmt))
    check(f'{ctor}.ceil("{frame}").format("{fmt}")', value.ceil(frame).format(fmt))
    check(f'Morrow.get("{value.isoformat()}").format("{fmt}")', value.format(fmt))

# Built-in locales other than Morrow's 1.0 Chinese text follow Arrow.
classes = sorted(set(arrow.locales._locale_map.values()), key=lambda cls: cls.__name__)
base = arrow.get(2026, 1, 15, 12)
for cls in classes:
    if cls in (arrow.locales.ChineseCNLocale, arrow.locales.ChineseTWLocale):
        continue
    name = cls.names[0]
    value = arrow.get(rng.randrange(1900, 2099), rng.randrange(1, 13), rng.randrange(1, 29), rng.randrange(24))
    fmt = "dddd, MMMM Do YYYY hh A"
    ctor = f"Morrow({value.year}, {value.month}, {value.day}, {value.hour})"
    check(f'{ctor}.format("{fmt}", locale="{name}")', value.format(fmt, locale=name))
    seconds = rng.choice([-1, 1]) * rng.randrange(10, 60 * 60 * 24 * 300)
    try:
        expected = base.shift(seconds=seconds).humanize(base, locale=name)
    except ValueError:
        continue  # Arrow lacks this translation; Morrow falls back to days.
    check(f'Morrow(2026, 1, 15, 12).shift(seconds={seconds}).humanize(Morrow(2026, 1, 15, 12), locale="{name}")', expected)

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="morrow-arrow-") as directory:
    source = Path(directory) / "check.mojo"
    source.write_text("\n".join(lines) + "\n")
    subprocess.run(shlex.split(os.environ.get("MOJO", "uv run mojo")) + ["run", "-I", str(root), str(source)], cwd=root, check=True)
print(f"Passed {checks} deterministic comparisons against Arrow {arrow.__version__}")
