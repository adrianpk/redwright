---
id: TKT-20261019165604
title: Contain Pi authoring on Linux and prove the real binary boundary
status: in_progress
kind: task
severity: unclassified
priority: normal
scope: llm
tags: pi-harness, slice-delivery, rails
source: chat
reported_at: 2026-10-19T16:56:04Z
ready_at: 2026-10-19T17:08:55Z
started_at: 2026-10-19T18:12:42Z
reviewed_at:
closed_at:
resolution:
owner:
branch: fix/slice-4-pi-pi-linux-containment
pr:
commits: []
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

Linux namespace construction, active write-denial admission and private scratch cleanup are implemented; focused OS tests passed (5 tests, 32 assertions). The maintainer approved this slice and its
dependency/platform choices under the linked plan. Respect preceding slice
dependencies; only this Pi delivery has autonomous commit/integration authority.

## Tasks

- [x] `T4.1` Implement LinuxSandbox command construction with read-only mount allowlists, private writable scratch, no inherited host IPC sockets/fds and explicit policy identity/readiness.
- [ ] `T4.2` Isolate the selected static credential/model configuration, disable discovery and unattended UI, and expose precise platform/version/resource failures.
- [ ] `T4.3` Run the pinned real Pi 1.3.0 against an owned loopback endpoint, proving write denial, resource exclusion, cleanup and valid structured output.

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

Ready under the approved plan; implementation pending. Existing Settings/Setup changes,
preview services, credentials and active databases remain outside this ticket.
