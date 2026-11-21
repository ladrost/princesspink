# PrincessPink

[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/Go-1.27+-00ADD8?logo=go&logoColor=white)](go.work)
[![Status](https://img.shields.io/badge/Status-Concept%20%26%20Architecture-informational)](docs/Concept.md)

**PrincessPink** is an open-source, scientific simulation of human reproduction and generational lineage presented through a pen-and-paper role-playing game (RPG) interface. Inspired by classic tabletop character sheets, it gamifies human biology, genetics, and population dynamics while visualizing each character with a comic-style face portrait.

---

## Content & Safety Policy

PrincessPink enforces a strict **zero-violence, zero-nudity** policy:

- **No violence or gore:** Unlike combat-oriented RPGs, there are no weapons, battles, or violent mechanics. Characters live and pass away strictly through natural biological lifecycles.
- **No nudity or explicit content:** Human reproduction is modeled purely through abstract scientific data, biological state transitions, and tabletop-style attributes.
- **Safe-by-design visuals:** Visual representation is limited to stylized **comic-art face portraits** derived from a character's phenotypic traits and age stage.

---

## Key Features

- **Pen-and-Paper Character Sheets:** Tabletop-inspired sheets displaying core identity, biological stats, genetic traits, lineage, and a comic-style face portrait.
- **Permanent Character Lifecycle:** Every character receives a globally unique `UUID` at conception and is tracked across its entire lifecycle (`CONCEIVED` → `GESTATING` → `ALIVE` → `DECEASED`) with `gender`, `date_of_birth`, and `date_of_death`.
- **Gender-Specific Biological Simulation:**
  - *Female characters:* Tracks menarche (`date_of_first_menstruation`), `menstruation_dates`, ovarian/menstrual cycle phases, and individual ovulated egg cells.
  - *Male characters:* Models spermatogenesis and generates a dedicated **per-ejaculation SQLite database** of simulated sperm cells.
- **Gamete-Level DNA & Inheritance:** Individual egg cells and sperm cells carry simulated haploid DNA derived via meiosis from their parents. Upon fertilization, the winning sperm cell and egg cell combine to compute the child's immutable diploid DNA and biological gender.
- **Players, Game Masters & Groups:** Role-based access control where **Players** manage their own characters and **Game Masters** oversee simulation groups, time progression, and population dynamics.
- **Modular Microservices Design:** Each character sheet attribute and biological subsystem is designed as an independent Go microservice for clarity, scalability, and scientific extensibility.

---

## Architecture at a Glance

| Layer | Technology / Approach |
| :--- | :--- |
| **Language & Workspace** | Go (`go.work` multi-module workspace) |
| **Frontend Microservices** | Go + **Gin** HTTP framework (character sheets, GM portal, portrait rendering) |
| **Internal Communication** | **gRPC / Protocol Buffers** for synchronous calls; event broker for simulation ticks & lifecycle events |
| **User Administration & Security** | Central **PostgreSQL** with Argon2id password hashing, MFA, RBAC (Player / Game Master), and audit logging |
| **Simulation & Genetics Engine** | Event-driven Go microservices (`sim-clock`, `sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-conception`, `sim-dna`, `sim-gestation`, `sim-lifecycle`) using local **SQLite** for scientific reference data and per-ejaculation sperm-cell databases |
| **Deployment Target** | Containerized workloads on Kubernetes (**Microsoft Azure AKS**) |

For full system diagrams, entity-relationship models, data schemas, and security details, see the [Technical Concept](docs/Concept.md).

---

## Repository Structure

```text
princesspink/
├── docs/
│   └── Concept.md     # Comprehensive technical concept & architecture specification
├── pkg/               # Shared Go packages (contracts, middleware, helpers)
├── services/          # Independently deployable Go microservices
├── go.work            # Go multi-module workspace definition
├── Makefile           # Build, test, and developer workflow targets
└── LICENSE            # BSD 3-Clause License
```

---

## Project Status & Roadmap

PrincessPink is currently in the **concept and architectural foundation** stage. Development is planned in phases (detailed in [docs/Concept.md](docs/Concept.md)):

1. **Foundation & User Administration:** Shared `pkg/` contracts, `user-admin` with PostgreSQL, and authentication/RBAC.
2. **Core Character Registry & Sheet Aggregation:** `character-registry`, `sheet-aggregator`, initial `attr-*` services, and Gin frontend.
3. **Biological & Genetic Simulation Engine:** `sim-clock`, gamete/DNA simulation (`sim-menstruation`, `sim-ejaculation`, `sim-sperm-race`, `sim-conception`, `sim-dna`), and lifecycle services.
4. **Portraits, GM Portal & AKS Production Hardening:** `portrait-renderer`, `frontend-gm`, observability, and Azure AKS deployment.

---

## Getting Started

### Prerequisites

- [Go](https://go.dev/) 1.27+
- [Git](https://git-scm.com/)
- *(For upcoming local service runs)* Docker, PostgreSQL, and Kubernetes tooling (`kubectl`)

### Clone the Repository

```bash
git clone https://github.com/your-org/princesspink.git
cd princesspink
```

> **Note:** Microservice implementations and `Makefile` targets are under active design. Start by reading [`docs/Concept.md`](docs/Concept.md) to understand the domain model and service boundaries.

---

## Documentation

- **[Technical Concept (`docs/Concept.md`)](docs/Concept.md)** — Full domain model, character lifecycle, gamete DNA & SQLite architecture, microservice catalog, Azure AKS infrastructure, and glossary.

---

## Contributing

Contributions, architectural feedback, and scientific modeling discussions are welcome!

1. Review the [Technical Concept](docs/Concept.md) and the **Content & Safety Policy** above.
2. Open an issue to discuss bugs, ideas, or proposed changes before submitting large pull requests.
3. Fork the repository, create a feature branch, and submit a pull request with clear descriptions and tests where applicable.

All contributions must strictly respect the project's **zero-violence, zero-nudity** principles.

---

## License

This project is licensed under the **BSD 3-Clause License** — see the [LICENSE](LICENSE) file for details.