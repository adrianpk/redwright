# ADR-003: Command-Query Semantic Core v1

## Status
Accepted

## Date
2026-04-29

## Context
The platform receives heterogeneous input from Telegram, TUI, slash commands, and web UI. Raw text execution is unsafe and non-auditable.

## Decision
All operational behavior must converge to explicit semantic actions:

- `Command` for writes/mutations.
- `Query` for reads.

Adapters may interpret input, but execution is only allowed after successful mapping into a validated Command/Query payload.

## DDD/Application Boundary

1. Adapters:
- Telegram
- TUI
- Web/Rails
- Git provider
- Docker executor

2. Application layer:
- Command handlers
- Query handlers
- policy enforcement (authz, transitions, retries)

3. Domain layer:
- ticket lifecycle invariants
- role restrictions
- visibility semantics

4. Infrastructure layer:
- repositories
- provider clients
- sandbox lifecycle

## Consequences

### Positive
- Deterministic execution boundary.
- Stronger auditing and replayability.
- Cleaner extensibility for additional ingress surfaces.

### Negative
- Initial design overhead for schemas and validators.
- Requires disciplined adapter implementation.
