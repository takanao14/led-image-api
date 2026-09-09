BUF ?= buf
GO ?= go
BASE_BRANCH ?= origin/main

.PHONY: help format format-check lint generate generate-check test breaking check

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  format          Format Proto files"
	@echo "  format-check    Check Proto formatting"
	@echo "  lint            Lint Proto files"
	@echo "  generate        Regenerate Go bindings"
	@echo "  generate-check  Verify generated bindings are current"
	@echo "  test            Test Go packages"
	@echo "  breaking        Check compatibility against $(BASE_BRANCH)"
	@echo "  check           Run all non-mutating checks"

format:
	$(BUF) format --write

format-check:
	$(BUF) format --diff --exit-code

lint:
	$(BUF) lint

generate:
	$(BUF) generate

generate-check:
	@tmp_dir=$$(mktemp -d); \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	cp -R gen/go "$$tmp_dir/go"; \
	$(BUF) generate; \
	diff -ru "$$tmp_dir/go" gen/go

test:
	$(GO) test ./...

breaking:
	$(BUF) breaking --against '.git#branch=$(BASE_BRANCH)'

check: format-check lint generate-check test

.DEFAULT_GOAL := help
