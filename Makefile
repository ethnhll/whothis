# whothis - Macbook bootstrap configuration

.PHONY: all version homebrew uv playbook
all: version homebrew uv playbook

VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")
UNAME := $(shell uname -s)

# Homebrew paths (avoid relying on PATH)
ARCH := $(shell uname -m)
ifeq ($(ARCH),arm64)
	BREW_PREFIX := /opt/homebrew
else
	BREW_PREFIX := /usr/local
endif
BREW := $(BREW_PREFIX)/bin/brew
UVX := $(BREW_PREFIX)/bin/uvx

# Detect Linux distribution if applicable
ifeq ($(UNAME),Darwin)
	DISTRO := macos
	OS := macos
	OS_VERSION := $(OS) $(shell sw_vers -productVersion)
else
	$(error Unsupported operating system: $(UNAME))
endif

version:
	@echo "=== whothis v$(VERSION) ==="
	@echo "System:    $(UNAME)"
	@echo "OS:        $(OS_VERSION)"

homebrew:
	@if [ -x "$(BREW)" ]; then \
		echo "$$($(BREW) --version | head -1) is already installed."; \
	else \
		echo "Installing Homebrew..." && \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

uv: homebrew
	@if [ -x "$(UVX)" ]; then \
		echo "uv is already installed."; \
	else \
		echo "Installing uv..." && \
		$(BREW) install uv; \
	fi

playbook: uv
	@echo "Running playbook..."
	@$(UVX) --from ansible-core \
		 --with ansible \
		 ansible-playbook \
		 --ask-become-pass \
		 --extra-vars ansible_python_interpreter=python3 \
		 --inventory inventory, \
		 ansible/main.yml

