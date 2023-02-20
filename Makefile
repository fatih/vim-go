VIMS ?= vim-8.0 vim-8.2 nvim
TEST_FLAGS ?=

all: install lint test

install:
	@echo "==> Installing Vims: $(VIMS)"
	@for vim in $(VIMS); do \
		./scripts/install-vim $$vim; \
		./scripts/install-tools $$vim; \
	done

test:
	@echo "==> Running tests for $(VIMS)"
	@for vim in $(VIMS); do \
		./scripts/test $(TEST_FLAGS) $$vim; \
	done

lint:
	@echo "==> Running linting tools"
	@./scripts/lint vim-8.2

docker:
	@echo "==> Building/starting Docker container"
	@./scripts/docker-test

clean:
	@echo "==> Cleaning /tmp/vim-go-test"
	@rm -rf /tmp/vim-go-test

.PHONY: runtime/indent/go.vim
runtime/indent/go.vim:
	@git checkout master -- indent/go.vim
	@git reset HEAD --  indent/go.vim

.PHONY: runtime/syntax/go.vim
runtime/syntax/go.vim:
	@git checkout master -- syntax/go.vim
	@git reset HEAD -- syntax/go.vim

vim-runtime: runtime/indent/go.vim runtime/syntax/go.vim
	@echo "==> fetching from vim/vim"
	@echo "==> choose the hunks to apply with git add -pu"

.PHONY: all test install clean lint docker vim-runtime
