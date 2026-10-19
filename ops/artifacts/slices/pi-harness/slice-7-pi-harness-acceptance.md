# Slice 7: Operator Guidance and Integrated Acceptance

Status: reviewing
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-7-pi-pi-harness-acceptance`
PR: pending

## Purpose

Give operators accurate setup, selection, compatibility and recovery guidance,
and connect the delivered boundaries in representative owned project journeys.

## Delivered Behavior

- The existing User Guide explains preparing profiles, saving/clearing the two
  independent choices, reading local readiness and active bindings, and
  verifying draft generation without treating it as approval.
- The configuration reference describes versioned private registry/static
  resources, native Pi 1.3.0 Linux containment, exact limits, requested versus
  observed model evidence, unknown usage and fail-closed recovery.
- An authenticated integrated journey changes a profile through a second Rails
  process, observes the new default alongside an older active binding, uses
  the new profile in a real subprocess, and reconciles an uncertain call with
  the same owned lease from another process.
- A Codex-only fixture generates, approves and slices a feature before a
  direct-API ticket proposal goes through context filtering, real application,
  Go validation, local Git and the existing reviewing transition.
- The [cycle report](../../2026-10-19-redwright-pi-harness-cycle-report.md)
  maps PI-01 through PI-15 to focused evidence and explicit unsupported or
  unverified boundaries. T7.3 remains open for controller gate evidence and
  final documentation closure after integration.

## Implementation Notes

The approved update preserves the existing User Guide location. Supporting
configuration contracts live in `docs/reference/harness-profiles.md` and link
back to the existing guide. No product behavior or runtime configuration is
changed by this slice.

`HarnessWorkflowTest` uses an owned SQLite database, authenticated Rails
sessions, prepared Codex-compatible subprocess fixtures and the existing
selection/operation owners. Recovery reuses the original lease; it never
invents an owner or replays inference. The direct provider completion is the
only injected model boundary in the feature-to-ticket journey.

## Contracts Added or Changed

The reference documents the delivered registry/resource formats, settings
semantics, containment boundary and limits. The cycle evidence map separates
implemented Linux capabilities from unsupported macOS/inspection/OAuth behavior
and unverified paid authentication. The external controller owns the unchanged
full gate; this PR's readiness checks cannot close T7.3 or the delivery set.

## Files of Interest

- `docs/reference/harness-profiles.md`
- `docs/how-to/user-guide/configure-redwright.md`
- `docs/how-to/user-guide/use-the-web-app.md`
- `apps/web/test/integration/harness_workflow_test.rb`
- `ops/artifacts/2026-10-19-redwright-pi-harness-cycle-report.md`

## Validation

Passed during implementation:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/integration/harness_workflow_test.rb)
```

Result: 2 tests, 63 assertions, no failures, errors or skips; 3.22 seconds.
Six Markdown files rendered; JSON examples, fences and 57 local links passed.

Final clean-HEAD checks are recorded once through `looper validate`, after all
PR-reference commits and pushes. Its exact-commit evidence owns the final
pre-merge results. The required prefix is:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
```

Documentation rendering, ticket metadata, changed Ruby syntax and
`git diff --check` follow that prefix. The full delivery-set gate, including
root Ruby tests, remains with the controller after Slice 7 integration.

## Risks and Follow-ups

T7.3 and delivery-set closure require the controller's exact integrated gate
candidate and green evidence. The cycle report is prepared for that evidence
and is not marked delivered. Unknown usage and provider authentication remain
truthfully distinct from local readiness and owned loopback proof.
