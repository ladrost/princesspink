# ADR-0014: Compulsory Go & Open-Source Source Code Documentation Standards

- **Status:** Accepted
- **Date:** 2026-11-28
- **Deciders:** PrincessPink Architecture
- **Related Documents:** [`docs/Concept.md`](../Concept.md), [`README.md`](../../README.md), [`AGENTS.md`](../../AGENTS.md), [`CONTRIBUTING.md`](../../CONTRIBUTING.md), [`LICENSE`](../../LICENSE), [`Makefile`](../../Makefile), [`.golangci.yml`](../../.golangci.yml), [`qodana.yaml`](../../qodana.yaml), [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md), [`ADR-0003`](ADR-0003-shared-logging-library.md), [`ADR-0005`](ADR-0005-shared-grpc-protobuf-contracts.md), [`ADR-0008`](ADR-0008-multi-module-makefile-build-automation.md), [`ADR-0009`](ADR-0009-github-actions-ci-cd.md), [`ADR-0011`](ADR-0011-go-as-sole-programming-language.md)

---

## Context

PrincessPink is an open-source, scientific, population-level simulation built exclusively in **Go 1.27+** ([ADR-0011](ADR-0011-go-as-sole-programming-language.md)) across shared libraries (`libs/`) and **25+ independently versioned microservices** (`services/`). Contributions are authored collaboratively by both **human open-source developers** and **AI coding assistants** governed by [`AGENTS.md`](../../AGENTS.md) and [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

Without compulsory, machine-enforced source code documentation standards, a modular open-source scientific platform quickly degrades in four ways:

1. **Undocumented or Ambiguous Public APIs:** Shared packages (`libs/logging`, `libs/telemetry`, `libs/proto`, `libs/config`, `libs/uuid`) and service domain packages become hard to consume safely when exported types, functions, units, bounds, concurrency contracts, and error semantics are missing from `go doc` / `pkg.go.dev`.
2. **Opaque Scientific & Domain Invariants:** Biological hazard models, Mendelian inheritance logic, PRNG seed derivations, `REPLAY_IMMUTABLE` temporal guards, and RBAC/mTLS security boundaries lose traceability when non-obvious design decisions and scientific rationales are undocumented.
3. **Inconsistent Open-Source & Contract Hygiene:** Missing per-file SPDX license headers complicate downstream BSD-3-Clause compliance; undocumented `.proto` schemas, OpenAPI specs, and SQL migrations force contributors to reverse-engineer contracts from implementation code.
4. **AI-Induced Documentation Drift & Noise:** Unconstrained AI-assisted edits either omit package/exported Go doc comments altogether, silently bypass linters with bare `//nolint` directives, or inject verbose line-by-line narration that restates obvious syntax while drifting out of sync when behavior changes.

Because PrincessPink is establishing its **Phase 0 / Architectural Foundation** prior to committing the first Go modules under `libs/` and `services/`, formalizing and automating compulsory Go and Open-Source source code documentation now ensures 100% compliance from the very first module with zero legacy debt.

---

## Decision

PrincessPink makes **Go and Open-Source source code documentation best practices compulsory** for **all human developers and AI coding agents**, enforced across source conventions, automated static analysis (`.golangci.yml`, `qodana.yaml`, `buf`, `gofmt`), developer workflows (`Makefile`), and pull request review gates (`AGENTS.md`, `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`).

### 1. Compulsory Go Doc Comments Standard (`go.dev/doc/comment`)

Every Go module under `libs/` and `services/` must adhere strictly to official [Go Doc Comments](https://go.dev/doc/comment) (Go 1.19+ `go/doc/comment` syntax):

1. **Package Documentation (`doc.go`):**
   - Every Go package—including shared `libs/*` packages, exported packages, and service `internal/*` packages—must provide **exactly one** canonical package doc comment beginning with `// Package <name> ...` (and `cmd/<service>/main.go` entry points must carry a concise binary overview comment explaining the service's role).
   - Multi-file packages must place the package doc comment in a dedicated **`doc.go`** file so documentation is discoverable and never duplicated across files.
2. **Exported Declarations:**
   - Every exported `type`, `func`, method, `const` (or grouped `const`/`var` block), and `var` must have a complete-sentence Go doc comment placed immediately above the declaration (no blank line between comment and declaration), **starting with the exact exported symbol name** and **ending with a period (`.`)**.
   - Exported struct fields and interface methods carrying non-obvious units (e.g., `_cm`, `_kg`, `_bpm`, `_minutes`), valid ranges, immutability guarantees, concurrency safety, nil/zero-value behavior, or domain error semantics must also be documented.
   - Sentinel errors and custom error types must document when they are returned so callers can handle them with `errors.Is` / `errors.As`.
3. **Canonical Go 1.19+ Doc Comment Formatting:**
   - Use standard `go/doc/comment` markup formatted by `gofmt -s`: `# Headings`, bullet/numbered lists, indented code blocks, symbol doc links (`[TypeName]`, `[pkg.Symbol]`, `[Type.Method]`), and reference URL links (`[Label]: https://...`) with zero unused link definitions.
   - Do **not** embed raw HTML or unsupported Markdown syntax (`**bold**`, triple-backtick code fences) in Go doc comments.
4. **Structured Deprecation Notices:**
   - Mark deprecated exported symbols with a dedicated paragraph starting with `Deprecated: ` that names the replacement using a Go doc link (for example, `Deprecated: Use [NewClient] instead.`).
5. **Runnable, Testable `Example` Functions (`*_test.go`):**
   - Every shared library package under `libs/` (and any reusable exported Go API) must include runnable `Example*` functions in `example_test.go` (or `*_test.go`) with verified `// Output:` (or `// Unordered output:`) comments so `go test` executes and validates documentation examples continuously and `go doc` / `pkg.go.dev` renders live usage.

### 2. Compulsory Open-Source File, Module & Inline Documentation Standards

1. **SPDX License Headers (REUSE / BSD-3-Clause Compliance):**
   - Every authored, non-generated Go source file must start on line 1 with the exact SPDX license identifier matching root [`LICENSE`](../../LICENSE):
     ```go
     // SPDX-License-Identifier: BSD-3-Clause
     ```
   - Separate the SPDX header from any `//go:build` constraint and from the `// Package <name>` doc comment by a blank line so license headers never leak into rendered `go doc` / `pkg.go.dev` output.
2. **Standard Generated-Code Header:**
   - All generated Go files (such as Protobuf bindings under `libs/proto/gen/go/`) must start with Go's standard machine-readable marker matching `^// Code generated .* DO NOT EDIT\.$`, allowing linters (`generated: strict`), Qodana, and code review tools to distinguish generated output from hand-authored code without disabling checks globally.
3. **Per-Module & Per-Service `README.md`:**
   - Every shared library (`libs/<module>/README.md`) and every microservice (`services/<service>/README.md`) must maintain a concise `README.md` documenting:
     - Purpose and bounded responsibility (referencing [`docs/Concept.md`](../Concept.md) and relevant ADRs).
     - Owned PostgreSQL schemas/tables or SQLite reference/gamete artifacts (if any).
     - Exposed gRPC/Protobuf, HTTP/WebSocket, or NATS JetStream interfaces.
     - Operational configuration keys (`libs/config`) and security/RBAC expectations.
     - Local build, test, and doc commands (`make check SERVICE=<name>`, `make doc SERVICE=<name>`).
4. **High-Signal "Why" Comments (Anti-Bloat Policy for Devs & AI):**
   - Inline comments and comments on non-trivial unexported symbols must explain **why**—scientific/biological formulas and reference dataset provenance, PRNG seed derivation `(group_id, sim_tick, event_id)`, locking/concurrency contracts (`SELECT ... FOR UPDATE`, goroutine lifetimes, channel closing ownership), `REPLAY_IMMUTABLE` temporal guards, cryptographic/RBAC invariants, and links to ADRs or `docs/Concept.md`.
   - **No Syntax Narration:** Do not write low-signal comments that merely restate obvious Go code (e.g., `// increment counter`, `// return error`). AI coding agents must avoid comment bloat while still satisfying every Go doc and invariant requirement.
   - **No Commented-Out Code:** Dead or commented-out code blocks must never be committed; Git history preserves deleted code.
5. **Tracked `TODO` / `FIXME` Discipline:**
   - Every `TODO` or `FIXME` comment must cite a tracked GitHub issue using `// TODO(#<issue>): <concise action>` (or `// FIXME(#<issue>): ...`). Untracked, anonymous, or stale TODOs are disallowed, and TODOs must never defer security, privacy, or content-safety enforcement.
6. **Content Safety, Privacy & Non-PII Hygiene:**
   - Every source comment, doc comment, `Example*` output, `.proto` description, SQL comment, and module `README.md` must strictly uphold PrincessPink's **zero-violence, zero-nudity** Content & Safety Policy and must never contain real credentials, tokens, DSNs, or PII.

### 3. Non-Go Source Artifact Documentation (Contracts, Schemas & Automation)

Because PrincessPink's architecture spans declarative contracts, schemas, and build automation alongside Go ([ADR-0011](ADR-0011-go-as-sole-programming-language.md) §3):

- **Protobuf Contracts (`libs/proto`, [ADR-0005](ADR-0005-shared-grpc-protobuf-contracts.md)):** `buf.yaml` enables Buf's **`COMMENTS`** lint category (`COMMENT_SERVICE`, `COMMENT_RPC`, `COMMENT_MESSAGE`, `COMMENT_FIELD`, `COMMENT_ENUM`, `COMMENT_ENUM_VALUE`, `COMMENT_ONEOF`) alongside `STANDARD`. Leading comments on `.proto` declarations automatically flow into generated Go doc comments under `libs/proto/gen/go/`.
- **OpenAPI Specifications (`docs/api/`):** Every external HTTP/WebSocket endpoint, parameter, status code, and schema must provide clear `summary` and `description` documentation.
- **SQL Migrations & Reference Schemas (PostgreSQL 18+ & SQLite):** Every versioned SQL migration starts with a header comment describing intent and idempotency/rollback notes; domain tables and non-obvious columns (especially append-only / `REVOKE UPDATE, DELETE` invariants) should include PostgreSQL `COMMENT ON TABLE` / `COMMENT ON COLUMN`.
- **Makefile, Dockerfiles & IaC/Helm:** Every `Makefile` target must include a `##` description for `make help` ([ADR-0008](ADR-0008-multi-module-makefile-build-automation.md)); Dockerfiles and AKS/Helm/Terraform manifests must comment non-obvious hardening flags, build arguments, and configuration values.

### 4. Automated Machine Enforcement & Zero-Bypass Policy

Documentation rules are enforced automatically on every local check and pull request rather than left to manual memory:

| Enforcement Layer | Configuration / Command | Compulsory Rules Enforced |
| :--- | :--- | :--- |
| **`golangci-lint` v2** | Root [`.golangci.yml`](../../.golangci.yml) via `make lint` / `make check` | `godoclint` (`pkg-doc`, `single-pkg-doc`, `require-pkg-doc`, `start-with-name`, `require-doc`, `deprecated`, `no-unused-link`), `revive` (`exported`, `package-comments`, `comment-spacings`, plus strict disable-directive checks), `staticcheck` (`all`, explicitly retaining `ST1000`, `ST1020`, `ST1021`, `ST1022`), `godot` (`scope: declarations`, `period: true`, `capital: true`), `testableexamples`, `goheader` (`SPDX-License-Identifier: BSD-3-Clause`), `misspell`, `dupword`, and `nolintlint` (`require-explanation: true`, `require-specific: true`). Uses `generated: strict` and deliberately omits the `comments` exclusion preset. |
| **JetBrains Qodana** | Root [`qodana.yaml`](../../qodana.yaml) via `make qodana` / GoLand | Explicitly enables `GoExportedElementShouldHaveComment`, `GoCommentStart`, and `GoCommentLeadingSpace` under `qodana.recommended` with `failThreshold: 0`. |
| **`gofmt -s`** | `make fmt` / `make fmt-check` | Canonically formats Go 1.19+ doc comments (headings, lists, doc links, comment spacing). |
| **`go doc` & `go test`** | `make doc` & `make test-race` | Renders full package docs and executable examples (`go doc -all -ex`) and compiles/executes `Example*` tests against their `// Output:` blocks. |
| **`buf lint`** | `libs/proto/buf.yaml` via `make proto-lint` | Enforces Buf `STANDARD` + `COMMENTS` categories across all gRPC services, RPCs, messages, fields, enums, and NATS event schemas. |

**Zero-Bypass Rule:** Neither human developers nor AI coding agents may add bare `//nolint`, `//revive:disable`, or `//noinspection` directives to silence documentation warnings. Any unavoidable false positive must name the exact linter/rule and include an inline justification explaining why suppression is necessary (`nolintlint` + `revive` directives enforce this automatically).

### 5. Atomic Co-Evolution & Governance for Human Developers and AI Agents

- **Update Docs With Code:** Any PR that changes exported signatures, behavior, error semantics, configuration keys, database invariants, or `.proto` contracts **must** update the corresponding Go doc comments, `doc.go`, `Example*` tests, module `README.md`, and relevant ADR / `docs/Concept.md` sections in the same PR.
- **Equal Accountability (Devs & AI):** [`AGENTS.md`](../../AGENTS.md) makes these rules mandatory for AI coding assistants; [`CONTRIBUTING.md`](../../CONTRIBUTING.md) and [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md) make them mandatory for human contributors and reviewers. Missing, stale, inaccurate, or noisy syntax-narrating comments are blocking code-review findings.

---

## Options Considered

| Option | Description | Evaluation |
| :--- | :--- | :--- |
| **1. Compulsory Multi-Layer Go & Open-Source Documentation Standard (ADR-0014 + `.golangci.yml` + `qodana.yaml` + `buf` `COMMENTS` + `AGENTS.md`/`CONTRIBUTING.md`/PR Template)** | Codify official Go doc comments, SPDX headers, runnable `Example*` tests, module READMEs, high-signal "why" comments, and Protobuf/SQL/OpenAPI docs, backed by automated linter enforcement in `make check` and CI. | **Selected.** Zero drift between policy and code, consistent quality across human and AI contributors, native `go doc` / `pkg.go.dev` readiness, and zero third-party doc toolchain overhead. |
| **2. Advisory Documentation Guidelines Only (Prose in `CONTRIBUTING.md` / `AGENTS.md`)** | Recommend Go doc comments and license headers in Markdown docs without enabling documentation linters in `.golangci.yml`, `qodana.yaml`, or `buf.yaml`. | **Rejected.** Advisory standards inevitably erode under deadline pressure, across 25+ microservices, and across automated AI-assisted PRs; reviewers waste time flagging mechanical issues linters should catch. |
| **3. Separate External Documentation Generator (Docusaurus / MkDocs / Sphinx)** | Maintain API and internal code documentation in an external documentation site built outside Go source files. | **Rejected.** Introduces a non-Go build toolchain (conflicting with [ADR-0011](ADR-0011-go-as-sole-programming-language.md)), duplicates Go's built-in `go doc` / `pkg.go.dev` ecosystem, and quickly falls out of sync with actual Go code and `.proto` files. |
| **4. Mandatory Comment-to-Code Percentage Quotas (e.g., `revive` `comments-density`)** | Require every Go file to contain at least N% comment lines. | **Rejected.** Creates perverse incentives—especially for AI assistants—to pad files with redundant line-by-line comments restating obvious Go syntax, hurting readability without improving real documentation quality. |

---

## Rationale & Alignment with PrincessPink Requirements

1. **Scientific Clarity & Reproducibility (`docs/Concept.md` §1.2 & §7.2):**
   PrincessPink's simulation services (`sim-*`) and attribute calculators (`attr-*`) encode biological and statistical logic. Requiring clear package docs, explicit unit/bound documentation on exported types, and high-signal "why" comments citing reference SQLite tables and PRNG seeds keeps every biological model auditable by both engineers and scientific contributors.
2. **Low-Friction Open-Source Onboarding (`CONTRIBUTING.md`, [ADR-0008](ADR-0008-multi-module-makefile-build-automation.md), [ADR-0011](ADR-0011-go-as-sole-programming-language.md)):**
   Standardized `doc.go`, runnable `Example*` tests, `SPDX-License-Identifier: BSD-3-Clause` headers, per-service `README.md` files, and `make doc` enable newcomers to explore any library or microservice immediately via `go doc` or `pkg.go.dev` without reverse-engineering source code.
3. **Human + AI Collaboration Reliability (`AGENTS.md`):**
   AI coding agents follow explicit, unambiguous rules paired with deterministic compiler/linter feedback loops. Encoding documentation rules directly in `.golangci.yml`, `qodana.yaml`, `buf.yaml`, `AGENTS.md`, and `.github/PULL_REQUEST_TEMPLATE.md` turns documentation quality into an objective, verifiable gate (`make check`) for both humans and AI.
4. **Zero-Debt Timing (Phase 0 Baseline):**
   Activating full enforcement before Phase 1 modules (`libs/*`, `services/user-admin`) are written avoids painful retroactive cleanups or legacy exclusion lists.

---

## Consequences

### Positive
- Every package, exported Go symbol, Protobuf service/message/field/RPC, and shared-library example is consistently documented, spell-checked, and license-tagged from commit one.
- Executable `Example*` tests under `libs/` keep usage documentation guaranteed to compile and match real behavior on every `make test-race` run.
- `nolintlint` and `revive` directive checks prevent silent bypassing of documentation standards by either human contributors or AI tools.
- Generated files (`libs/proto/gen/go/`) remain cleanly separated via Go's standard `// Code generated ... DO NOT EDIT.` convention while still inheriting rich Go doc comments generated from `.proto` leading comments.

### Trade-offs & Operational Notes
- **Higher Upfront Authoring Discipline:** Contributors and AI agents must write `doc.go`, exported doc comments, SPDX headers, module `README.md` files, and `Example*` tests (for `libs/`) before `make check` passes. This small upfront investment pays back continuously across 25+ microservices.
- **Tooling Parity:** Running `make lint` requires `golangci-lint` v2 (`make tools`), and `make proto-lint` requires `buf` (`make tools`), matching the existing quality gate in [ADR-0008](ADR-0008-multi-module-makefile-build-automation.md) and [ADR-0009](ADR-0009-github-actions-ci-cd.md).
- **Human Review Still Matters for Semantics:** Static analyzers guarantee presence, formatting, SPDX headers, spelling, and runnable examples, but human code reviewers remain responsible for judging whether comments accurately explain domain invariants and avoid low-signal noise.
