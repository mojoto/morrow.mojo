import tomllib
import argparse
import os
import subprocess
import shutil
import glob
import logging
from typing import Any
from pathlib import Path

import yaml
import typer

logger = logging.getLogger(__name__)

app = typer.Typer()

TEMP_DIR = Path(os.path.expandvars("$HOME/tmp"))
PIXI_TOML_PATH = Path("pixi.toml")
RECIPE_PATH = Path("recipe.yaml")
CONDA_BUILD_PATH = Path(os.environ.get("CONDA_BLD_PATH", os.getcwd()))
"""If `CONDA_BLD_PATH` is set, then publish from there. Otherwise, publish from the current directory."""

def load_project_config() -> dict[str, Any]:
    """Loads the project configuration from the pixi.toml file."""
    with PIXI_TOML_PATH.open("rb") as f:
        return tomllib.load(f)

PROJECT_CONFIG = load_project_config()


class TemporaryBuildDirectory:
    """Context manager to create a temporary build directory."""
    def __enter__(self) -> Path:
        TEMP_DIR.mkdir(parents=True, exist_ok=True)
        package = PROJECT_CONFIG["package"]["name"]
        subprocess.run(
            ["mojo", "package", f"src/{package}", "-o", f"{TEMP_DIR}/{package}.mojopkg"],
            check=True,
        )
        return TEMP_DIR

    def __exit__(self, exc_type: Any, exc_value: Any, traceback: Any) -> None:
        if TEMP_DIR.exists():
            shutil.rmtree(TEMP_DIR)
            logger.info("Temporary build directory removed.")


def format_dependency(name: str, version: str) -> str:
    """Converts the list of dependencies from the pixi.toml into a list of strings for the recipe."""
    start = 0
    operator = "=="
    if version[0] in {"<", ">"}:
        if version[1] != "=":
            operator = version[0]
            start = 1
        else:
            operator = version[:2]
            start = 2

    return f"{name} {operator} {version[start:]}"


@app.command()
def generate_recipe() -> None:
    """Generates a recipe for the project based on the project configuration in the pixi.toml."""
    # Replace the placeholders in the recipe with the project configuration.
    recipe = {
        "context": {"version": "13.4.2"},
        "package": {},
        "source": [],
        "build": {
            "script": [
                "mkdir -p ${PREFIX}/lib/mojo",
            ]
        },
        "requirements": {
            "run": []
        },
        "about": {},
    }

    # Populate package information
    package_name = PROJECT_CONFIG["package"]["name"]
    recipe["package"]["name"] = package_name
    recipe["package"]["version"] = PROJECT_CONFIG["package"]["version"]

    # Populate source files
    recipe["source"].append({"path": "src"})
    recipe["source"].append({"path": PROJECT_CONFIG["workspace"]["license-file"]})

    # Populate build script
    recipe["build"]["script"].append(
        f"pixi run mojo package {package_name} -o ${{PREFIX}}/lib/mojo/{package_name}.mojopkg"
    )

    # Populate requirements
    for dependency, version in PROJECT_CONFIG["dependencies"].items():
        recipe["requirements"]["run"].append(format_dependency(dependency, version))

    # Populate about section
    recipe["about"]["homepage"] = PROJECT_CONFIG["workspace"]["homepage"]
    recipe["about"]["license"] = PROJECT_CONFIG["workspace"]["license"]
    recipe["about"]["license_file"] = PROJECT_CONFIG["workspace"]["license-file"]
    recipe["about"]["summary"] = PROJECT_CONFIG["workspace"]["description"]
    recipe["about"]["repository"] = PROJECT_CONFIG["workspace"]["repository"]

    # Write the final recipe.
    with Path("recipe.yaml").open("w+") as f:
        yaml.dump(recipe, f)


@app.command()
def publish(channel: str) -> None:
    """Publishes the conda packages to the specified conda channel."""
    logger.info(f"Publishing packages to: {channel}")
    for file in glob.glob(f'{CONDA_BUILD_PATH}/**/*.conda'):
        try:
            subprocess.run(
                ["pixi", "upload", f"https://prefix.dev/api/v1/upload/{channel}", file],
                check=True,
            )
        except subprocess.CalledProcessError:
            pass
        os.remove(file)


def remove_temp_directory() -> None:
    """Removes the temporary directory used for building the package."""
    if TEMP_DIR.exists():
        logger.info("Removing temp directory.")
        shutil.rmtree(TEMP_DIR)


def prepare_temp_directory() -> None:
    """Creates the temporary directory used for building the package. Adds the compiled mojo package to the directory."""
    remove_temp_directory()
    TEMP_DIR.mkdir()
    package = PROJECT_CONFIG["package"]["name"]
    subprocess.run(
        ["mojo", "package", f"src/{package}", "-o", f"{TEMP_DIR}/{package}.mojopkg"],
        check=True,
    )


@app.command()
def run_tests(path: str | None = None) -> None:
    """Executes the tests for the package."""
    TEST_DIR = Path("src/test")

    logger.info("Building package and copying tests.")
    with TemporaryBuildDirectory() as temp_directory:
        shutil.copytree(TEST_DIR, temp_directory, dirs_exist_ok=True)
        target = temp_directory
        if path:
            target = target / path
        logger.info(f"Running tests at {target}...")
        subprocess.run(["mojo", "test", target], check=True)


@app.command()
def run_examples(path: str | None = None) -> None:
    """Executes the examples for the package."""
    EXAMPLE_DIR = Path("examples")
    if not EXAMPLE_DIR.exists():
        logger.info(f"Path does not exist: {EXAMPLE_DIR}.")
        return

    logger.info("Building package and copying examples.")
    with TemporaryBuildDirectory() as temp_directory:
        shutil.copytree(EXAMPLE_DIR, temp_directory, dirs_exist_ok=True)
        example_files = EXAMPLE_DIR.glob("*.mojo")
        if path:
            example_files = EXAMPLE_DIR.glob(path)

        logger.info(f"Running examples in {example_files}...")
        for file in example_files:
            name, _ = file.name.split(".", 1)
            shutil.copyfile(file, temp_directory / file.name)
            subprocess.run(["mojo", "build", temp_directory / file.name, "-o", temp_directory / name], check=True)
            subprocess.run([temp_directory / name], check=True)


@app.command()
def run_benchmarks(path: str | None = None) -> None:
    BENCHMARK_DIR = Path("benchmarks")
    if not BENCHMARK_DIR.exists():
        logger.info(f"Path does not exist: {BENCHMARK_DIR}.")
        return

    logger.info("Building package and copying benchmarks.")
    with TemporaryBuildDirectory() as temp_directory:
        shutil.copytree(BENCHMARK_DIR, temp_directory, dirs_exist_ok=True)
        benchmark_files = BENCHMARK_DIR.glob("*.mojo")
        if path:
            benchmark_files = BENCHMARK_DIR.glob(path)

        logger.info(f"Running benchmarks in {benchmark_files}...")
        for file in benchmark_files:
            name, _ = file.name.split(".", 1)
            shutil.copyfile(file, temp_directory / file.name)
            subprocess.run(["mojo", "build", temp_directory / file.name, "-o", temp_directory / name], check=True)
            subprocess.run([temp_directory / name], check=True)


@app.command()
def build_conda_package() -> None:
    """Builds the conda package for the project."""
    # Generate the recipe if it does not exist already.
    if not RECIPE_PATH.exists():
        generate_recipe()

    subprocess.run(
        ["pixi", "build", "-o", CONDA_BUILD_PATH],
        check=True,
    )
    os.remove("recipe.yaml")


if __name__ == "__main__":
    app()
