---
name: Feature request
about: Propose a new feature, scientific simulation model, tabletop mechanic, or enhancement
title: '[Feature]: '
labels: enhancement
assignees: ''
---

<!--
Thank you for proposing an enhancement to PrincessPink!
Before submitting, please review:
- docs/Concept.md: https://github.com/ladrost/princesspink/blob/main/docs/Concept.md
- Architecture Decision Records (ADRs): https://github.com/ladrost/princesspink/tree/main/docs/architecture
- CONTRIBUTING.md: https://github.com/ladrost/princesspink/blob/main/CONTRIBUTING.md
All proposals must uphold PrincessPink's non-negotiable zero-violence, zero-nudity Content & Safety Policy.
-->

## Pre-Submission Checklist

- [ ] I have searched existing [issues](https://github.com/ladrost/princesspink/issues), [pull requests](https://github.com/ladrost/princesspink/pulls), and [`docs/Concept.md`](https://github.com/ladrost/princesspink/blob/main/docs/Concept.md) to avoid duplicates.
- [ ] This proposal strictly complies with PrincessPink's **zero-violence, zero-nudity** Content & Safety Policy (no combat, gore, explicit content, or unmoderated image uploads).
- [ ] This proposal aligns with the [Code of Conduct](https://github.com/ladrost/princesspink/blob/main/CODE_OF_CONDUCT.md) and the Go-only language baseline ([ADR-0011](https://github.com/ladrost/princesspink/blob/main/docs/architecture/ADR-0011-go-as-sole-programming-language.md))—or explicitly justifies an ADR discussion.

## Problem Statement & Motivation

<!-- Describe the problem, simulation gap, or RPG/platform need this feature addresses, and why it matters. -->

## Proposed Solution

<!-- Clearly describe what you want to happen, including expected user, Game Master, or developer experience. -->

## Roadmap & Architecture Alignment

- **Target Roadmap Phase:** <!-- e.g., Phase 0 (Foundation), Phase 1 (Platform), Phase 2 (Sheet/Chat MVP), Phase 3 (Core Simulation), Phase 4 (Full Lifecycle & Gamification), Phase 5 (AKS Hardening) -->
- **Affected Modules / Services:** <!-- e.g., `libs/proto`, `services/sim-roleplay`, `services/gamification-service`, `docs/` -->
- **Requires an Architecture Decision Record (ADR)?** <!-- Yes / No — required for new shared libraries, infrastructure baseline changes, or inter-service pattern changes under `docs/architecture/` -->

## Domain, Scientific Model & Determinism Considerations (if applicable)

<!-- Fill this out when proposing or refining biological/statistical models or tabletop mechanics. -->

- **Scientific / Domain Rationale:** <!-- Summarize biological or tabletop basis and relevant references. -->
- **Invariants & Deterministic Verification:** <!-- What invariants should fixed-seed `//go:build simulation` or unit tests assert? Confirm respect for immutable identity/history (`REPLAY_IMMUTABLE`), RBAC/GM-only boundaries, and non-pay-to-win mechanics. -->
- **Parameter Storage:** <!-- Confirm scientific constants will reside in versioned read-only SQLite reference datasets or versioned `GROUP.simulation_config` JSONB (not hardcoded magic numbers or env vars). -->

## API, Data & Security Impact (if applicable)

<!-- Note any expected impact on:
- gRPC / Protobuf contracts (`libs/proto` — additive `v1` vs. breaking `v2`)
- NATS JetStream events & transactional outbox
- PostgreSQL 18+ schemas/migrations or SQLite artifacts
- RBAC (`PLAYER` / `GAME_MASTER`) or encrypted cloud networking (ADR-0012)
-->

## Alternatives Considered

<!-- Describe any alternative designs or workarounds you considered and why this approach is preferred. -->

## Acceptance Criteria

<!-- List concrete, testable outcomes that define when this feature is complete. -->

- [ ] <!-- Criterion 1 -->
- [ ] <!-- Criterion 2 -->

## Additional Context

<!-- Add links to relevant sections of docs/Concept.md, ADRs, related issues, or diagrams. -->
