SHELL := bash
.SHELLFLAGS := -eux -o pipefail -c
.DEFAULT_GOAL := build
.DELETE_ON_ERROR:  # If a recipe to build a file exits with an error, delete the file.
.SUFFIXES:  # Remove the default suffixes which are for compiling C projects.
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

export COLUMNS ?= 70
seperator ?= $(shell printf %${COLUMNS}s | tr " " "═")

platform := $(shell python -c 'import sys; print(sys.platform)')

export PIP_DISABLE_PIP_VERSION_CHECK=1
pip-install := ve/bin/pip --no-input install --constraint constraints.txt
pip-check := ve/bin/pip show -q

source_code := src

isort := ve/bin/isort --multi-line=VERTICAL_HANGING_INDENT --trailing-comma --no-sections 

########################################################################################
# Build targets
#
# It is acceptable for other targets to implicitly depend on these targets having been
# run.  I.e., it is ok if "make lint" generates an error before "make" has been run.

.PHONY: build
build: ve development-utilities

ve:
	python3.9 -m venv ve

ve/bin/%:
	# Install development utility "$*"
	$(pip-install) $*

# Utilities we use during development.
.PHONY: development-utilities
development-utilities: ve/bin/black
development-utilities: ve/bin/flake8
development-utilities: ve/bin/isort
development-utilities: ve/bin/mypy
development-utilities: ve/bin/pydocstyle
development-utilities: ve/bin/pyinstaller
development-utilities: ve/bin/pylint
development-utilities: ve/bin/tox
development-utilities: ve/bin/wheel

########################################################################################
# Test and lint targets

.PHONY: pylint
pylint:
	ve/bin/pylint $(source_code) --output-format=colorized

.PHONY: flake8
flake8:
	ve/bin/flake8 $(source_code)

.PHONY: pydocstyle
pydocstyle:
	ve/bin/pydocstyle $(source_code)

.PHONY: mypy
mypy:
	ve/bin/mypy $(source_code) --strict

.PHONY: black-check
black-check:
	ve/bin/black -S $(source_code) --check

.PHONY: isort-check
isort-check:
	$(isort) $(source_code) --diff --check

.PHONY: lint
lint: mypy pylint black-check flake8 isort-check

.PHONY: test
test:
	ve/bin/python setup.py test

.PHONY: tox
tox:
	ve/bin/tox

.PHONY: check
check: tox

########################################################################################
# Sorce code formatting targets

.PHONY: black
black:
	ve/bin/black -S $(source_code)

.PHONY: isort
isort:
	$(isort) $(source_code)

########################################################################################
# Cleanup targets

.PHONY: clean-%
clean-%:
	rm -rf $*

.PHONY: clean-pycache
clean-pycache:
	find . -name __pycache__ -delete

.PHONY: clean
clean: clean-ve clean-pycache clean-dist
