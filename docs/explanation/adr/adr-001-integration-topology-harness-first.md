# ADR-001: Integration Topology (Harness-First)

## Status
Accepted

## Date
2026-04-29

## Context
RedWright already has an operational runtime for Telegram/TUI ingress, planning, execution, and Git automation. A new web-based Kanban layer must be integrated without regressing existing direct workflows.

Two options were considered:

1. Rails-first: Rails owns runtime lifecycle and embeds the harness.
2. Harness-first: harness remains execution owner; web layer is an adapter.

## Decision
Adopt **harness-first topology** for v1.

- Harness remains the primary execution owner.
- Web layer (Rails) provides Kanban orchestration, persistence, and UI.
- Rails communicates with harness through explicit Command/Query contracts.

## Consequences

### Positive
- Preserves existing Telegram/TUI behavior and operational maturity.
- Reduces migration risk by keeping one execution core.
- Enables multiple UI surfaces over the same semantic core.

### Negative
- Requires explicit integration boundary and API contracts.
- Rails-centric features cannot bypass harness execution semantics.

## Non-Goals
- Rewriting runtime orchestration inside Rails for v1.
- Replacing current ingress adapters.
