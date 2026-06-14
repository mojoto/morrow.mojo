MOJO ?= $(if $(wildcard .venv/bin/mojo),.venv/bin/mojo,mojo)
MOJO_TEST_FLAGS ?= -I .
MOJO_PYTHON ?= 3.14
PACKAGE := morrow.mojopkg
TEST_FILES := $(sort $(wildcard tests/test_*.mojo))

.PHONY: help install test format build clean

help:
	@printf "Targets:\n"
	@printf "  install  Install Mojo into .venv with uv\n"
	@printf "  test     Run all Mojo unit tests\n"
	@printf "  format   Format Mojo sources and tests\n"
	@printf "  build    Build $(PACKAGE)\n"
	@printf "  clean    Remove generated build artifacts\n"

install:
	@if ! command -v uv >/dev/null 2>&1; then \
		printf "uv is required to install Mojo. See https://docs.astral.sh/uv/getting-started/installation/\n"; \
		exit 1; \
	fi
	uv venv --python $(MOJO_PYTHON) --allow-existing
	uv pip install mojo
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
