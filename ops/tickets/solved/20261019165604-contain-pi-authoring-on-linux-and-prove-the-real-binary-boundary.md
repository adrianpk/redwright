---
id: TKT-20261019165604
title: Contain Pi authoring on Linux and prove the real binary boundary
status: solved
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:04Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T18:12:42Z
reviewed_at: 2026-10-19T18:22:51Z
closed_at: 2026-10-19T18:28:08Z
resolution: fixed
owner:
branch: fix/slice-4-pi-pi-linux-containment
pr: https://forge.adrianpk.com/adrianpk/redwrigh/pulls/13
commits: [687c3c818285c0e6632ebd04f90b952c50634ff9, 96cb256e38eae1a6789b27610b85d37eb09c2f59, 5ff9b6268096f1bb81723c27c1bfb91b38dc8e81]
---

# Contain Pi authoring on Linux and prove the real binary boundary

## Context

Supporting repository-development ticket for Slice 4 of the RedWright Pi harness delivery.
One slice/PR is the delivery unit. The plan and tracker own ordering and approval.

- [Plan](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
- [Tracker](../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
- [Specification](../../specs/specs/2026-10-19-redwright-pi-harness-spec.md)
- Prerequisite: Slice 3 integrated and closed.
- Planned branch: `fix/slice-4-pi-pi-linux-containment`
- Planned PR title: `feat(slice-4): linux containment and real pi proof`
- Planned report: `ops/artifacts/slices/pi-harness/slice-4-pi-linux-containment.md`
- Acceptance mapping: `PI-02, PI-06, PI-07, PI-08, PI-09, PI-11, PI-12, PI-14`

## Expected

Prepared Pi profiles can run tool-free calls inside an explicitly verified Linux Bubblewrap policy with isolated selected resources.

- Only the declared scratch area is writable; workspace and outside sentinel write attempts fail at the OS boundary.
- No entire home, runtime socket directory or unrelated credentials are mounted; discovered resources cannot gain authority.
- The Linux proof is required on the delivery host. macOS remains explicitly unsupported for Pi until an equivalent policy is verified; Codex behavior is preserved.

## Actual

All three tasks are implemented. The explicit Linux namespace/mount policy
admits Pi only after an active OS write-denial probe. It excludes the host
workspace and ambient resources, snapshots only the selected static credential
and model, and verifies retained executable/model/policy identities. Focused
OS/resource tests passed (11 tests, 98 assertions). Real Pi 1.3.0 and Bubblewrap
0.12.0 passed owned loopback generation, poisoned discovery, provider/tool
failure, cancellation, deadline and concurrent-call acceptance (4 tests,
55 assertions). Original files and unrelated resources remain untouched.

## Tasks

- [x] `T4.1` Implement LinuxSandbox command construction with read-only mount allowlists, private writable scratch, no inherited host IPC sockets/fds and explicit policy identity/readiness.
- [x] `T4.2` Isolate the selected static credential/model configuration, disable discovery and unattended UI, and expose precise platform/version/resource failures.
- [x] `T4.3` Run the pinned real Pi 1.3.0 against an owned loopback endpoint, proving write denial, resource exclusion, cleanup and valid structured output.

## Planned Commits

- `T4.1`: `feat(harnesses): contain Pi calls with Bubblewrap`
- `T4.2`: `feat(harnesses): isolate Pi resources and readiness`
- `T4.3`: `test(harnesses): prove real Pi containment and generation`

## Validation

From `apps/web`, after this slice supplies any new test paths:

```sh
RAILS_ENV=test bundle exec rails test test/services/harnesses/linux_sandbox_test.rb test/services/harnesses/pi_resources_test.rb
RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb
RAILS_ENV=test bundle exec rails test
```

Use an owned test database. Check changed Ruby syntax, ticket metadata and
`git diff --check`. The final delivery gate remains the plan's exact ordered
gate. These commands are planned, not reported as passed.

## Outcome

Canonical PR #13 merged at `cdeb6dbbffcda5cff44fab6b95c4c07a802fb2b1`.
Retained controller evidence passed all five ordered checks: 594 Rails tests,
4,663 assertions; real Pi acceptance 4 tests, 55 assertions; ticket metadata,
changed Ruby syntax and whitespace. No failures, errors or skips.
