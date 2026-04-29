# ADR-004: Runtime Partitioning (Interactive and Factory)

## Status
Accepted

## Date
2026-04-29

## Context
The product must keep fast interactive workflows while adding reproducible ticket-driven automation.

## Decision
Run two logical runtimes sharing one semantic core:

1. `interactive` runtime:
- Telegram/TUI direct mode.
- No Docker.
- Low-latency operator workflow.

2. `factory` runtime:
- Ticket-driven mode.
- Docker sandbox mandatory.
- Reproducible autonomous or semi-autonomous execution.

Both runtimes must consume the same Command/Query contracts and domain policies.

## Consequences

### Positive
- Isolation of concerns and state.
- Cleaner operational controls and observability.
- Avoids context contamination between informal and factory flows.

### Negative
- Duplicate operational plumbing (queues, metrics, health checks).
- More deployment and lifecycle management complexity.
