---
id: TKT-20261019165607
title: Document and validate the integrated Pi harness workflow
status: solved
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:07Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T19:15:52Z
reviewed_at: 2026-10-19T19:21:03Z
closed_at: 2026-10-19T19:34:36Z
resolution: fixed
owner:
branch: fix/slice-7-pi-pi-harness-acceptance
pr: https://forge.adrianpk.com/adrianpk/redwrigh/pulls/16
commits: [a3cc089d6905f1e9118076829b762d7ea7df56b1, ef325dc15678de54c911705ed1b7ce6f55ee0be8, f34f9ecde2310e7f191616b09943eb828b2bfeac]
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

T7.1 and T7.2 are integrated through canonical PR #16. The existing guide and configuration reference
cover prepared profiles, independent choices, containment, limits, evidence and
recovery. Integrated switching/recovery and feature-to-ticket journeys passed:
2 tests, 63 assertions. Six documentation files rendered; JSON examples,
fences and 57 local links passed. The cycle report maps every PI requirement.
T7.3 is complete. The unchanged controller gate passed at
`2c42eb5f0f921aacf355244dddfb795d907ce019`: Rails 621 tests/5,076 assertions,
native Pi 6/77 and root Ruby 551/2,902, with no failures, errors or skips.
Ticket metadata and whitespace passed.

## Tasks

- [x] `T7.1` Update the existing User Guide/configuration reference with static-profile setup, effective selections, Linux containment, limits and truthful capability/usage evidence.
- [x] `T7.2` Exercise a representative configured-project journey, cross-process switching/recovery, Codex-only compatibility and ticket validation using owned fixtures.
- [x] `T7.3` Run the unchanged delivery-set gate on the exact integrated candidate and close the cycle report/tracker only with matching green evidence.

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

The focused integrated journey passed with 2 tests/63 assertions. The exact
controller full gate passed at `2c42eb5f0f921aacf355244dddfb795d907ce019`;
the cycle report records the unchanged command, component results and log digest.
The worker used retained evidence rather than rerunning the gate.

## Outcome

Prepared in the dedicated Slice 7 worktree. The canonical
[Slice 7 report](../../artifacts/slices/pi-harness/slice-7-pi-harness-acceptance.md)
and [cycle report](../../artifacts/2026-10-19-redwright-pi-harness-cycle-report.md)
retain the evidence boundary. Canonical PR [#16](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/16) merged
into `dev` at `a5b4120ee1849dd9dd2903f5450081f1234056f2` after six controller checks
passed, including Rails 621 tests/5,076 assertions and native Pi 6/77.
Integration and T7.3 are closed using the successful immutable-candidate gate
evidence. All three tasks are complete and this ticket is solved. The closure
task commit `f34f9ecde2310e7f191616b09943eb828b2bfeac` is recorded in Acta.
