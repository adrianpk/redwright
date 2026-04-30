# ADR-009 Ticket Lifecycle vs Visibility and Deletion

## Status
Accepted

## Context
The Kanban module requires clear semantics for:
- operational status progression,
- ticket visibility management,
- irreversible removal.

Without explicit boundaries, `archive` and `delete` can be confused with workflow states, creating ambiguity in UI behavior, data interpretation, and authorization policies.

## Decision
1. Column status remains the single source of truth for operational workflow stage.
2. `archive` is a transversal visibility flag, not a workflow status.
3. `delete` is a hard delete operation, not a workflow status.

## Semantics
## Status
- Encoded by ticket column.
- Represents operational progression (`backlog`, `in_progress`, `review`, `approved`, `merged`, etc.).

## Archive
- Implemented via `archived_at`.
- Does not modify ticket column/status.
- Removes ticket from active board visibility.
- Preserves the last operational stage for future interpretation.

## Delete
- Physically removes the ticket record.
- Leaves no residual workflow state.
- Is terminal and irreversible by design.

## Consequences
## Positive
- Clear separation of concerns:
  - status answers `where in workflow`,
  - archive answers `visible in active board or not`,
  - delete answers `exists or not`.
- Avoids overloading Kanban columns with non-operational concepts.
- Supports future reporting consistency by preserving pre-archive stage.

## Tradeoffs
- Archived tickets require dedicated retrieval surfaces (not in active board scope).
- Hard delete removes historical recovery options unless external audit/event logs are introduced.

## Policy Notes
- `archive` may be used from any status.
- Most archived tickets are expected to come from `merged`, but this is not a system constraint.
- Authorization for `archive` and `delete` remains role-governed.

## Rejected Alternatives
1. Model `archive` as a dedicated board column.
  - Rejected because archive is a visibility concern, not an operational stage.
2. Model `delete` as a pseudo-status.
  - Rejected because deleted tickets no longer exist and cannot carry state.
3. Soft delete for removed tickets.
  - Rejected for now; hard delete is the selected behavior.
