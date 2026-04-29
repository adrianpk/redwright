# ADR-006: Ticket Visibility and Access Semantics

## Status
Accepted

## Date
2026-04-29

## Context
Ticket automation requires composable visibility controls. Assignment alone is insufficient for hidden/internal workflows.

## Decision
Use a composable visibility model with explicit default-deny for agents.

Policy evaluation order:

1. Explicit deny labels (if configured) take precedence.
2. Assignment grant (`assignee == identity`) grants visibility.
3. Label grant (identity allow-list label match) grants visibility.
4. Otherwise deny.

Human visibility remains governed by project membership and role.

## Consequences

### Positive
- Supports hidden/internal tickets.
- Supports controlled exposure for autonomous processing.
- Preserves least-privilege behavior.

### Negative
- Requires stable label taxonomy and policy hygiene.
- Misconfigured labels can reduce automation throughput.
