MOJO ?= $(if $(wildcard .venv/bin/mojo),.venv/bin/mojo,mojo)
MOJO_TEST_FLAGS ?= -I .
MOJO_PYTHON ?= 3.14
PACKAGE := morrow.mojopkg
TEST_FILES := $(sort $(wildcard tests/test_*.mojo))
DOCS_DIR := website

.PHONY: help install test format build clean docs-install docs-start docs-build docs-clean

help:
	@printf "Targets:\n"
	@printf "  install  Install Mojo into .venv with uv\n"
	@printf "  test     Run all Mojo unit tests\n"
	@printf "  format   Format Mojo sources and tests\n"
	@printf "  build    Build $(PACKAGE)\n"
	@printf "  clean    Remove generated build artifacts\n"
	@printf "  docs-install  Install Docusaurus dependencies\n"
	@printf "  docs-start    Start the Docusaurus dev server\n"
	@printf "  docs-build    Build the Docusaurus static site\n"
	@printf "  docs-clean    Remove Docusaurus generated artifacts\n"

install:
	@if ! command -v uv >/dev/null 2>&1; then \
		printf "uv is required to install Mojo. See https://docs.astral.sh/uv/getting-started/installation/\n"; \
		exit 1; \
	fi
	uv venv --python $(MOJO_PYTHON) --allow-existing
	uv pip install --prerelease allow mojo
	.venv/bin/mojo --version

test:
	@test -n "$(TEST_FILES)" || { printf "No test files found.\n"; exit 1; }
	@set -e; \
	for test_file in $(TEST_FILES); do \
		printf "\n==> %s\n" "$$test_file"; \
		$(MOJO) run $(MOJO_TEST_FLAGS) "$$test_file"; \
	done

format:
	$(MOJO) format morrow tests

build:
	$(MOJO) package morrow -o $(PACKAGE)

clean:
	rm -f $(PACKAGE)

docs-install:
	npm --prefix $(DOCS_DIR) install

docs-start:
	npm --prefix $(DOCS_DIR) run start

docs-build:
	npm --prefix $(DOCS_DIR) run build

docs-clean:
	npm --prefix $(DOCS_DIR) run clear
	rm -rf $(DOCS_DIR)/build
