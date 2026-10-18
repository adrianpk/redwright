# Ticket Workflow for Small Fixes

Use tickets for small, bounded fixes where full plan/tracker formalization is unnecessary.

## Ticket Rules

1. Create ticket files under `ops/tickets/`.
2. Use sortable filename format: `YYYYMMDDHHMMSS-<slug>.md` (UTC timestamp).
3. Use frontmatter fields from `ops/tickets/TEMPLATE.md`.
4. Keep code and repository docs in English.
5. Allowed status values: `open`, `in_progress`, `reviewing`, `solved`, `closed`, `blocked`.
6. Allowed transitions: `open -> in_progress`, `in_progress -> reviewing`, `reviewing -> solved`, `reviewing -> closed`, `* -> blocked`, `blocked -> in_progress`.
7. Mutate ticket state in the same implementation cycle.
8. Set `started_at` on `open -> in_progress`.
9. Link `branch`, `pr`, and `commits` before or during `reviewing`.
10. Set `closed_at` only on `reviewing -> solved` or `reviewing -> closed`.
11. Keep ticket `reviewing` while implementation PR is open.
12. Update ticket to `solved` or `closed` directly on `dev` after review decision.
13. Do not open dedicated PRs only for ticket status metadata.
14. If scope expands, promote ticket to formal plan/slice/tracker flow.

## Reduced Workflow (Ticket-Driven)

1. Create ticket under `ops/tickets/`.
2. Create a branch from `dev`.
3. Set ticket `status: in_progress` and `started_at`.
4. Implement the fix.
5. Set ticket `status: reviewing`, update `branch`, `pr`, and `commits`.
6. Open one PR for the ticket, targeting `dev`.
7. Complete review.
8. Merge into `dev`, then set ticket `status: solved` and `closed_at` when resolved; use `closed` when discarded/not resolved.
