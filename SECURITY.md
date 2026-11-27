# Security Policy

Security and privacy are foundational to **PrincessPink**. Our architecture incorporates defense-in-depth controls across authentication, authorization, data storage, container hardening, and automated vulnerability scanning (see [`docs/Concept.md`](docs/Concept.md#42-user-administration--security-service) and [`ADR-0010`](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)).

If you discover a security vulnerability in PrincessPink, **please report it privately** so we can investigate, remediate, and coordinate disclosure responsibly.

---

## Reporting a Vulnerability (Private Disclosure Only)

> **Important:** **Do NOT open a public GitHub issue, pull request, or public discussion** for suspected security vulnerabilities, exploit Proof-of-Concepts (PoCs), or leaked credentials. Public disclosure puts users and operators at risk before a fix is available.

### Primary Reporting Channel: GitHub Private Vulnerability Reporting

Please submit vulnerability reports privately through **GitHub Security Advisories**:

1. Navigate to the repository's **Security** tab on GitHub:
   `https://github.com/ladrost/princesspink/security/advisories/new`
2. Click **"Report a vulnerability"** to open a private advisory form visible only to the project maintainers and you.
3. Provide the details listed in [What to Include in Your Report](#what-to-include-in-your-report).

Using GitHub Security Advisories allows maintainers to collaborate with you privately, test fixes in a private temporary fork, request a CVE identifier when appropriate, and publish a coordinated advisory once patched.

If GitHub Private Vulnerability Reporting is temporarily unavailable, please contact the repository maintainer (`@ladrost`) privately without posting technical vulnerability details in any public issue, comment, or commit.

---

## What to Include in Your Report

To help us triage and reproduce the issue quickly, please include as much of the following as possible:

- **Affected Component(s):** Specific microservice (`services/<service-name>`), shared library (`libs/<module>`), Protobuf/API contract, container definition, Kubernetes/Helm manifest, CI/CD workflow (`.github/workflows/`), or architectural specification.
- **Affected Version(s):** Service `VERSION` or scoped Git tag (`<service>/v<MAJOR.MINOR.PATCH>`), commit SHA, Go toolchain version (`go.work`), and runtime environment (OS/architecture, PostgreSQL version, Docker/Kubernetes setup).
- **Vulnerability Class & Summary:** A clear description of the issue (e.g., authentication or MFA bypass, RBAC/IDOR cross-group data exposure, SQL injection, SQLite artifact path traversal, JWT/refresh-token handling flaw, XSS/CSRF/WebSocket hijacking, resource exhaustion/DoS, PII/secret leakage, dependency CVE, or content-policy filter bypass).
- **Reproduction Steps / PoC:** Step-by-step instructions, a minimal request/payload sequence, or a failing Go test case using **synthetic, non-production data only**.
- **Impact Assessment:** What an attacker can achieve (confidentiality, integrity, availability) and what privileges or preconditions are required (unauthenticated, `PLAYER`, `GAME_MASTER`, cluster-internal).
- **Suggested Remediation (Optional):** Any proposed fix, mitigation, or patch ideas you wish to share.

---

## Supported Versions

PrincessPink is currently in **Phase 0 (Architectural Foundation)**—no production microservice releases have been published yet. Security reports concerning architectural specifications, shared platform designs, build tooling, CI/CD workflows, and upcoming Phase 1+ libraries and services are welcome and actively reviewed.

Once microservices begin releasing under PrincessPink's **independent per-service Semantic Versioning** model (`services/<service-name>/VERSION` and scoped tags `<service-name>/v<MAJOR.MINOR.PATCH>`; see [`docs/Concept.md`](docs/Concept.md#35-independent-microservice-versioning) and [`ADR-0009`](docs/architecture/ADR-0009-github-actions-ci-cd.md)), security support follows this policy:

| Component / Branch | Support Status | Notes |
| :--- | :--- | :--- |
| **`main` branch** | Supported | Active development and security fixes. |
| **Latest release per microservice (`<service>/vX.Y.Z`)** | Supported | Security fixes are published as independent patch or minor releases for each affected service. |
| **Older microservice releases** | Not supported | Users and operators are expected to upgrade to the latest release of the affected service. |
| **Go Toolchain (`go.work`)** | **Go 1.27+** (`toolchain go1.27.4`) | Aligned with the upstream [Go Security Policy](https://go.dev/security/policy) (two most recent Go major releases). |
| **PostgreSQL Baseline ([ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md))** | **PostgreSQL 18+** | Supported through upstream PostgreSQL 18 security runway. |

---

## Response & Coordinated Vulnerability Disclosure (CVD) Process

We are committed to handling every report transparently, promptly, and respectfully:

1. **Acknowledgment:** We aim to acknowledge receipt of your report within **3 business days** via the private GitHub Security Advisory thread.
2. **Triage & Assessment:** Within **7 days**, maintainers will evaluate reproducibility, determine affected components, and assess severity (using CVSS alongside PrincessPink's domain threat model, such as cross-player or cross-group authorization boundaries).
3. **Ongoing Updates:** While investigating and developing a fix, we will share status updates at least every **14 days**.
4. **Remediation & Verification:** Fixes are developed and reviewed in a private advisory fork, accompanied by regression tests and full quality/security verification (`make check`, `govulncheck`, Trivy container scans, and `buf` checks as applicable).
5. **Release & Public Advisory:** Once patched and released (as updated independent service version(s) `<service>/v<VERSION>`), we will publish the GitHub Security Advisory, request a CVE when warranted, and—with your permission—credit you for the discovery.
6. **Disclosure Window:** We follow a standard **90-day coordinated disclosure window** from initial report receipt. If remediation requires additional time (for example, coordinated upgrades across upstream dependencies), we will discuss an adjusted timeline with you openly.

---

## Scope & Safe Harbor

### In Scope

Security reports covering any of the following areas in the PrincessPink repository are in scope:

- **Authentication, Sessions & MFA (`user-admin`, [ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)):** `Argon2id` password hashing weaknesses, timing/account-enumeration leaks, Ed25519 JWT validation or key-rotation flaws, refresh-token rotation or reuse-detection bypasses, TOTP/WebAuthn MFA bypasses, and session fixation/hijacking.
- **Authorization & RBAC Boundaries:** Privilege escalation between `PLAYER` and `GAME_MASTER` roles, unauthorized access to internal `SYSTEM_SEED` bootstrap endpoints, cross-group data leaks, unauthorized access to another Player's characters or private Direct Messages, unauthorized GM activation of Player-owned characters as NPCs, bypasses of `REPLAY_IMMUTABLE` attribute-history immutability locks, race conditions or unauthorized hijacking in `NPC_OWNERSHIP_CLAIM` (e.g., claiming a character with a `PENDING` parental agreement or while already owning an era-alive PC), bypasses of single-character-per-group, point-in-time era-liveness, character-generation quota, or child `origin_group_id` constraints, and tampering with immutable audit logs or `CHARACTER_ATTRIBUTE_HISTORY`.
- **Frontend Edge & Real-Time Chat (`frontend-*`, `chat-*`, [ADR-0002](docs/architecture/ADR-0002-world-chat-microservices-and-server-selection.md)):** Cross-Site Scripting (XSS), Cross-Site Request Forgery (CSRF), insecure cookie attributes, WebSocket (`wss://`) authentication or channel-isolation flaws, rate-limit/anti-hopping bypasses, and bypasses of the zero-violence/zero-nudity content-policy filter.
- **Database, SQLite & Identifier Security ([ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md), [ADR-0007](docs/architecture/ADR-0007-shared-uuid-utilities.md)):** SQL injection (`pgx/v5` or SQLite), path traversal or file injection in per-female Egg-Reserve (`egg_reserve_<uuid>.sqlite`) or per-ejaculation (`ejaculation_<uuid>.sqlite`) artifact handling, nil/malformed UUID acceptance, or misuse of UUIDv7 as a cryptographic secret/token.
- **Privacy, Secrets & Observability ([ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md), [ADR-0004](docs/architecture/ADR-0004-shared-opentelemetry-observability.md), [ADR-0006](docs/architecture/ADR-0006-shared-configuration-library.md)):** Leakage of PII (emails, chat bodies), credentials, DSNs, JWTs, or MFA secrets via `libs/logging`, `libs/config`, error responses, OpenTelemetry spans, or unintended public exposure of internal `/metrics` endpoints.
- **Resource Exhaustion / Denial of Service:** Unbounded concurrency or memory amplification in `Argon2id` verification, `sheet-aggregator` fan-out, WebSocket handling, batch parentless character generation, or SQLite gamete cohort generation.
- **Supply Chain, Containers & CI/CD ([ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)):** Reachable vulnerabilities in Go dependencies (`govulncheck`), container privilege escalation or image hardening regressions (`distroless/static`), and GitHub Actions workflow permission or OIDC misconfigurations.

### Out of Scope

- Non-security bugs, biological simulation inaccuracies, or RPG balance issues (please open a regular public [GitHub Issue](https://github.com/ladrost/princesspink/issues)).
- Automated vulnerability scanner reports without demonstrated reachability or exploitability in PrincessPink (for example, unreachable transitive Go symbols excluded by `govulncheck`).
- Theoretical vulnerabilities in upstream third-party projects (Go stdlib, PostgreSQL, NATS, Kubernetes) that do not affect PrincessPink directly—please report upstream bugs to their respective maintainers (while still alerting us privately if a reachable CVE impacts our `go.mod` or container images).
- Any testing against third-party or community-hosted deployments without explicit owner authorization, as well as social engineering, phishing, or physical attacks against maintainers or contributors.

### Safe Harbor

We support good-faith security research. If you make a genuine effort to follow this policy—testing only on your own local environment or fork, avoiding privacy violations, data destruction, or service disruption, and reporting findings privately—the PrincessPink maintainers will work with you collaboratively and will not pursue legal action for your good-faith research.

---

## Security Architecture & Automated Controls

PrincessPink's security posture is documented in [`docs/Concept.md`](docs/Concept.md) and our Architecture Decision Records:

- **Go Single-Language & Pure-Go Static Hardening ([ADR-0011](docs/architecture/ADR-0011-go-as-sole-programming-language.md), [ADR-0008](docs/architecture/ADR-0008-multi-module-makefile-build-automation.md)):** All libraries and microservices are written in Go 1.27+ and built as `CGO_ENABLED=0`, `-trimpath` static binaries running in minimal, non-root `distroless/static` containers with read-only root filesystems and dropped Linux capabilities.
- **Authentication, Cryptography & RBAC ([ADR-0010](docs/architecture/ADR-0010-user-admin-auth-rbac-and-group-management.md)):** `Argon2id` password hashing (`golang.org/x/crypto/argon2` with constant-time verification, dummy hashing on unknown accounts, and concurrency semaphores), short-lived PII-free Ed25519 (`EdDSA`) JWTs, `crypto/rand` (≥ 256-bit) rotating refresh tokens in `HttpOnly`, `Secure`, `SameSite=Strict` cookies with family revocation on reuse, TOTP/WebAuthn MFA, defense-in-depth RBAC, and immutable PostgreSQL 18 `RETURNING OLD, NEW` audit trails.
- **Transport, Secrets & Database Isolation ([ADR-0001](docs/architecture/ADR-0001-minimum-postgresql-version.md), [ADR-0006](docs/architecture/ADR-0006-shared-configuration-library.md)):** TLS 1.3 externally, mTLS internally, default-deny Kubernetes `NetworkPolicy`, Azure Key Vault + Secrets Store CSI Driver with `*_FILE` indirection and `config.Secret` redaction, PostgreSQL 18+ with `SCRAM-SHA-256`/Microsoft Entra ID authentication, `sslmode=verify-full`, per-service schemas, and strictly parameterized `pgx/v5` queries.
- **Identifier & Logging Hygiene ([ADR-0003](docs/architecture/ADR-0003-shared-logging-library.md), [ADR-0007](docs/architecture/ADR-0007-shared-uuid-utilities.md)):** Strict RFC 9562 UUIDv7 validation for entity IDs and canonical SQLite artifact filenames (preventing path traversal), mandatory `libs/logging` `ReplaceAttr` redaction, and non-PII `user_uuid` logging.
- **Automated Security Scanning ([ADR-0009](docs/architecture/ADR-0009-github-actions-ci-cd.md)):**
  - `govulncheck` reachability analysis against the Go Vulnerability Database (`make vuln` and scheduled weekly CI scans).
  - `golangci-lint` v2 (`make lint`), JetBrains Qodana Go static analysis (`make qodana`), Go race detector (`make test-race`), and GitHub CodeQL for Go.
  - Trivy container image vulnerability scanning failing on `HIGH` and `CRITICAL` CVEs (`make docker-scan` and release pipelines).
  - Least-privilege GitHub Actions workflows, SHA-pinned third-party Actions, and keyless Azure OIDC Workload Identity Federation.

### Running Security Checks Locally

Contributors and operators can run our local Go and container vulnerability checks anytime using the root [`Makefile`](Makefile):

```bash
# Install Go security and lint tools (govulncheck, golangci-lint, buf)
make tools

# Scan Go modules for reachable known vulnerabilities (Go Vulnerability Database)
make vuln

# Run the full quality & security gate (fmt-check, vet, lint, test-race, vuln)
make check

# Run JetBrains Qodana static analysis (requires Qodana CLI)
make qodana

# Scan built container images with Trivy (HIGH and CRITICAL)
make docker-scan
```
