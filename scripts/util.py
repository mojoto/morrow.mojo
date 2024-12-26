import tomllib
import argparse
import os
import subprocess
import shutil
import glob
from typing import Any


TEMP_DIR = os.path.expandvars("$HOME/tmp")
RECIPE_DIR = "./src"


def build_dependency_list(dependencies: dict[str, str]) -> list[str]:
    """Converts the list of dependencies from the mojoproject.toml into a list of strings for the recipe."""
    deps: list[str] = []
    for name, version in dependencies.items():
        start = 0
        operator = "=="
        if version[0] in {"<", ">"}:
            if version[1] != "=":
                operator = version[0]
                start = 1
            else:
                operator = version[:2]
                start = 2

        deps.append(f"    - {name} {operator} {version[start:]}")

    return deps


def load_project_config() -> dict[str, Any]:
    """Loads the project configuration from the mojoproject.toml file."""
    with open("mojoproject.toml", "rb") as f:
        return tomllib.load(f)


def generate_recipe(args: Any) -> None:
    """Generates a recipe for the project based on the project configuration in the mojoproject.toml."""
    # Load the project configuration and recipe template.
    config: dict[str, Any] = load_project_config()
    recipe: str
    with open("src/recipe.tmpl", "r") as f:
        recipe = f.read()

    # Replace the placeholders in the recipe with the project configuration.
    recipe = (
        recipe.replace("{{NAME}}", config["project"]["name"])
        .replace("{{DESCRIPTION}}", config["project"]["description"])
        .replace("{{LICENSE}}", config["project"]["license"])
        .replace("{{LICENSE_FILE}}", config["project"]["license-file"])
        .replace("{{HOMEPAGE}}", config["project"]["homepage"])
        .replace("{{REPOSITORY}}", config["project"]["repository"])
        .replace("{{VERSION}}", config["project"]["version"])
    )

    if args.mode != "default":
        recipe = recipe.replace("{{ENVIRONMENT_FLAG}}", f"-e {args.mode}")
    else:
        recipe = recipe.replace("{{ENVIRONMENT_FLAG}}", "")

    # Dependencies are the only notable field that changes between environments.
    dependencies: dict[str, str]
    match args.mode:
        case "default":
            dependencies = config["dependencies"]
        case _:
            dependencies = config["feature"][args.mode]["dependencies"]

    deps = build_dependency_list(dependencies)
    recipe = recipe.replace("{{DEPENDENCIES}}", "\n".join(deps))

    # Write the final recipe.
    with open("src/recipe.yaml", "w+") as f:
        recipe = f.write(recipe)


def publish_to_prefix(args: Any) -> None:
    """Publishes the conda packages to the specified conda channel."""
    # If CONDA_BLD_PATH is set, then pubilsh from there. Otherwise, publish from the current directory.
    conda_build_path = os.environ.get("CONDA_BLD_PATH", os.getcwd())
    if not conda_build_path:
        raise ValueError("CONDA_BLD_PATH environment variable is not set. This ")

    print(f"Publishing packages to: {args.channel}")
    for file in glob.glob(f'{conda_build_path}/**/*.conda'):
        try:
            subprocess.run(
                ["rattler-build", "upload", "prefix", "-c", args.channel, file],
                check=True,
            )
        except subprocess.CalledProcessError:
            pass
        os.remove(file)


def remove_temp_directory() -> None:
    """Removes the temporary directory used for building the package."""
    if os.path.exists(TEMP_DIR):
        print("Removing temp directory.")
        shutil.rmtree(TEMP_DIR)


def prepare_temp_directory() -> None:
    """Creates the temporary directory used for building the package. Adds the compiled mojo package to the directory."""
    package = load_project_config()["project"]["name"]
    remove_temp_directory()
    os.mkdir(TEMP_DIR)
    subprocess.run(
        ["mojo", "package", f"src/{package}", "-o", f"{TEMP_DIR}/{package}.mojopkg"],
        check=True,
    )


def execute_package_tests(args: Any) -> None:
    """Executes the tests for the package."""
    TEST_DIR = "./test"

    print("Building package and copying tests.")
    prepare_temp_directory()
    shutil.copytree(TEST_DIR, TEMP_DIR, dirs_exist_ok=True)

    target = TEMP_DIR
    if args.path:
        target = f"{target}/{args.path}"
    print(f"Running tests at {target}...")
    subprocess.run(["mojo", "test", target], check=True)

    remove_temp_directory()


def execute_package_examples(args: Any) -> None:
    """Executes the examples for the package."""
    EXAMPLE_DIR = "examples"
    if not os.path.exists("examples"):
        print(f"Path does not exist: {EXAMPLE_DIR}.")
        return

    print("Building package and copying examples.")
    prepare_temp_directory()
    shutil.copytree(EXAMPLE_DIR, TEMP_DIR, dirs_exist_ok=True)

    example_files = f'{EXAMPLE_DIR}/*.mojo'
    if args.path:
        example_files = f"{EXAMPLE_DIR}/{args.path}"

    print(f"Running examples in {example_files}...")
    for file in glob.glob(example_files):
        file_name = os.path.basename(file)
        name, _ = os.path.splitext(file_name)
        shutil.copyfile(file, f"{TEMP_DIR}/{file_name}")
        subprocess.run(["mojo", "build", f"{TEMP_DIR}/{file_name}", "-o", f"{TEMP_DIR}/{name}"], check=True)
        subprocess.run([f"{TEMP_DIR}/{name}"], check=True)

    remove_temp_directory()


def execute_package_benchmarks(args: Any) -> None:
    BENCHMARK_DIR = "./benchmarks"
    if not os.path.exists("benchmarks"):
        print(f"Path does not exist: {BENCHMARK_DIR}.")
        return

    print("Building package and copying benchmarks.")
    prepare_temp_directory()
    shutil.copytree(BENCHMARK_DIR, TEMP_DIR, dirs_exist_ok=True)

    benchmark_files = f'{BENCHMARK_DIR}/*.mojo'
    if args.path:
        benchmark_files = f"{BENCHMARK_DIR}/{args.path}"

    print(f"Running benchmarks in {benchmark_files}...")
    for file in glob.glob(benchmark_files):
        file_name = os.path.basename(file)
        name, _ = os.path.splitext(file_name)
        shutil.copyfile(file, f"{TEMP_DIR}/{file_name}")
        subprocess.run(["mojo", "build", f"{TEMP_DIR}/{file_name}", "-o", f"{TEMP_DIR}/{name}"], check=True)
        subprocess.run([f"{TEMP_DIR}/{name}"], check=True)

    remove_temp_directory()


def build_conda_package(args: Any) -> None:
    """Builds the conda package for the project."""
    # Build the conda package for the project.
    config = load_project_config()
    channels: list[str]
    rattler_command: list[str]
    match args.mode:
        case "default":
            channels = config["project"]["channels"]
            rattler_command = ["magic", "run", "rattler-build", "build"]
        case _:
            channels = config["feature"][args.mode]["channels"]
            rattler_command = ["magic", "run", "-e", args.mode, "rattler-build", "build"]

    options: list[str] = []
    for channel in channels:
        options.extend(["-c", channel])

    generate_recipe(args)
    subprocess.run(
        [*rattler_command, "-r", RECIPE_DIR, "--skip-existing=all", *options],
        check=True,
    )
    os.remove(f"{RECIPE_DIR}/recipe.yaml")


def main():
    # Configure the parser to receive the mode argument.
    # create the top-level parser
    parser = argparse.ArgumentParser(
        prog="util", description="Generate a recipe for the project."
    )
    subcommands = parser.add_subparsers(help="sub-command help")

    # create the parser for the "templater" command
    templater = subcommands.add_parser("templater", help="template help")
    templater.add_argument(
        "-m",
        "--mode",
        type=str,
        default="default",
        help="The environment to generate the recipe for. Defaults to 'default' for the standard version.",
    )
    templater.set_defaults(func=generate_recipe)

    # create the parser for the "build" command
    build = subcommands.add_parser("build", help="build help")
    build.add_argument(
        "-m",
        "--mode",
        type=str,
        default="default",
        help="The environment to build the package using. Defaults to 'default' for the standard version.",
    )
    build.set_defaults(func=build_conda_package)

    # create the parser for the "publish" command
    publish = subcommands.add_parser("publish", help="publish help")
    publish.add_argument(
        "-c",
        "--channel",
        type=str,
        default="mojo-community",
        help="The prefix.dev conda channel to publish to. Defaults to 'mojo-community'.",
    )
    publish.set_defaults(func=publish_to_prefix)

    # create the parser for the "run" command
    run = subcommands.add_parser("run", help="run help")
    run_subcommands = run.add_subparsers(help="run sub-command help")

    # create the parser for the "run tests" command
    run_tests = run_subcommands.add_parser("tests", help="tests help")
    run_tests.add_argument(
        "-p",
        "--path",
        type=str,
        default=None,
        help="Optional path to test file or test directory to run tests for.",
    )
    run_tests.set_defaults(func=execute_package_tests)

    # create the parser for the "run benchmarks" command
    run_benchmarks = run_subcommands.add_parser("benchmarks", help="benchmarks help")
    run_benchmarks.add_argument(
        "-p",
        "--path",
        type=str,
        default=None,
        help="Optional path to benchmark file or test directory to run tests for.",
    )
    run_benchmarks.set_defaults(func=execute_package_benchmarks)

    # create the parser for the "run examples" command
    run_examples = run_subcommands.add_parser("examples", help="examples help")
    run_examples.add_argument(
        "-p",
        "--path",
        type=str,
        default=None,
        help="Optional path to example file or test directory to run tests for.",
    )
    run_examples.set_defaults(func=execute_package_examples)

    args = parser.parse_args()
    if args.func:
        args.func(args)


if __name__ == "__main__":
    main()
