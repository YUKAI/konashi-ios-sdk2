# Variables

.DEFAULT_GOAL := help

# Targets

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":[^#]*? #| #"}; {printf "%-42s%s\n", $$1 $$3, $$2}'

.PHONY: bootstrap
bootstrap: # Setup tools
	mint bootstrap

.PHONY: format
format: # Format code
	mint run swiftformat ./Sources/

.PHONY: lint
lint: # Lint code
	mint run swiftlint autocorrect
