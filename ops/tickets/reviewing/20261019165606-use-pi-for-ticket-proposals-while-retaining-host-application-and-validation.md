---
id: TKT-20261019165606
title: Use Pi for ticket proposals while retaining host application and validation
status: reviewing
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:06Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T19:00:47Z
reviewed_at: 2026-10-19T19:12:15Z
closed_at:
resolution:
owner:
branch: fix/slice-6-pi-pi-ticket-proposals
pr:
commits: [f9cc3037a8842883d391909f23f0ce0747a4a746, 24f5088c0a55648492bdfb70d4c59b31a70c7250]
---

# Use Pi for ticket proposals while retaining host application and validation

## Context

Supporting repository-development ticket for Slice 6 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: Slice 5 integrated and closed.
- Planned branch: `fix/slice-6-pi-pi-ticket-proposals`
- Planned PR title: `feat(slice-6): pi ticket proposals under rails authority`
- Planned report: `ops/artifacts/slices/pi-harness/slice-6-pi-ticket-proposals.md`
- Acceptance mapping: `PI-05, PI-07, PI-10, PI-11, PI-12, PI-13`

## Expected

The existing ticket model step can use a selected structured harness while Rails continues to own context, application, validation and Git.

- The model proposes data; OutputApplier, ValidationLoop, workspace checks and GitFinalizer retain their current authority.
- Schema-valid proposals still need domain/path/base-state checks; external changes cannot be overwritten blindly.
- No tool-using Pi worker, CHR scheduler, automatic forge publication authority or Codex proof replacement is introduced.

## Actual

All three tasks are implemented. The selected ticket requester preserves the
existing context/contract boundary and independent direct-API default. One
binding and deadline cover corrections; per-attempt bases and durable effect
receipts protect host application, validation and local Git finalization.
Invalid proposals, outside edits and uncertain effects block progress.
Focused checks passed: 75 tests/700 assertions. Native Pi ticket acceptance
passed within the six-case acceptance suite: 6 tests/77 assertions.

## Tasks

- [x] `T6.1` Add an injected harness requester to the existing ticket model boundary, preserving the current direct-API default, context shaping and separate role selection.
- [x] `T6.2` Retain the logical correction-loop binding and per-attempt base/schema/policy evidence; reconcile uncertain application/finalization before retrying effects.
- [x] `T6.3` Verify valid/invalid proposals, changed-base conflicts, correction attempts, uncertain replay and failure of host validation without false ticket completion.

## Planned Commits

- `T6.1`: `feat(harnesses): generate ticket proposals through selected profiles`
- `T6.2`: `feat(tickets): retain proposal bases and reconcile retries`
- `T6.3`: `test(tickets): protect Pi proposal application authority`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/services/agent_ticket_execution test/services/harnesses/ticket_proposal_integration_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Implemented in the dedicated Slice 6 worktree. The canonical report is
[Slice 6](../../artifacts/slices/pi-harness/slice-6-pi-ticket-proposals.md).
Canonical PR references and final exact-head controller evidence follow the
task commits before readiness. The controller owns integration into `dev`.
