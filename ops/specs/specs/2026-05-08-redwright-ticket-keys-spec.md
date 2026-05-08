# Spec: RedWright Ticket Keys

## Metadata

- status: `approved_for_slice`
- owner: `adrianpk`
- created: `2026-05-08`
- scope: `ticket identifiers, command invocation, board display`
- source_context:
  - `ops/specs/specs/2026-05-08-redwright-agent-ticket-execution-spec.md`
  - `ops/plans/2026-05-08-redwright-agent-ticket-execution-cycle-plan.md`

## Problem

Ticket row IDs are database implementation details. They are useful for internal persistence, but they are not suitable as user-facing or transport-facing ticket references.

The manual Telegram execution workflow must not require commands such as `/ticket start 28`, where `28` is a SQLite row ID. The invocation should use a stable ticket key.

## Goals

- Add a persistent ticket key.
- Support first-cycle keys using the format `RW-<number>`.
- Keep numeric row IDs available internally.
- Allow command boundaries to resolve either a numeric ID or a ticket key during compatibility transition.
- Prefer ticket keys in Telegram/manual instructions and board payloads.
- Keep future project-scoped keys such as `<PROJECTKEY>-<number>` open.

## Non-Goals

- Do not replace database primary keys.
- Do not migrate all URLs to ticket keys in this slice.
- Do not implement project-scoped key sequences yet.
- Do not change the Kanban workflow model.

## Key Format

The first implementation uses:

```text
RW-<number>
```

Examples:

- `RW-1`
- `RW-10`

Keys are stored uppercase and must be unique.

## Generation Semantics

New tickets receive the next available `RW-<number>` key.

Existing tickets are backfilled in deterministic creation order. This keeps Factory tickets stable and allows the manual Go todo scenario ticket to receive a stable ticket key even when SQLite row IDs continue increasing.

Deleted scenario tickets may release their ticket key for reuse during deterministic reset, as long as no existing ticket currently owns that key.

## Command Resolution

Ticket command inputs should resolve a ticket reference, not only a database ID.

Supported references:

- numeric row ID, for temporary backwards compatibility
- `RW-<number>` ticket key

Telegram manual flow should use:

```text
/ticket start RW-10
```

The shorter `/ticket RW-10` form is not the operational command for this workflow.

## UI And API Exposure

Board and ticket payloads should include both:

- `id`: internal row ID
- `ticket_key`: external ticket key

Board cards should display `ticket_key` where a user can identify the ticket.

## Acceptance Criteria

- Tickets persist a unique ticket key.
- Existing tickets are backfilled.
- New tickets receive a ticket key without user input.
- `ExecuteAgentTicket` resolves `/ticket start RW-<n>` through the command API.
- Numeric `ticket_id` remains accepted for backwards compatibility.
- Board payloads and cards expose the ticket key.
- The deterministic Go todo reset prints a Telegram command using the ticket key and restores the active project under `_workspace/Projects`.
