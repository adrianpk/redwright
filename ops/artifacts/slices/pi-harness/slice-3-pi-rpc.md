# Slice 3: Bounded Pi RPC Calls

Status: reviewing
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-3-pi-pi-rpc`
PR: [#12](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/12)

## Purpose

Provide a bounded Pi 1.3.0 RPC adapter behind the Rails structured-call contract,
with explicit final-result ownership and host validation.

## Delivered Behavior

- Shared subprocess supervision drains stdout and stderr while writing stdin,
  observes one absolute deadline and cancellation, terminates owned process
  groups on failure, and reaps owned children. Codex keeps its existing command
  and final-output-file contract through this supervisor.
- Pi requires verified containment before any executable invocation. Within an
  admitted context it verifies version 1.3.0, the retained provider/model and
  optional thinking level, then creates an ephemeral session with tools,
  discovery, automatic retries and compaction disabled.
- Unique command IDs correlate setup and prompt acknowledgments. A result
  requires the owned prompt to start, an authoritative final assistant message,
  matching agent-end evidence, non-aborted settlement, verified idle state and
  a successful process exit. Partial output, handled/queued prompts, tool/UI
  requests, provider failures and incomplete or late records fail the call.
- Strict UTF-8 JSONL framing accepts split records, CRLF and interleaved passive
  events. Unicode line/paragraph separators remain message content. Host schema
  and deadline checks run before any structured result reaches its caller.
- Encoded input is bounded to 1 MiB, schemas to 64 KiB, individual RPC records
  to 16 MiB, stdout/stderr to 64 MiB/2 MiB, and decoded final results to 2 MiB
  or a stricter caller limit. Diagnostics retain byte counts with zero raw
  stream bytes; requested bindings and observed provider/model remain distinct.
  Missing usage remains unknown and partial counters remain partial.

## Implementation Notes

`ProcessSupervisor` uses nonblocking pipes and an owned process group. An exited
leader remains unreaped while inherited output pipes are open, preserving its
identity for group cleanup. Every exceptional path closes owned pipes and waits
for the child. No stream content is retained as diagnostic text.

`PiAdapter` admits a host-owned containment collaborator, applies the same
deadline to version verification and RPC, and scrubs the inherited environment.
`PiProtocol` owns command correlation and the per-call state machine. Protocol
mapping follows the pinned [Pi 1.3.0 RPC documentation](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/rpc.md).
The binding schema digest must match the host schema; successful results carry
the semantic binding digest and measured final-message counters.

## Contracts Added or Changed

- Added bounded process supervision shared by Codex and Pi.
- Added Pi protocol/version admission and correlated tool-free RPC completion.
- Extended immutable requests with deadline, cancellation, retained binding and
  private resource references; extended results/errors with safe diagnostics.
- PI-02, PI-05, PI-06, PI-07, PI-11 and PI-12 have transport-boundary evidence.
  Existing operation admission remains the owner of shared capacity and attempts.

## Files of Interest

- `apps/web/app/services/harnesses/process_supervisor.rb`: pipe IO, lifetime,
  byte ceilings and owned cleanup.
- `apps/web/app/services/harnesses/pi_adapter.rb` and `pi_protocol.rb`: pinned
  invocation, setup, framing, final ownership and settlement.
- `apps/web/test/services/harnesses/pi_transport_test.rb` and
  `process_supervisor_test.rb`: real-pipe lifecycle and limit regressions.
- `apps/web/test/support/fixtures/pi_rpc.rb`: owned executable fixture with
  split/interleaved events, failure modes and escaped maximum-size results.

## Validation

Development validation passed from the repository root:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/services/harnesses/pi_transport_test.rb test/services/harnesses/process_supervisor_test.rb)
```

Result: 16 tests, 308 assertions, zero failures, errors or skips; 9.32 seconds.
Codex structured-call and generator regressions also passed during transport
extraction. Owned fixture tests verify cancellation, descendant pipe cleanup,
callback failure cleanup, process reaping, environment exclusion, early/late
exit, invalid UTF-8, provider errors and a fully escaped 2 MiB decoded result.

Final clean-HEAD checks are executed through `looper validate`; retained
exact-commit evidence is authoritative before PR readiness and integration:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
scripts/agent/tickets/check.sh
git diff --name-only --diff-filter=ACMR origin/dev...HEAD -- '*.rb' | xargs -r -n 1 ruby -wc
git diff --check
```

## Risks and Follow-ups

Production Pi admission remains blocked until Slice 4 supplies and proves the
Linux containment owner. The sandbox collaborator in transport tests admits
only the owned fixture; these tests establish protocol behavior. The real Pi
binary, filesystem policy and controlled endpoint have their separate approved
acceptance boundary in Slice 4. Existing authoring and ticket consumers retain
their assigned later integration slices.
