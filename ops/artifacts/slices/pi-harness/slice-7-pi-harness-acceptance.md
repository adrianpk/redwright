# Slice 7: Operator Guidance and Integrated Acceptance

Status: delivered
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-7-pi-pi-harness-acceptance`
PR: [#16](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/16)

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
  unverified boundaries. T7.3 is complete using the controller's matching
  integrated gate evidence and documentation closure.

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
full gate. Its successful integrated result now closes T7.3 and the delivery
set; pre-merge checks remain a separate evidence boundary.

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
root Ruby tests, passed through the controller at the candidate recorded below.

## Risks and Follow-ups

None recorded within the approved delivery. Unsupported macOS containment,
OAuth refresh and tool-using workers, plus unverified paid authentication,
remain explicit in the cycle evidence map. Unknown usage remains distinct
from local readiness and owned loopback proof.

## Integration

Canonical PR #16 was verified merged into `dev` at
`a5b4120ee1849dd9dd2903f5450081f1234056f2`. Its six ordered controller checks
passed: Rails 621 tests/5,076 assertions (80.38 seconds), native Pi
6 tests/77 assertions (10.74 seconds), documentation rendering, ticket
metadata, changed Ruby syntax and whitespace. Acta records integration.
All seven slice PRs are integrated. The unchanged full gate subsequently
passed at `2c42eb5f0f921aacf355244dddfb795d907ce019`: Rails 621 tests/5,076
assertions, native Pi 6/77 and root Ruby 551/2,902, with no failures, errors
or skips. Ticket metadata and whitespace passed. The cycle report pins the
exact controller command, evidence record and log digest. T7.3 is complete;
Slice 7 of 7 and all 21 tasks are completed.
