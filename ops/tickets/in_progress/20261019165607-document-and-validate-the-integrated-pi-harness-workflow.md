---
id: TKT-20261019165607
title: Document and validate the integrated Pi harness workflow
status: in_progress
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:07Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T19:15:52Z
reviewed_at:
closed_at:
resolution:
owner:
branch: fix/slice-7-pi-pi-harness-acceptance
pr:
commits: []
---

# Document and validate the integrated Pi harness workflow

## Context

Supporting repository-development ticket for Slice 7 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: Slice 6 integrated and closed.
- Planned branch: `fix/slice-7-pi-pi-harness-acceptance`
- Planned PR title: `feat(slice-7): operator guidance and integrated acceptance`
- Planned report: `ops/artifacts/slices/pi-harness/slice-7-pi-harness-acceptance.md`
- Acceptance mapping: `PI-01 through PI-15`

## Expected

An operator can configure prepared Pi profiles, switch a project, understand failures and verify the integrated behavior with recorded evidence.

- All PI acceptance requirements have an explicit delivered/unsupported evidence mapping and the selected real-binary proof passes.
- Full Rails regression and the existing root Ruby suite pass on the exact integrated candidate; no main promotion occurs.
- Application code, Settings/Setup work and preview services outside this delivery remain preserved.

## Actual

Implementation has not started. The maintainer approved this slice and its
dependency/platform choices under the linked plan. Respect preceding slice
dependencies; only this Pi delivery has autonomous commit/integration authority.

## Tasks

- [ ] `T7.1` Update the existing User Guide/configuration reference with static-profile setup, effective selections, Linux containment, limits and truthful capability/usage evidence.
- [ ] `T7.2` Exercise a representative configured-project journey, cross-process switching/recovery, Codex-only compatibility and ticket validation using owned fixtures.
- [ ] `T7.3` Run the unchanged delivery-set gate on the exact integrated candidate and close the cycle report/tracker only with matching green evidence.

## Planned Commits

- `T7.1`: `docs(harnesses): explain selectable Pi and Codex workflows`
- `T7.2`: `test(harnesses): verify integrated selection and recovery`
- `T7.3`: `chore(ops): close the validated Pi harness delivery`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/integration/harness_workflow_test.rb
RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Ready under the approved plan; implementation pending. Existing Settings/Setup changes,
preview services, credentials and active databases remain outside this ticket.
