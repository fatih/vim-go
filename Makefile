all: test

test:
	@echo "==> Running tests"
	@./scripts/test vim-8.0

.PHONY: all test
