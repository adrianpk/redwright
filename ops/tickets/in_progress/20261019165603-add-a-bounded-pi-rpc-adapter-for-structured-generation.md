---
id: TKT-20261019165603
title: Add a bounded Pi RPC adapter for structured generation
status: in_progress
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:03Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T17:51:32Z
reviewed_at:
closed_at:
resolution:
owner:
branch: fix/slice-3-pi-pi-rpc
pr:
commits: []
---

# Add a bounded Pi RPC adapter for structured generation

## Context

Supporting repository-development ticket for Slice 3 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: Slice 2 integrated and closed.
- Planned branch: `fix/slice-3-pi-pi-rpc`
- Planned PR title: `feat(slice-3): bounded pi rpc calls`
- Planned report: `ops/artifacts/slices/pi-harness/slice-3-pi-rpc.md`
- Acceptance mapping: `PI-02, PI-05, PI-06, PI-07, PI-11, PI-12`

## Expected

A pinned Pi adapter handles correlated setup, settlement, final output and owned-process cleanup through the shared Rails call contract.

- A prompt acknowledgment, agent_end, partial JSON or tool event alone is never accepted as a final result.
- The adapter rejects missing containment evidence until the next slice supplies it; existing Codex remains usable.
- Fixtures establish transport behavior without paid provider calls or a new background service.

## Actual

Shared bounded process supervision is implemented and Codex authoring uses it. The maintainer approved this slice and its
dependency/platform choices under the linked plan. Respect preceding slice
dependencies; only this Pi delivery has autonomous commit/integration authority.

## Tasks

- [x] `T3.1` Implement shared owned-process supervision with concurrent pipe draining, deadlines, stream ceilings, sanitized diagnostics and deterministic reaping.
- [x] `T3.2` Implement PiAdapter for Pi 1.3.0 RPC, exact model/provider setup, ephemeral tool-free sessions and final settlement validation.
- [ ] `T3.3` Exercise split/interleaved records, invalid UTF-8, early/late exits, provider failure, cancellation and encoded 2 MiB results through real pipe fixtures.

## Planned Commits

- `T3.1`: `feat(harnesses): supervise bounded subprocess calls`
- `T3.2`: `feat(harnesses): add the Pi structured call adapter`
- `T3.3`: `test(harnesses): cover Pi RPC lifecycle and limits`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/services/harnesses/pi_transport_test.rb test/services/harnesses/process_supervisor_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Ready under the approved plan; implementation pending. Existing Settings/Setup changes,
preview services, credentials and active databases remain outside this ticket.
