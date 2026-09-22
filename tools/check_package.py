#!/usr/bin/env python3
"""Run the public API smoke test using only a precompiled release package."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path, help="A .mojoc file or release .tar.gz")
    parser.add_argument("--mojo", type=Path, default=ROOT / ".venv/bin/mojo")
    args = parser.parse_args()
    compiler = args.mojo.resolve(strict=True)
    package = args.package.resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix="morrow-package-") as directory:
        root = Path(directory)
        if package.name.endswith(".tar.gz"):
            with tarfile.open(package) as archive:
                archive.extractall(root, filter="data")
        else:
            shutil.copy2(package, root / "morrow.mojoc")
        libraries = list(root.rglob("morrow.mojoc"))
        if len(libraries) != 1:
            raise ValueError("Expected exactly one morrow.mojoc in the package")
        smoke = root / "smoke.mojo"
        shutil.copy2(ROOT / "conda.recipe/test.mojo", smoke)
        subprocess.run(
            [str(compiler), "run", "-I", str(libraries[0].parent), str(smoke)],
            cwd=root,
            check=True,
        )
    print(f"Passed isolated package smoke test: {package.name}")


if __name__ == "__main__":
    main()
