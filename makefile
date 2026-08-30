.DEFAULT_GOAL := setup
.PHONY: setup

setup:
	@echo "==> Configuring git hooks..."
	git config core.hooksPath .githooks
