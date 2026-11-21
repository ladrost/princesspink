# PrincessPink

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/Go-1.27+-00ADD8?logo=go&logoColor=white)](go.work)
[![Status](https://img.shields.io/badge/Status-Concept%20%26%20Architecture-informational)](docs/Concept.md)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

**PrincessPink** is an open-source, scientific, population-level simulation of human reproduction and generational lineage presented through a pen-and-paper role-playing game (RPG) interface. Inspired by classic tabletop character sheets (such as AD&D), it gamifies human biology, genetics, and family trees while visualizing each character with a deterministically generated comic-style face portrait.

---

## Table of Contents

- [Content & Safety Policy](#content--safety-policy)
- [Key Features](#key-features)
- [Architecture at a Glance](#architecture-at-a-glance)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Project Status & Roadmap](#project-status--roadmap)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)
- [Security](#security)
- [License](#license)

---

## Content & Safety Policy

PrincessPink enforces a strict, non-negotiable **zero-violence, zero-nudity** policy:

- **No violence or gore:** Unlike combat-oriented RPGs, there are no weapons, battles, injury graphics, or violent mechanics. Characters live and pass away strictly through natural biological lifecycles.
- **No nudity or explicit content:** Human reproduction is modeled purely through abstract scientific data, biological state transitions, and tabletop-style attributes and events—never through explicit text, imagery, or adult themes.
- **Safe-by-design visuals:** Visual representation is strictly limited to stylized **comic-art face portraits** (head and shoulders) derived deterministically from a character's phenotypic traits and age stage, with no free-form image uploads.

---

## Key Features

- **Pen-and-Paper Character Sheets & Dynamic Appearance:** Tabletop-inspired sheets displaying identity, lineage, a comic-style face portrait, and visible appearance traits (`eye_color`, `hair_color`, `skin_color`) anchored in DNA that evolve naturally after birth and across life stages.
- **6 AD&D-Style Reproduction Attributes:** Every character sheet features six numeric tabletop stats (e.g., `3–18` scale with derived modifiers) that directly influence reproduction attempts: **Fertility (`FER`)**, **Constitution (`CON`)**, **Vitality (`VIT`)**, **Hormonal Balance (`HOR`)**, **Receptivity (`REC`)**, and **Compatibility (`COM`)**.
- **Permanent Character Lifecycle:** Every character receives a globally unique, immutable `UUID` at conception and is tracked across its entire existence (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`) with `gender`, `date_of_birth`, `date_of_death`, and parental lineage.
- **Gender-Specific Biological & Gamete Simulation:**
  - *Female characters:* At birth, `sim-egg-reserve` generates the character's lifetime supply of oocytes into a dedicated **per-female Egg-Reserve SQLite database** linked to her `character_uuid`. After menarche (`sim-menarche`), `sim-egg-selection` selects the ovulated egg cell each cycle alongside full `menstruation_dates` tracking.
  - *Male characters:* Models spermatogenesis and builds a dedicated **per-ejaculation SQLite database** (`sim-ejaculation`) of simulated sperm cells, each with its own haploid DNA, motility, morphology, viability, and surface ligand profile.
- **Gamete-Level DNA & Surface-Compatibility Fertilization:** Both egg cells and sperm cells carry individual haploid DNA derived via simulated meiosis (crossover, recombination, independent assortment, and rare mutations). During fertilization, `sim-sperm-race` and `sim-gamete-surface` evaluate both arrival order and molecular receptor–ligand fit—the fastest sperm cell does not automatically win if its surface does not fit. Upon fusion, `sim-dna` combines maternal and paternal haploid DNA into the child's immutable 23-pair diploid genome (`XX` or `XY`).
- **Real-Time RPG Chat:** Built-in WebSocket chat (`frontend-chat` + `chat-service`) supporting World of Warcraft-style **Global Chat**, private **Group Chat** (Game Master and Group members), and **1-to-1 Direct Messages** between Players, with moderation and zero-violence/zero-nudity content filtering.
- **Players, Game Masters & Groups:** Role-based access control where **Players** own and play their characters, while **Game Masters** oversee simulation groups, configure simulation clock speed and parameters, inspect group characters, and moderate Group Chat.
- **Modular Microservices with Independent Versioning:** Each character sheet attribute (`attr-*`) and biological subsystem (`sim-*`) is designed as an independently versioned Go microservice (`VERSION` file, scoped Git tags, and versioned event traceability) for scientific clarity and reproducibility.

---

## Architecture at a Glance

| Layer | Technology / Approach |
| :--- | :--- |
| **Language & Workspace** | Go 1.27+ (`go.work` multi-module workspace, independent semantic versioning per service) |
| **Frontend Microservices** | Go + **Gin** HTTP framework (`frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `portrait-renderer`) with server-rendered HTML/HTMX and authenticated WebSockets (`wss://`) |
| **Internal Communication** | **gRPC / Protocol Buffers** (`pkg/proto`) for synchronous RPC & parallel attribute fan-out; **NATS JetStream** (or Azure Service Bus) for simulation ticks, lifecycle events, and chat pub/sub |
| **User Administration & Security** | `user-admin` backed by **PostgreSQL** with `Argon2id` password hashing, MFA (TOTP / WebAuthn), RBAC (`PLAYER` / `GAME_MASTER`), TLS 1.3 / mTLS, and immutable audit logging |
| **Character Sheet & Attributes** | `character-registry`, `sheet-aggregator` (concurrent `errgroup` fan-out with graceful degradation and tick-based caching), and dedicated `attr-*` microservices |
| **Simulation & Genetics Engine** | Event-driven Go microservices (`sim-clock`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, `sim-dna`, `sim-birth-date`, `sim-gestation`, `sim-mortality`, `sim-lifecycle`) using **SQLite** for scientific reference data, per-female egg-reserve databases, and per-ejaculation sperm-cell artifacts |
| **Real-Time Chat** | `chat-service` + `frontend-chat` with PostgreSQL persistence (`chat.*` schema), NATS JetStream fan-out, rate limiting, and content-policy moderation |
| **Observability & Quality** | **OpenTelemetry** tracing, `log/slog` structured JSON logging, Prometheus metrics, deterministic fixed-seed simulation tests, `golangci-lint`, `govulncheck`, and Trivy container scanning |
| **Deployment Target** | Hardened non-root `distroless/static` containers on **Microsoft Azure Kubernetes Service (AKS)** with Azure Database for PostgreSQL, ACR, and Key Vault |

For full entity-relationship models, architecture diagrams, SQLite deployment patterns, and service catalogs, see the [Technical Concept](docs/Concept.md).

---

## Repository Structure

```text
princesspink/
├── .github/
│   └── workflows/          # CI/CD pipelines (lint, test, security scan, container build & deploy)
├── docs/
│   ├── Concept.md          # Comprehensive technical concept & architecture specification
│   ├── api/                # OpenAPI & Protobuf API specifications
│   ├── architecture/       # Architecture Decision Records (ADRs) & infrastructure specs
│   └── runbooks/           # Operational & incident response runbooks
├── pkg/                    # Shared Go libraries (gRPC/Protobuf contracts, auth middleware, telemetry, helpers)
├── services/               # Independently deployable and versioned Go microservices
├── CODE_OF_CONDUCT.md      # Contributor Covenant Code of Conduct (v2.0)
├── LICENSE                 # BSD 3-Clause License
├── Makefile                # Multi-module build, test, lint, Protobuf, versioning, and container targets
├── README.md               # Project overview and developer entry point
└── go.work                 # Go multi-module workspace definition
```

---

## Getting Started

### Prerequisites

- [Go](https://go.dev/) 1.27+
- [Git](https://git-scm.com/)
- GNU `make`
- *(Optional / for upcoming service builds and local stacks)* [Docker](https://www.docker.com/) (with Compose), PostgreSQL, `kubectl`, and [Trivy](https://trivy.dev/)

### Clone the Repository

```bash
git clone https://github.com/ladrost/princesspink.git
cd princesspink
```

### Developer Workflow (`Makefile`)

The repository provides a multi-module `Makefile` supporting workspace-wide commands as well as single-service scoping via `SERVICE=<service-name>`:

```bash
# List all available targets and examples
make help

# Install Go developer tooling (golangci-lint, govulncheck, buf)
make tools

# Run the full CI quality gate (fmt-check, vet, lint, test-race, vuln)
make check

# Build, test, or version a single microservice (once services are added under services/)
make build SERVICE=sim-gamete-surface
make test-race SERVICE=user-admin
make test-sim
make versions
```

> **Note:** PrincessPink is currently in the **concept and architectural foundation** stage—no microservice implementations have been committed under `pkg/` or `services/` yet. Start by reading [`docs/Concept.md`](docs/Concept.md) to explore the domain model, service boundaries, and implementation plan.

---

## Project Status & Roadmap

PrincessPink is currently in **Phase 0 / Architectural Foundation**. Planned implementation phases (detailed in [docs/Concept.md](docs/Concept.md#9-phased-implementation-roadmap)):

1. **Phase 1 — Platform Foundation:** Shared `pkg/` libraries (logging, OpenTelemetry, gRPC contracts, config, UUID utilities), CI workflows, and `user-admin` with PostgreSQL, Argon2id auth, RBAC, and Group management.
2. **Phase 2 — Character Sheet, Chat & Frontend MVP:** `frontend-gateway`, `frontend-sheets`, `frontend-gm`, `frontend-chat`, `chat-service` (Global, Group, and 1-to-1 Direct Messages), `character-registry`, `sheet-aggregator`, initial `attr-*` microservices, and `portrait-renderer`.
3. **Phase 3 — Core Reproduction Simulation Pipeline:** `sim-clock`, `sim-egg-reserve`, `sim-egg-selection`, `sim-menarche`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-gamete-surface`, `sim-conception`, and `sim-dna` with SQLite stores, event bus integration, and fixed-seed cohort tests.
4. **Phase 4 — Full Lifecycle & Population Features:** `sim-birth-date`, `sim-gestation`, `sim-mortality`, `sim-lifecycle`, multi-generational family trees, and Game Master population analytics.
5. **Phase 5 — Production Hardening on Azure AKS:** Full Helm/Kustomize manifests, Azure PostgreSQL, Key Vault, `NetworkPolicy`, HPA, observability dashboards, security audit, and operational runbooks.

---

## Documentation

- **[Technical Concept (`docs/Concept.md`)](docs/Concept.md)** — Full domain model, ER & sequence diagrams, character lifecycle, gamete DNA & SQLite architecture, microservice catalog, chat design, Azure AKS topology, and glossary.
- **[API Specifications (`docs/api/`)](docs/api/)** — OpenAPI and Protobuf contract documentation (planned).
- **[Architecture Docs (`docs/architecture/`)](docs/architecture/)** — ADRs and infrastructure specifications (planned).
- **[Operational Runbooks (`docs/runbooks/`)](docs/runbooks/)** — Deployment, backup, and incident response runbooks (planned).

---

## Contributing

Contributions, architectural feedback, and scientific modeling discussions are welcome!

1. Read the [Technical Concept](docs/Concept.md), the [Content & Safety Policy](#content--safety-policy), and our [Code of Conduct](CODE_OF_CONDUCT.md).
2. Open an issue to discuss bugs, scientific modeling proposals, or architectural changes before submitting large pull requests.
3. Fork the repository, create a feature branch, and ensure `make check` passes for any Go changes.
4. Submit a pull request with a clear description, rationale, and relevant unit or deterministic simulation tests.

All contributions must strictly respect the project's **zero-violence, zero-nudity** principles.

---

## Code of Conduct

This project adheres to the Contributor Covenant Code of Conduct (version 2.0). By participating, you are expected to uphold this code. Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

---

## Security

PrincessPink is designed with security in mind (`Argon2id`, MFA, RBAC, TLS 1.3/mTLS, `govulncheck`, and Trivy image scanning—see [docs/Concept.md](docs/Concept.md#42-user-administration--security-service)).

If you discover a security vulnerability, please **do not** open a public issue. Instead, report it privately to the project maintainers (e.g., via GitHub Security Advisories) with sufficient detail to reproduce and assess the issue.

---

## License

This project is licensed under the **BSD 3-Clause License** — see the [LICENSE](LICENSE) file for details.