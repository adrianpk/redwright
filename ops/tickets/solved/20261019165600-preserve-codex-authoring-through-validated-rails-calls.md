---
id: TKT-20261019165600
title: Preserve Codex authoring through validated Rails calls
status: solved
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:00Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T17:17:42Z
reviewed_at: 2026-10-19T17:21:37Z
closed_at: 2026-10-19T17:27:34Z
resolution: fixed
owner:
branch: fix/slice-1-pi-validated-codex
pr: https://forge.adrianpk.com/adrianpk/redwrigh/pulls/10
commits: [6908a8c2d4032e92c3e2a28ee62ec20268632bf2, 89dac88b963a8912da2e8dfbd2fc87294d6501ad, 1a4409c49d1298cd240f3753e4fceb9555c1a9eb]
---

# Preserve Codex authoring through validated Rails calls

## Context

Supporting repository-development ticket for Slice 1 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: approved planning artifacts and clean execution checkout.
- Planned branch: `fix/slice-1-pi-validated-codex`
- Planned PR title: `feat(slice-1): validated codex structured calls`
- Planned report: `ops/artifacts/slices/pi-harness/slice-1-validated-codex.md`
- Acceptance mapping: `PI-01, PI-03, PI-04, PI-05`

## Expected

All existing authoring operations keep working through one Rails structured-call service with full host schema validation and unchanged domain publication.

- Codex-only authoring and all four existing consumers work with Pi absent.
- Invalid JSON/schema/domain results and nonzero or timed-out subprocesses cannot publish an artifact.
- Existing executable overrides retain their Codex-compatible meaning; unsupported adapter names cannot fall through.

## Actual

All three Slice 1 tasks are implemented. The four existing authoring consumers
use the shared Codex adapter, host schema validation and unchanged domain/file
owners. Focused validation passed: 35 tests and 389 assertions. Final clean-HEAD
checks are retained by the external controller before PR readiness.

## Tasks

- [x] `T1.1` Introduce Harnesses request/result values, StructuredCall and host JSON-Schema validation; add the approved json_schemer 2.5.0 to the Rails bundle.
- [x] `T1.2` Extract a CodexAdapter and route Specifications, Slicing, Dumps and protocol references through it without changing their prompts, defaults, deadlines or file authority.
- [x] `T1.3` Cover real subprocess success/failure, nested schema rejection and preservation of existing artifacts/statuses.

## Planned Commits

- `T1.1`: `feat(harnesses): validate structured call results in Rails`
- `T1.2`: `refactor(harnesses): route Codex authoring through one adapter`
- `T1.3`: `test(harnesses): protect Codex authoring contracts`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/services/harnesses/structured_call_test.rb test/services/specifications/generator_test.rb test/services/specifications/feature_workflow_test.rb test/services/dumps/curation_test.rb test/services/project_protocols/documents_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Delivered through canonical PR #10 at `09de3682a9c7ab76d40fae3f0cec37ddcfd53d3e`.
Controller validation passed: 549 Rails tests and 4,043 assertions, plus ticket,
Ruby syntax and whitespace checks. Existing Settings/Setup changes,
preview services, credentials and active databases remain outside this ticket.
