# ADR-008: Kanban-Centric Unified Runtime and Ticket Execution

## Status
Accepted

## Date
2026-04-30

## Context
The prior model distinguished `interactive` and `factory` runtimes and considered dual Telegram bots. Operationally this increased conceptual overhead and allowed ticket bypass paths that degraded consistency.

The product direction is now a Kanban-centric software factory:
- all execution maps to tickets,
- one runtime agent surface handles Telegram/TUI/Rails ingress,
- execution may run as single-ticket or looped ticket processing.

## Decision
Adopt one unified runtime execution surface with ticket-first semantics.

1. Execution modes are redefined:
- `single_ticket`: execute one selected ticket lifecycle (`code -> review -> merge`).
- `loop`: repeatedly pick next eligible ticket by priority/assignment and execute lifecycle.

2. Telegram/TUI ad-hoc requests must be ticketized:
- If user asks to create project: create board + setup ticket.
- If user asks on-the-fly task: create ticket and enqueue in appropriate column/state.

3. Ticket model extensions (MVP-required):
- `priority`: enum with three levels (`high`, `medium`, `low`).
- `time_tracking`: phase timestamps and aggregated duration.

4. Runtime notifications:
- Agent emits ticket progress updates to Telegram by default (configurable later).

5. Identity/runtime topology:
- One bot, one runtime process for MVP.
- Future multi-agent pool is explicitly documented but deferred.

## Open Questions
1. Team topology for scale:
- single composite agent vs role-separated pool (`coder/reviewer/merger`) as independent workers.

2. Parallelization policy:
- fixed worker counts from YAML vs dynamic runtime scaling.

3. Review/merge coupling:
- whether review and merge should be serial in same worker context or delegated to distinct identities.

## Consequences

### Positive
- One mental model across all ingress channels.
- Consistent auditability because all work is represented as tickets.
- Easier prioritization and scheduling.

### Negative
- Additional ticket-creation overhead for ad-hoc interactions.
- Requires robust auto-ticketing UX to avoid operator friction.
