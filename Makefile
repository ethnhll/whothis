# whothis - System bootstrap configuration

VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")
UNAME := $(shell uname -s)

# Detect Linux distribution if applicable
ifeq ($(UNAME),Linux)
    DISTRO := $(shell if [ -f /etc/os-release ]; then . /etc/os-release && echo $$ID; else echo "unknown"; fi)
    DISTRO_VERSION := $(shell if [ -f /etc/os-release ]; then . /etc/os-release && echo $$VERSION_ID; else echo "unknown"; fi)
    OS := linux
else ifeq ($(UNAME),Darwin)
    DISTRO := macos
    DISTRO_VERSION := $(shell sw_vers -productVersion)
    OS := macos
else
    $(error Unsupported operating system: $(UNAME))
endif

.PHONY: all version pkg-manager uv playbook

all: version pkg-manager uv playbook

version:
	@echo "=== whothis v$(VERSION) ==="
	@echo "System:       $(UNAME)"
	@echo "OS:           $(OS)"
	@echo "Distribution: $(DISTRO)"
	@echo "Version:      $(DISTRO_VERSION)"

pkg-manager:
ifeq ($(OS),macos)
	@if command -v brew >/dev/null 2>&1; then \
		echo "Homebrew is already installed: $$(brew --version | head -1)"; \
	else \
		echo "Installing Homebrew..." && \
		$(MAKE) _pkg-manager-install; \
	fi
else ifeq ($(OS),linux)
	@echo "pkg-manager 'apt' already installed"
endif

_pkg-manager-install:
ifeq ($(OS),macos)
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else ifeq ($(OS),linux)
ifeq ($(DISTRO),ubuntu)
	@echo "apt is built-in, nothing to install"
	@echo "Updating apt sources..."
	sudo apt update
else
	$(error Unknown linux pkg-manager for distro: $(DISTRO))
endif
endif

uv:
	@if command -v uv >/dev/null 2>&1; then \
		echo "uv is already installed: $$(uv --version)"; \
	else \
		echo "Installing uv..."; \
		$(MAKE) _uv-install; \
	fi

_uv-install:
ifeq ($(OS),macos)
	brew install uv
else ifeq ($(OS),linux)
	curl -LsSf https://astral.sh/uv/install.sh | sh
endif

playbook: uv
	@echo "Running playbook..."
	@uvx --from ansible-core \
		 --with ansible \
		 ansible-playbook \
		 --ask-become-pass \
		 --extra-vars ansible_python_interpreter=python3 \
		 --inventory localhost, \
		 ansible/playbook.yml

_clean:
	# todo: remove .venv/
	# todo: uninstall uv
	# todo: fix confirmation bug where uninstall output still presented even after abort

ifeq ($(OS),macos)
	@if command -v brew >/dev/null 2>&1; then \
		echo "WARNING: This will remove Homebrew!" && \
		read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || (echo "Aborted."; exit 1) && \
		echo "Uninstalling $$(brew --version | head -1)..." && \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"; \
		echo "$$(brew --version | head -1) uninstalled." && \
		echo "If needed, you can reinstall Homebrew with: 'make pkg-manager'"; \
	else \
		echo "Homebrew not installed, nothing to do." &&  \
		echo "To install Homebrew, run: 'make pkg-manager'."; \
	fi
else
	@echo "Detected Linux OS, package manager will not be removed.";
endif

