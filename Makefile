# whothis - Macbook bootstrap configuration

.PHONY: all version homebrew uv playbook
all: version homebrew uv playbook

VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")
UNAME := $(shell uname -s)

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
	@if command -v brew >/dev/null 2>&1; then \
		echo "$$(brew --version | head -1) is already installed."; \
	else \
		echo "Installing Homebrew..." && \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi

uv: homebrew
	@if command -v uv >/dev/null 2>&1; then \
		echo "$$(uv --version) is already installed."; \
	else \
		echo "Installing uv..." && \
		brew install uv; \
	fi

playbook: uv
	@echo "Running playbook..."
	@uvx --from ansible-core \
		 --with ansible \
		 ansible-playbook \
		 --ask-become-pass \
		 --extra-vars ansible_python_interpreter=python3 \
		 --inventory inventory, \
		 ansible/main.yml

