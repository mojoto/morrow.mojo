MOJO ?= uv run mojo
MOJO_BIN ?= $(CURDIR)/.venv/bin/mojo
MOJO_TEST_FLAGS ?= -I .
MOJO_PYTHON ?= 3.14
MOJO_VERSION ?= 1.1.0
RATTLER_BUILD ?= rattler-build
PACKAGE := morrow.mojoc
TEST_FILES := $(sort $(wildcard tests/test_*.mojo))
DOCS_DIR := website

.PHONY: help install test test-package benchmark format build package clean doc-install doc-serve doc-build doc-clean

help:
	@printf "Targets:\n"
	@printf "  install  Install Mojo into .venv with uv\n"
	@printf "  test     Run all Mojo unit tests\n"
	@printf "  test-package  Build and test the precompiled package in isolation\n"
	@printf "  benchmark  Run repeatable performance samples\n"
	@printf "  format   Format Mojo sources and tests\n"
	@printf "  build    Build $(PACKAGE)\n"
	@printf "  package  Build the distributable Conda package\n"
	@printf "  clean    Remove generated build artifacts\n"
	@printf "  doc-install  Install Docusaurus dependencies\n"
	@printf "  doc-serve    Serve the built Docusaurus site\n"
	@printf "  doc-build    Build the Docusaurus static site\n"
	@printf "  doc-clean    Remove Docusaurus generated artifacts\n"

install:
	@if ! command -v uv >/dev/null 2>&1; then \
		printf "uv is required to install Mojo. See https://docs.astral.sh/uv/getting-started/installation/\n"; \
		exit 1; \
	fi
	uv venv --python $(MOJO_PYTHON) --allow-existing
	uv pip install "mojo==$(MOJO_VERSION)"
	$(MOJO) --version

test:
	@test -n "$(TEST_FILES)" || { printf "No test files found.\n"; exit 1; }
	@set -e; \
	for test_file in $(TEST_FILES); do \
		printf "\n==> %s\n" "$$test_file"; \
		$(MOJO) run $(MOJO_TEST_FLAGS) "$$test_file"; \
	done

test-package: build
	python3 tools/check_package.py $(PACKAGE) --mojo "$(MOJO_BIN)"

benchmark:
	$(MOJO) run -I . tools/benchmark.mojo

format:
	$(MOJO) format morrow tests

build:
	$(MOJO) precompile morrow -o $(PACKAGE)

package:
	$(RATTLER_BUILD) build \
		--recipe conda.recipe/recipe.yaml \
		-c conda-forge \
		-c https://repo.prefix.dev/max

clean:
	rm -f $(PACKAGE)

doc-install:
	npm --prefix $(DOCS_DIR) install

doc-serve:
	npm --prefix $(DOCS_DIR) run serve

doc-build:
	npm --prefix $(DOCS_DIR) run build

doc-clean:
	npm --prefix $(DOCS_DIR) run clear
	rm -rf $(DOCS_DIR)/build
