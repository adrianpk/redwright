# Slice 4: Linux Containment and Real Pi Proof

Status: delivered
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-4-pi-pi-linux-containment`
PR: [#13](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/13)

## Purpose

Admit prepared Pi 1.3.0 profiles through an explicit Linux filesystem policy
and prove the real executable against a controlled loopback provider.

## Delivered Behavior

- `pi-linux-bwrap/v1` starts with an empty mount namespace, isolated user,
  process, IPC and hostname namespaces, a separate terminal session, dropped
  capabilities and disabled nested user namespaces. It mounts only the native
  executable, package metadata, explicit runtime libraries, CA/resolver files
  and private scratch. Root, proc and device directory mounts are read-only.
- Tool-free generation gets context over stdin. The host workspace, home,
  runtime sockets and unrelated configuration are absent from the namespace.
  A native OS probe must successfully write scratch and fail workspace/system
  writes before Pi can start. Failure never admits an uncontained process.
- Private scratch holds only the selected provider's static API key, the
  selected custom endpoint/model and fixed discovery/retry/compaction settings.
  Other providers and models are filtered out. OAuth, credential commands,
  environment expansion, custom credential headers and unsupported model
  resource formats fail explicitly. Source resources remain unchanged.
- Prepared profile readiness checks native Linux x86_64 support, Bubblewrap,
  Pi 1.3.0 distribution metadata and resource availability. Credential contents
  are read only at call time; readiness makes no provider request. Calls verify
  retained executable/model/policy identities and the actual contained version.
- The pinned native Pi binary completes host-validated structured generation
  through an owned OpenAI-compatible loopback endpoint. Real errors, tool
  requests, cancellation, deadlines and simultaneous calls retain the existing
  transport ownership and cleanup rules. Successful results name the verified
  containment policy revision.

## Implementation Notes

`LinuxSandbox` constructs the policy rather than relying on Bubblewrap defaults.
The policy uses a finite file allowlist, per-call mode-0700 scratch, scrubbed
environment, closed inherited descriptors and a PID-namespace reaper. The
shared supervisor owns process termination and waiting; context cleanup runs
after supervised children finish. The native package metadata is mounted next
to the executable because the compiled Pi runtime uses it for version/config
identity. Shell launchers and unsupported runtime layouts are rejected.

`PiResources` reads bounded private regular files without following a final
symlink, accepts only the selected static credential and copies filtered
resources into mode-0600 runtime files. The non-secret custom model snapshot
has a semantic revision; changed endpoints/models cannot alter retained calls.
Private paths and credential bytes never enter public profile projections,
model argv or retained stream diagnostics.

The implementation follows the pinned [Bubblewrap policy documentation](https://github.com/containers/bubblewrap/blob/v0.12.0/README.md)
and [Pi 1.3.0 configuration contract](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/configuration.md).
Provider network access remains available in the host network namespace;
filesystem containment does not claim network isolation. The selected model
endpoint is host configuration, not model-controlled output.

## Contracts Added or Changed

- Added the `pi-linux-bwrap/v1` containment owner and active OS admission probe.
- Added selected static Pi resource snapshots, explicit resource/auth errors
  and non-secret model configuration revisions.
- Pi prepared profiles now require OS containment and reject controlled
  inspection. Supported profiles use the contained adapter by default.
- Added opt-in real Pi acceptance. Explicit acceptance fails if native Pi,
  Bubblewrap or the policy proof is unavailable; the ordinary suite does not
  register the opt-in cases.
- PI-02, PI-06, PI-07, PI-08, PI-09, PI-11, PI-12 and PI-14 have evidence at
  the contained transport boundary.

## Files of Interest

- `apps/web/app/services/harnesses/linux_sandbox.rb`: mount/namespace policy,
  retained executable identity, active admission and owned scratch lifetime.
- `apps/web/app/services/harnesses/pi_resources.rb`: bounded static resource
  filtering and native distribution metadata.
- `apps/web/app/services/harnesses/profile_registry.rb` and `pi_adapter.rb`:
  local profile readiness and contained default invocation.
- `apps/web/test/services/harnesses/linux_sandbox_test.rb` and
  `pi_resources_test.rb`: OS write denial, descriptor/resource exclusion and
  unsupported platform/auth/resource behavior.
- `apps/web/test/integration/pi_harness_acceptance_test.rb` and
  `test/support/pi_acceptance_fixture.rb`: real native Pi and owned loopback
  endpoint, poisoned discovery, failure/lifetime and concurrency proof.

## Validation

Development checks passed from the repository root:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/services/harnesses/linux_sandbox_test.rb test/services/harnesses/pi_resources_test.rb)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
```

Focused OS/resource checks: 11 tests, 98 assertions, zero failures, errors or
skips. Real Pi acceptance: 4 tests, 55 assertions, zero failures, errors or skips.
The proof used native Pi 1.3.0 and Bubblewrap 0.12.0 with owned temporary files,
dummy static credentials and an owned loopback HTTP endpoint. No paid provider
or running application database was used. Endpoint threads and scratch trees
are stopped or removed after each owned check.

Final clean-HEAD checks run through `looper validate`; retained exact-commit
evidence is authoritative before PR readiness and integration:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
scripts/agent/tickets/check.sh
git diff --name-only --diff-filter=ACMR origin/dev...HEAD -- '*.rb' | xargs -r -n 1 ruby -wc
git diff --check
```

Canonical PR #13 merged at `cdeb6dbbffcda5cff44fab6b95c4c07a802fb2b1`.
Retained controller evidence passed all five commands above: 594 Rails tests,
4,663 assertions in 65.84 seconds; real Pi acceptance 4 tests, 55 assertions in
7.99 seconds. Both suites had zero failures, errors or skips.

## Risks and Follow-ups

The supported proof is the pinned native Linux x86_64 distribution with the
declared runtime dependencies. Other executable layouts fail admission; macOS
and controlled inspection remain unsupported. This policy permits provider
network access and does not certify hard token budgets or remote cancellation.
Authoring settings and ticket consumers retain their approved later integration
slices. Shared operation capacity and attempt authority remain with Rails.
