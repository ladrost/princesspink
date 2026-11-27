<!--
Thank you for contributing to PrincessPink!
Please review CONTRIBUTING.md and AGENTS.md before marking this pull request ready for review:
- https://github.com/ladrost/princesspink/blob/main/CONTRIBUTING.md
- https://github.com/ladrost/princesspink/blob/main/AGENTS.md
Keep PRs focused on a single logical change and do NOT create release Git tags (`<service>/v<VERSION>`) in feature PRs.
-->

## Summary

<!-- Explain what this pull request changes and why. -->

## Related Issues & Documentation

<!-- Link related issues using GitHub closing keywords (e.g., `Closes #42`, `Fixes #42`, `Refs #42`) and any relevant ADRs or docs/Concept.md sections. -->

- Related Issue(s): <!-- e.g., Closes # -->
- Related ADR(s) / Docs: <!-- e.g., ADR-0010, docs/Concept.md §4.2 -->

## Type of Change

<!-- Mark all that apply with `[x]`. -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature, microservice, or scientific simulation model
- [ ] Refactoring or performance improvement (no behavior change)
- [ ] Protobuf / API / database schema change
- [ ] Documentation or Architecture Decision Record (ADR)
- [ ] Build tooling (`Makefile`), CI/CD, or infrastructure / AKS manifest change
- [ ] Breaking change (requires coordination, migration notes, or `v2` contract)

## Affected Modules & Services

<!-- List the modules, services, or areas modified (e.g., `libs/logging`, `services/user-admin`, `Makefile`, `docs/`). -->

- <!-- e.g., `libs/logging`, `services/user-admin`, `docs/` -->

## Testing & Verification

<!-- Describe how you verified these changes, including new or updated tests and exact commands run. -->

- [ ] `make check` (`fmt-check`, `vet`, `lint`, `test-race`, `vuln`) — or scoped `make check SERVICE=<name>`
- [ ] `make test-sim` (deterministic fixed-seed `//go:build simulation` tests, if applicable)
- [ ] `make test-integration` (Testcontainers PostgreSQL 18+ / NATS JetStream, if applicable)
- [ ] `make proto-lint`, `make proto-breaking`, and `make proto-gen` (if `.proto` files changed)
- [ ] `make qodana` (JetBrains Qodana Go static analysis, if available)
- [ ] `make docker-build` and `make docker-scan` (if Dockerfiles or service builds changed)
- [ ] N/A — documentation-only or non-code change

**Verification Notes:**

<!-- Summarize test scenarios covered, edge cases verified, or benchmark results if applicable. -->

## Review & Compliance Checklist

<!-- Confirm all applicable items before requesting review. -->

- [ ] **Content & Safety Policy:** All changes strictly uphold PrincessPink's **zero-violence, zero-nudity** policy (no combat, gore, explicit content, or unmoderated image uploads) and the [Code of Conduct](https://github.com/ladrost/princesspink/blob/main/CODE_OF_CONDUCT.md).
- [ ] **Go & Shared Libraries:** Code follows idiomatic Go 1.27+ (`CGO_ENABLED=0`) standards and uses mandatory `libs/` packages (`logging`, `telemetry`, `proto`, `config`, `uuid`) where applicable—no PII/secrets in logs, no unbounded IDs as Prometheus labels, and no hardcoded biological magic constants.
- [ ] **Domain, Security & Cloud Invariants:** Changes respect immutable character identity/life history (`REPLAY_IMMUTABLE`), deterministic seeded PRNGs, parameterized SQL (`pgx/v5`), defense-in-depth RBAC/group ownership checks, validated canonical UUIDv7 SQLite paths, and private per-namespace subnet isolation with end-to-end TLS 1.3 / mTLS in cloud environments ([ADR-0012](https://github.com/ladrost/princesspink/blob/main/docs/architecture/ADR-0012-private-subnet-isolation-and-encrypted-cloud-communication.md)).
- [ ] **Contracts & Workspace Hygiene:** Regenerated files under `libs/proto/gen/go/` are committed (if `.proto` changed), `go.work` is synchronized (`make work-use && make work-sync`) if modules were added, and no release tags (`<service>/v<VERSION>`) were created.
- [ ] **Test & Linter Integrity:** Proportional unit, edge-case, simulation, or integration tests are added/updated; no failing tests are skipped or weakened; no unjustified `//nolint` or `//noinspection` directives were introduced.
- [ ] **Documentation & Clean Tree:** `docs/Concept.md`, relevant ADRs under `docs/architecture/`, or `README.md` are updated if architecture, contracts, or workflows changed; no secrets, `.env` files, `bin/`, or `.coverage/` artifacts are committed.
- [ ] **AI-Assisted Contributions (if applicable):** If AI coding tools were used, every line of generated code, tests, and documentation was personally reviewed and verified against [`AGENTS.md`](https://github.com/ladrost/princesspink/blob/main/AGENTS.md) and the project's ADRs.

## Additional Notes for Reviewers

<!-- Optional: highlight design trade-offs, migration/deployment steps, or areas where you would like specific reviewer feedback. -->
