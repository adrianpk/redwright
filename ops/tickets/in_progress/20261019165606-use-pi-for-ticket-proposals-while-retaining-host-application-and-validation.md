---
id: TKT-20261019165606
title: Use Pi for ticket proposals while retaining host application and validation
status: in_progress
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:06Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T19:00:47Z
reviewed_at:
closed_at:
resolution:
owner:
branch: fix/slice-6-pi-pi-ticket-proposals
pr:
commits: []
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

Implementation has not started. The maintainer approved this slice and its
dependency/platform choices under the linked plan. Respect preceding slice
dependencies; only this Pi delivery has autonomous commit/integration authority.

## Tasks

- [ ] `T6.1` Add an injected harness requester to the existing ticket model boundary, preserving the current direct-API default, context shaping and separate role selection.
- [ ] `T6.2` Retain the logical correction-loop binding and per-attempt base/schema/policy evidence; reconcile uncertain application/finalization before retrying effects.
- [ ] `T6.3` Verify valid/invalid proposals, changed-base conflicts, correction attempts, uncertain replay and failure of host validation without false ticket completion.

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

Ready under the approved plan; implementation pending. Existing Settings/Setup changes,
preview services, credentials and active databases remain outside this ticket.
