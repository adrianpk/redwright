---
id: TKT-20261019165601
title: Persist project harness selection and logical operation bindings
status: ready
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:01Z
ready_at: 2026-10-19T17:08:55Z
started_at:
reviewed_at:
closed_at:
resolution:
owner:
branch:
pr:
commits: []
---

# Persist project harness selection and logical operation bindings

## Context

Supporting repository-development ticket for Slice 2 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: Slice 1 integrated and closed.
- Planned branch: `fix/slice-2-pi-rails-harness-selection`
- Planned PR title: `feat(slice-2): rails selection and retained operations`
- Planned report: `ops/artifacts/slices/pi-harness/slice-2-rails-harness-selection.md`
- Acceptance mapping: `PI-02, PI-10, PI-11, PI-12`

## Expected

One Active Record owner serializes each project's authoring/ticket-proposal defaults, while each logical operation keeps an immutable resolved binding.

- Project selections use one Rails database authority rather than ProjectAttribute business context or a parallel workspace config.
- New requests see a complete settings revision without restart; existing operation bindings do not change.
- No running database or Factory files are reset, migrated or replaced during fixture validation.

## Actual

Implementation has not started. The maintainer approved this slice and its
dependency/platform choices under the linked plan. Respect preceding slice
dependencies; only this Pi delivery has autonomous commit/integration authority.

## Tasks

- [ ] `T2.1` Add ProjectHarnessSetting and HarnessOperation with original create-table migrations, constraints, data-preserving database preparation and private named-profile resolution.
- [ ] `T2.2` Implement one Rails selection/admission service with optimistic revisions, bounded idempotency receipts and immutable bindings across nested calls/retries.
- [ ] `T2.3` Verify separate-process selection races, stale requests, private projections, operation capacity and legacy defaults on owned SQLite fixtures.

## Planned Commits

- `T2.1`: `feat(harnesses): persist project selections and operations`
- `T2.2`: `feat(harnesses): retain resolved operation bindings`
- `T2.3`: `test(harnesses): verify selection and admission concurrency`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/models/project_harness_setting_test.rb test/services/harnesses/selection_test.rb test/services/harnesses/operation_test.rb test/services/specifications/database_rebuild_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Ready under the approved plan; implementation pending. Existing Settings/Setup changes,
preview services, credentials and active databases remain outside this ticket.
