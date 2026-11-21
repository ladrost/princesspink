# PrincessPink — Multi-Module Go Microservices Makefile
# Aligned with docs/Concept.md, Go workspace (go.work) layout, and independent per-service versioning.

SHELL        := /usr/bin/env bash
.SHELLFLAGS  := -euo pipefail -c
.DEFAULT_GOAL := help

# ------------------------------------------------------------------------------
# Tooling & Configuration
# ------------------------------------------------------------------------------
GO            ?= go
GOFMT         ?= gofmt
GOLANGCI_LINT ?= golangci-lint
GOVULNCHECK   ?= govulncheck
BUF           ?= buf
DOCKER        ?= docker
TRIVY         ?= trivy

BIN_DIR       ?= bin
COVERAGE_DIR  ?= .coverage

# Build settings (override on CLI, e.g. make build GOOS=linux GOARCH=arm64 CGO_ENABLED=0)
CGO_ENABLED   ?= 0
GOOS          ?= $(shell $(GO) env GOOS 2>/dev/null || uname -s | tr '[:upper:]' '[:lower:]')
GOARCH        ?= $(shell $(GO) env GOARCH 2>/dev/null || echo amd64)
VERSION_PKG   ?= main

# Container / Azure Container Registry (ACR) settings
REGISTRY      ?= princesspink.azurecr.io
PLATFORMS     ?= linux/amd64,linux/arm64

# Git & Build Metadata
GIT_COMMIT    := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
BUILD_DATE    := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# ------------------------------------------------------------------------------
# Workspace & Service Discovery
# ------------------------------------------------------------------------------
PKG_MODULES     := $(sort $(patsubst %/go.mod,%,$(shell find pkg -name go.mod 2>/dev/null)))
SERVICE_MODULES := $(sort $(patsubst %/go.mod,%,$(shell find services -mindepth 2 -maxdepth 2 -name go.mod 2>/dev/null)))
ALL_MODULES     := $(PKG_MODULES) $(SERVICE_MODULES)
SERVICES        := $(patsubst services/%,%,$(SERVICE_MODULES))

# Optional single-service scope: e.g. `make test SERVICE=sim-gamete-surface`
ifdef SERVICE
TARGET_SERVICES := $(SERVICE)
TARGET_MODULES  := services/$(SERVICE)
else
TARGET_SERVICES := $(SERVICES)
TARGET_MODULES  := $(ALL_MODULES)
endif

# ------------------------------------------------------------------------------
# Help
# ------------------------------------------------------------------------------
##@ General

.PHONY: help
help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nPrincessPink Makefile\n\nUsage:\n  make \033[36m<target>\033[0m [SERVICE=<service-name>]\n"} \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
	@printf "\nExamples:\n"
	@printf "  make build                                # Build all microservices\n"
	@printf "  make build SERVICE=sim-gamete-surface     # Build a single microservice\n"
	@printf "  make test-race SERVICE=user-admin         # Run race-enabled tests for one service\n"
	@printf "  make docker-build SERVICE=sim-dna         # Build versioned container image\n"
	@printf "  make tag SERVICE=attr-eye-color           # Create scoped git tag (<service>/v<VERSION>)\n\n"

# ------------------------------------------------------------------------------
# Go Workspace & Dependencies
# ------------------------------------------------------------------------------
##@ Workspace & Dependencies

.PHONY: work-use
work-use: ## Register all pkg/ and services/ modules in go.work
	@if [ -z "$(ALL_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	$(GO) work use $(ALL_MODULES)

.PHONY: work-sync
work-sync: ## Synchronize workspace build list with go.work
	$(GO) work sync

.PHONY: deps
deps: ## Download and verify Go module dependencies
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [deps] $$mod"; \
		(cd "$$mod" && $(GO) mod download && $(GO) mod verify); \
	done

.PHONY: tidy
tidy: ## Run 'go mod tidy' across all modules (or SERVICE=<name>)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [tidy] $$mod"; \
		(cd "$$mod" && $(GO) mod tidy); \
	done

# ------------------------------------------------------------------------------
# Build
# ------------------------------------------------------------------------------
##@ Build

.PHONY: build
build: ## Build all microservices (or SERVICE=<name>) into bin/ with embedded service versions
	@if [ -z "$(TARGET_SERVICES)" ]; then \
		echo "No microservice modules found under services/."; \
		exit 0; \
	fi
	@mkdir -p "$(BIN_DIR)"
	@for svc in $(TARGET_SERVICES); do \
		dir="services/$$svc"; \
		if [ ! -f "$$dir/go.mod" ]; then \
			echo "Error: service '$$svc' not found at $$dir/go.mod" >&2; \
			exit 1; \
		fi; \
		if [ -f "$$dir/VERSION" ]; then \
			ver="$$(tr -d '[:space:]' < "$$dir/VERSION")"; \
		else \
			ver="0.0.0-dev"; \
		fi; \
		if [ -d "$$dir/cmd/$$svc" ]; then \
			entry="./cmd/$$svc"; \
		elif [ -d "$$dir/cmd/server" ]; then \
			entry="./cmd/server"; \
		else \
			entry="."; \
		fi; \
		ldflags="-s -w -X '$(VERSION_PKG).Version=$$ver' -X '$(VERSION_PKG).Commit=$(GIT_COMMIT)' -X '$(VERSION_PKG).BuildDate=$(BUILD_DATE)'"; \
		echo "==> [build] $$svc (v$$ver, $(GOOS)/$(GOARCH), entry=$$entry)"; \
		(cd "$$dir" && CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) $(GO) build -trimpath -ldflags "$$ldflags" -o "$(CURDIR)/$(BIN_DIR)/$$svc" "$$entry"); \
	done

.PHONY: build-linux
build-linux: ## Cross-compile static Linux amd64 binaries for container images
	@$(MAKE) build GOOS=linux GOARCH=amd64 CGO_ENABLED=0

# ------------------------------------------------------------------------------
# Testing
# ------------------------------------------------------------------------------
##@ Testing

.PHONY: test
test: ## Run unit tests across all modules (or SERVICE=<name>)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [test] $$mod"; \
		(cd "$$mod" && $(GO) test ./...); \
	done

.PHONY: test-race
test-race: ## Run tests with race detector enabled (-race -count=1)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [test-race] $$mod"; \
		(cd "$$mod" && $(GO) test -race -count=1 ./...); \
	done

.PHONY: test-cover
test-cover: ## Run tests with coverage profiles and HTML reports in .coverage/
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@mkdir -p "$(COVERAGE_DIR)"
	@for mod in $(TARGET_MODULES); do \
		name="$$(echo "$$mod" | tr '/' '_')"; \
		profile="$(CURDIR)/$(COVERAGE_DIR)/$$name.coverprofile"; \
		html="$(CURDIR)/$(COVERAGE_DIR)/$$name.html"; \
		echo "==> [test-cover] $$mod"; \
		(cd "$$mod" && $(GO) test -race -covermode=atomic -coverprofile="$$profile" ./...); \
		$(GO) tool cover -func="$$profile" | tail -n 1; \
		$(GO) tool cover -html="$$profile" -o "$$html"; \
	done

.PHONY: test-sim
test-sim: ## Run deterministic fixed-seed simulation cohort tests (-tags=simulation)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [test-sim] $$mod"; \
		(cd "$$mod" && $(GO) test -race -count=1 -tags=simulation ./...); \
	done

.PHONY: test-integration
test-integration: ## Run containerized integration tests (-tags=integration)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [test-integration] $$mod"; \
		(cd "$$mod" && $(GO) test -race -count=1 -tags=integration ./...); \
	done

.PHONY: bench
bench: ## Run Go benchmarks across all modules (or SERVICE=<name>)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [bench] $$mod"; \
		(cd "$$mod" && $(GO) test -run='^$$' -bench=. -benchmem ./...); \
	done

# ------------------------------------------------------------------------------
# Code Quality & Security
# ------------------------------------------------------------------------------
##@ Code Quality & Security

.PHONY: fmt
fmt: ## Format all Go source files with gofmt -s -w
	@files="$$(find pkg services -name '*.go' 2>/dev/null || true)"; \
	if [ -z "$$files" ]; then \
		echo "No Go source files found under pkg/ or services/."; \
		exit 0; \
	fi; \
	$(GOFMT) -s -w $$files

.PHONY: fmt-check
fmt-check: ## Verify all Go source files are properly formatted (CI check)
	@files="$$(find pkg services -name '*.go' 2>/dev/null || true)"; \
	if [ -z "$$files" ]; then \
		echo "No Go source files found under pkg/ or services/."; \
		exit 0; \
	fi; \
	unformatted="$$($(GOFMT) -s -l $$files)"; \
	if [ -n "$$unformatted" ]; then \
		echo "The following files are not properly formatted (run 'make fmt'):" >&2; \
		echo "$$unformatted" >&2; \
		exit 1; \
	fi

.PHONY: vet
vet: ## Run 'go vet' across all modules (or SERVICE=<name>)
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [vet] $$mod"; \
		(cd "$$mod" && $(GO) vet ./...); \
	done

.PHONY: lint
lint: ## Run golangci-lint across all modules (or SERVICE=<name>)
	@command -v $(GOLANGCI_LINT) >/dev/null 2>&1 || { echo "Error: $(GOLANGCI_LINT) is not installed (run 'make tools')." >&2; exit 1; }
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [lint] $$mod"; \
		(cd "$$mod" && $(GOLANGCI_LINT) run ./...); \
	done

.PHONY: vuln
vuln: ## Run govulncheck vulnerability scan across all modules
	@command -v $(GOVULNCHECK) >/dev/null 2>&1 || { echo "Error: $(GOVULNCHECK) is not installed (run 'make tools')." >&2; exit 1; }
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [vuln] $$mod"; \
		(cd "$$mod" && $(GOVULNCHECK) ./...); \
	done

.PHONY: check
check: fmt-check vet lint test-race vuln ## Run full CI quality gate (fmt-check, vet, lint, test-race, vuln)

# ------------------------------------------------------------------------------
# Code Generation & API Contracts (gRPC / Protobuf)
# ------------------------------------------------------------------------------
##@ Code Generation & Contracts

.PHONY: generate
generate: ## Run 'go generate ./...' across all modules
	@if [ -z "$(TARGET_MODULES)" ]; then \
		echo "No Go modules found under pkg/ or services/."; \
		exit 0; \
	fi
	@for mod in $(TARGET_MODULES); do \
		echo "==> [generate] $$mod"; \
		(cd "$$mod" && $(GO) generate ./...); \
	done

.PHONY: proto-lint
proto-lint: ## Lint Protobuf API contracts using buf
	@command -v $(BUF) >/dev/null 2>&1 || { echo "Error: $(BUF) is not installed (run 'make tools')." >&2; exit 1; }
	$(BUF) lint

.PHONY: proto-breaking
proto-breaking: ## Check Protobuf contracts for breaking changes against main
	@command -v $(BUF) >/dev/null 2>&1 || { echo "Error: $(BUF) is not installed (run 'make tools')." >&2; exit 1; }
	$(BUF) breaking --against '.git#branch=main'

.PHONY: proto-gen
proto-gen: ## Generate Go gRPC/Protobuf code from contracts using buf
	@command -v $(BUF) >/dev/null 2>&1 || { echo "Error: $(BUF) is not installed (run 'make tools')." >&2; exit 1; }
	$(BUF) generate

# ------------------------------------------------------------------------------
# Independent Microservice Versioning
# ------------------------------------------------------------------------------
##@ Versioning

.PHONY: versions
versions: ## List all discovered microservices and their independent semantic versions
	@if [ -z "$(SERVICES)" ]; then \
		echo "No microservices found under services/."; \
		exit 0; \
	fi
	@printf "%-30s %s\n" "SERVICE" "VERSION"
	@printf "%-30s %s\n" "-------" "-------"
	@for svc in $(SERVICES); do \
		if [ -f "services/$$svc/VERSION" ]; then \
			ver="$$(tr -d '[:space:]' < "services/$$svc/VERSION")"; \
		else \
			ver="0.0.0-dev (missing VERSION file)"; \
		fi; \
		printf "%-30s %s\n" "$$svc" "$$ver"; \
	done

.PHONY: tag
tag: ## Create an annotated scoped Git tag '<SERVICE>/v<VERSION>' (requires SERVICE=<name>)
	@if [ -z "$(SERVICE)" ]; then \
		echo "Error: SERVICE is required (e.g. make tag SERVICE=sim-gamete-surface)" >&2; \
		exit 1; \
	fi
	@ver_file="services/$(SERVICE)/VERSION"; \
	if [ ! -f "$$ver_file" ]; then \
		echo "Error: $$ver_file not found." >&2; \
		exit 1; \
	fi; \
	ver="$$(tr -d '[:space:]' < "$$ver_file")"; \
	tag="$(SERVICE)/v$$ver"; \
	echo "==> Creating Git tag $$tag"; \
	git tag -a "$$tag" -m "Release $(SERVICE) v$$ver"

# ------------------------------------------------------------------------------
# Containers (ACR / AKS) & Local Development
# ------------------------------------------------------------------------------
##@ Containers & Local Development

.PHONY: docker-build
docker-build: ## Build container image(s) tagged with each service's own version (or SERVICE=<name>)
	@if [ -z "$(TARGET_SERVICES)" ]; then \
		echo "No microservices found under services/."; \
		exit 0; \
	fi
	@for svc in $(TARGET_SERVICES); do \
		dir="services/$$svc"; \
		if [ ! -f "$$dir/Dockerfile" ]; then \
			echo "==> [docker-build] skipping $$svc (no $$dir/Dockerfile)"; \
			continue; \
		fi; \
		if [ -f "$$dir/VERSION" ]; then \
			ver="$$(tr -d '[:space:]' < "$$dir/VERSION")"; \
		else \
			ver="0.0.0-dev"; \
		fi; \
		image="$(REGISTRY)/$$svc"; \
		echo "==> [docker-build] $$image:$$ver"; \
		$(DOCKER) build \
			--file "$$dir/Dockerfile" \
			--build-arg SERVICE_NAME="$$svc" \
			--build-arg SERVICE_VERSION="$$ver" \
			--build-arg GIT_COMMIT="$(GIT_COMMIT)" \
			--build-arg BUILD_DATE="$(BUILD_DATE)" \
			--tag "$$image:$$ver" \
			--tag "$$image:latest" \
			.; \
	done

.PHONY: docker-buildx
docker-buildx: ## Build & push multi-arch container image(s) (linux/amd64,linux/arm64) to ACR
	@if [ -z "$(TARGET_SERVICES)" ]; then \
		echo "No microservices found under services/."; \
		exit 0; \
	fi
	@for svc in $(TARGET_SERVICES); do \
		dir="services/$$svc"; \
		if [ ! -f "$$dir/Dockerfile" ]; then \
			echo "==> [docker-buildx] skipping $$svc (no $$dir/Dockerfile)"; \
			continue; \
		fi; \
		if [ -f "$$dir/VERSION" ]; then \
			ver="$$(tr -d '[:space:]' < "$$dir/VERSION")"; \
		else \
			ver="0.0.0-dev"; \
		fi; \
		image="$(REGISTRY)/$$svc"; \
		echo "==> [docker-buildx] $$image:$$ver ($(PLATFORMS))"; \
		$(DOCKER) buildx build \
			--platform "$(PLATFORMS)" \
			--file "$$dir/Dockerfile" \
			--build-arg SERVICE_NAME="$$svc" \
			--build-arg SERVICE_VERSION="$$ver" \
			--build-arg GIT_COMMIT="$(GIT_COMMIT)" \
			--build-arg BUILD_DATE="$(BUILD_DATE)" \
			--tag "$$image:$$ver" \
			--push \
			.; \
	done

.PHONY: docker-push
docker-push: ## Push versioned container image(s) to registry (ACR)
	@if [ -z "$(TARGET_SERVICES)" ]; then \
		echo "No microservices found under services/."; \
		exit 0; \
	fi
	@for svc in $(TARGET_SERVICES); do \
		dir="services/$$svc"; \
		if [ ! -f "$$dir/Dockerfile" ]; then \
			continue; \
		fi; \
		if [ -f "$$dir/VERSION" ]; then \
			ver="$$(tr -d '[:space:]' < "$$dir/VERSION")"; \
		else \
			ver="0.0.0-dev"; \
		fi; \
		image="$(REGISTRY)/$$svc"; \
		echo "==> [docker-push] $$image:$$ver"; \
		$(DOCKER) push "$$image:$$ver"; \
	done

.PHONY: docker-scan
docker-scan: ## Scan built service container image(s) for vulnerabilities using Trivy
	@command -v $(TRIVY) >/dev/null 2>&1 || { echo "Error: $(TRIVY) is not installed." >&2; exit 1; }
	@if [ -z "$(TARGET_SERVICES)" ]; then \
		echo "No microservices found under services/."; \
		exit 0; \
	fi
	@for svc in $(TARGET_SERVICES); do \
		dir="services/$$svc"; \
		if [ ! -f "$$dir/Dockerfile" ]; then \
			continue; \
		fi; \
		if [ -f "$$dir/VERSION" ]; then \
			ver="$$(tr -d '[:space:]' < "$$dir/VERSION")"; \
		else \
			ver="0.0.0-dev"; \
		fi; \
		echo "==> [docker-scan] $(REGISTRY)/$$svc:$$ver"; \
		$(TRIVY) image --exit-code 1 --severity HIGH,CRITICAL "$(REGISTRY)/$$svc:$$ver"; \
	done

.PHONY: dev-up
dev-up: ## Start local development stack (PostgreSQL, NATS, core services) via Docker Compose
	@if [ -f "compose.yaml" ] || [ -f "docker-compose.yml" ]; then \
		$(DOCKER) compose up -d; \
	else \
		echo "No compose.yaml or docker-compose.yml found yet."; \
		exit 1; \
	fi

.PHONY: dev-down
dev-down: ## Stop local development stack via Docker Compose
	@if [ -f "compose.yaml" ] || [ -f "docker-compose.yml" ]; then \
		$(DOCKER) compose down; \
	else \
		echo "No compose.yaml or docker-compose.yml found yet."; \
		exit 1; \
	fi

# ------------------------------------------------------------------------------
# Developer Tooling & Cleanup
# ------------------------------------------------------------------------------
##@ Tooling & Cleanup

.PHONY: tools
tools: ## Install required Go developer tools (golangci-lint, govulncheck, buf)
	$(GO) install golang.org/x/vuln/cmd/govulncheck@latest
	$(GO) install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
	$(GO) install github.com/bufbuild/buf/cmd/buf@latest

.PHONY: clean
clean: ## Remove build binaries and test coverage artifacts
	rm -rf "$(BIN_DIR)" "$(COVERAGE_DIR)"
	find . -maxdepth 3 \( -name 'coverage.out' -o -name 'coverage.html' -o -name '*.coverprofile' \) -delete
