# whothis - Macbook bootstrap configuration

# Fail fast; stop multi-line recipes on first error.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

.DEFAULT_GOAL := all
.PHONY: all version homebrew uv playbook help

all: version homebrew uv playbook

VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")
UNAME := $(shell uname -s)

# Only macOS is supported.
ifneq ($(UNAME),Darwin)
$(error Unsupported operating system: $(UNAME))
endif
OS_VERSION := macos $(shell sw_vers -productVersion)

# Homebrew paths (absolute; PATH may not be set up yet on a fresh box).
# NOTE: arch -> prefix logic is mirrored in ansible/default.config.yml and
# dotfiles/zsh/.zsh/.zprofile. Keep the three in sync.
ARCH := $(shell uname -m)
ifeq ($(ARCH),arm64)
	BREW_PREFIX := /opt/homebrew
else
	BREW_PREFIX := /usr/local
endif
BREW := $(BREW_PREFIX)/bin/brew
UVX := $(BREW_PREFIX)/bin/uvx

# Pin the Ansible runtime. With no pins, uvx resolves ansible-core against
# whatever Python it happens to find; on a fresh box that was an old 3.9, which
# pulls ansible-core 2.15 (too old for community.general 13 -> warnings/failures)
# and lacks prebuilt wheels for some deps (forcing a Rust source build). Forcing
# a modern managed Python + matching ansible-core avoids both.
ANSIBLE_PY := 3.12
ANSIBLE_CORE := ansible-core>=2.17

help:
	@echo "Targets: all (default), version, homebrew, uv, playbook"

version:
	@echo "=== whothis v$(VERSION) ==="
	@echo "System:    $(UNAME)"
	@echo "OS:        $(OS_VERSION)"

homebrew:
	@if [ -x "$(BREW)" ]; then \
		echo "$$($(BREW) --version | head -1) is already installed."; \
	else \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

uv: homebrew
	@if [ -x "$(UVX)" ]; then \
		echo "uv is already installed."; \
	else \
		echo "Installing uv..."; \
		$(BREW) install uv; \
	fi

playbook: uv
	@echo "Installing Ansible collections (from requirements.yml)..."
	@cd ansible && $(UVX) --python $(ANSIBLE_PY) --from '$(ANSIBLE_CORE)' ansible-galaxy \
		collection install -r requirements.yml
	@echo "Running playbook..."
	@cd ansible && $(UVX) --python $(ANSIBLE_PY) --from '$(ANSIBLE_CORE)' \
		ansible-playbook \
		--ask-become-pass \
		--extra-vars ansible_python_interpreter=python3 \
		main.yml
