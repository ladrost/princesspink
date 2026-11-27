---
name: Bug report
about: Report a bug, unexpected behavior, or simulation defect in PrincessPink
title: '[Bug]: '
labels: bug
assignees: ''
---

<!--
Thank you for reporting a bug in PrincessPink!
- SECURITY VULNERABILITIES: Do NOT open a public issue. Report privately via GitHub Security Advisories:
  https://github.com/ladrost/princesspink/security/advisories/new (see SECURITY.md).
- Before submitting, please search existing issues to avoid duplicates.
- Redact any secrets, tokens, credentials, DSNs, or PII before pasting logs or stack traces.
- All submissions must follow CODE_OF_CONDUCT.md and our zero-violence, zero-nudity Content & Safety Policy.
-->

## Pre-Submission Checklist

- [ ] I have searched existing [issues](https://github.com/ladrost/princesspink/issues) and confirmed this bug has not already been reported.
- [ ] I have confirmed this is **not** a security vulnerability (report security issues privately via [GitHub Security Advisories](https://github.com/ladrost/princesspink/security/advisories/new) per [SECURITY.md](https://github.com/ladrost/princesspink/blob/main/SECURITY.md)).
- [ ] I have redacted all secrets, credentials, JWTs, DSNs, and PII from any logs, configs, or stack traces included below.
- [ ] This report adheres to the [Code of Conduct](https://github.com/ladrost/princesspink/blob/main/CODE_OF_CONDUCT.md) and PrincessPink's zero-violence, zero-nudity Content & Safety Policy.

## Bug Description

<!-- Provide a clear and concise description of what the bug is. -->

## Expected Behavior

<!-- Describe what you expected to happen (reference docs/Concept.md or an ADR if relevant). -->

## Actual Behavior

<!-- Describe what actually happened instead. -->

## Steps to Reproduce

<!-- Provide minimal, numbered steps to reproduce the issue (e.g., exact commands, API/RPC inputs, or failing test command such as `make test-race SERVICE=<name>`). -->

1.
2.
3.

## Affected Component & Version

<!-- Specify the affected library/service/doc and version or Git commit SHA. -->

- **Module / Service:** <!-- e.g., `libs/config`, `services/user-admin`, `services/sim-dna`, `Makefile`, `docs/` -->
- **Service `VERSION` or Git Commit SHA / Tag:** <!-- e.g., `0.1.0`, `user-admin/v0.1.0`, or output of `git rev-parse --short HEAD` -->

## Environment

- **Go Version:** <!-- output of `go version` (baseline: Go 1.27+) -->
- **OS & Architecture:** <!-- e.g., `linux/amd64`, `darwin/arm64`, Windows WSL2 -->
- **PostgreSQL Version (if applicable):** <!-- baseline: PostgreSQL 18+ -->
- **Docker / Kubernetes / Other Runtime (if applicable):** <!-- e.g., Docker 27.x, AKS / kind -->

## Simulation Determinism Context (if applicable)

<!-- Fill this out if the bug occurs in a `sim-*` microservice or `make test-sim`. Leave blank otherwise. -->

- **Seed / Identifiers (`group_id`, `sim_tick`, `event_id`):**
- **Relevant `GROUP.simulation_config` overrides:**
- **Producing `service_version`:**

## Logs, Stack Traces, or Failing Test Output

<!-- Paste relevant logs or test output below. Ensure no secrets or PII are included. -->

```text

```

## Additional Context

<!-- Add any other context, links to related issues/ADRs, or proposed fix ideas here. -->
