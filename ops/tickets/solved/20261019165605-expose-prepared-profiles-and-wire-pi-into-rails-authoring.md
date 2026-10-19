---
id: TKT-20261019165605
title: Expose prepared profiles and wire Pi into Rails authoring
status: solved
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:05Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T18:38:14Z
reviewed_at: 2026-10-19T18:51:31Z
closed_at: 2026-10-19T19:00:47Z
resolution: fixed
owner:
branch: fix/slice-5-pi-pi-authoring-settings
pr: https://forge.adrianpk.com/adrianpk/redwrigh/pulls/14
commits: [3c155dbfc4f2f680c877cf97f0e4238ec51fd1cf, bf117bec6d674fa02276c94a9c8bbf9edf7cc6c1, 324e68d8473c6fea88c1e7ed4a9999bc2f20b73c]
---

# Expose prepared profiles and wire Pi into Rails authoring

## Context

Supporting repository-development ticket for Slice 5 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: Slice 4 integrated and closed.
- Planned branch: `fix/slice-5-pi-pi-authoring-settings`
- Planned PR title: `feat(slice-5): selectable pi authoring in the web app`
- Planned report: `ops/artifacts/slices/pi-harness/slice-5-pi-authoring-settings.md`
- Acceptance mapping: `PI-02, PI-03, PI-04, PI-08, PI-10, PI-15`

## Expected

Users can inspect/change project harness defaults through a compact authenticated Rails page and use Pi for each existing authoring action.

- The UI uses the existing Rails visual language and selection service; it accepts profile keys rather than executable or credential paths.
- Changing defaults affects new calls only, including separate authoring and ticket-proposal choices.
- No refresh/restart, paid probe or provider installation is hidden in a settings mutation.

## Actual

All three tasks are implemented. The four Rails authoring consumers retain one
selected binding, deadline and owned lease through nested calls and existing
host publication. The authenticated Harness page provides separate role
controls, local readiness and active bindings with private data excluded.
Focused checks passed (37 tests, 484 assertions), including a separate Rails
process changing selections. Native Pi produced a Rails draft in owned loopback
acceptance (5 tests, 65 assertions). Compiled styles and Chromium viewport proof
passed at 390 and 1280 pixels (1 test, 26 assertions).

## Tasks

- [x] `T5.1` Inject one retained authoring operation into Specs, slicing, Dumps and protocol references; preserve current revisions, semantic checks and atomic publication.
- [x] `T5.2` Add a project-scoped Harness settings resource with compact controls for prepared profiles, clear-to-default, active bindings and local readiness.
- [x] `T5.3` Verify authenticated and stale/conflicting changes, independent process visibility, responsive rendering and all four authoring consumer boundaries.

## Planned Commits

- `T5.1`: `feat(harnesses): use selected profiles for Rails authoring`
- `T5.2`: `feat(web): expose project harness selections`
- `T5.3`: `test(web): verify harness switching and authoring`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/controllers/project_harness_settings_controller_test.rb test/services/harnesses/authoring_integration_test.rb test/controllers/documents_controller_test.rb test/controllers/project_protocols_controller_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Implemented in the dedicated Slice 5 worktree. The canonical report is
[Slice 5](../../artifacts/slices/pi-harness/slice-5-pi-authoring-settings.md).
Canonical PR [#14](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/14) merged
into `dev` at `c54eaa3cca7da2673218c7cc9a070afea4cdce39` after seven ordered
controller checks passed, including Rails 608 tests/4,865 assertions.
