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
development-utilities: ve/bin/twine
development-utilities: ve/bin/wheel

########################################################################################
# Distribution targets

.PHONY: assert-one-dist
assert-one-dist:
	@if [ $$(find dist -name 'manuel-*.tar.gz' | wc -l) != 1 ]; then \
	    echo There must be one and only one distribution file present.; \
	    exit 1; \
	fi

.PHONY: assert-no-unreleased-changes
assert-no-unreleased-changes:
	@if grep unreleased CHANGES.rst > /dev/null; then \
	    echo There must not be any unreleased changes in CHANGES.rst.; \
	    exit 1; \
	fi

.PHONY: assert-version-in-changelog
assert-version-in-changelog:
	@if ! grep $$(ve/bin/python setup.py --version) CHANGES.rst; then \
	    echo The current version number must be mentioned in CHANGES.rst.; \
	    exit 1; \
	fi

.PHONY: assert-no-changes
assert-no-changes:
	@if git status --porcelain; then \
	    echo There must not be any ucomitted changes.; \
	    exit 1; \
	fi

.PHONY: dist
dist:
	ve/bin/python setup.py sdist

.PHONY: tox-dist
tox-dist: assert-one-dist
	### check to see if the distribution passes the tests
	rm -rf tmp
	mkdir tmp
	tar xzvf $(dist) -C tmp
	cd tmp/manuel-*; PYTHONPATH= tox
	rm -rf tmp

.PHONY: upload
upload: assert-one-dist
	dist := $(shell find dist -name 'manuel-*.tar.gz')
	ve/bin/twine upload --repository manuel $$(find dist -name 'manuel-*.tar.gz')

.PHONY: release
ifeq '$(shell git rev-parse --abbrev-ref HEAD)' 'master'
release: dist assert-one-dist tox-dist upload
release: assert-no-unreleased-changes assert-version-in-changelog assert-no-changes
	### generate a distribution, tag it, and upload it
	git tag $$(ve/bin/python setup.py --version)
	git push origin --tags
else
release:
	@echo Error: must be on master branch to do a release.; exit 1
endif

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
