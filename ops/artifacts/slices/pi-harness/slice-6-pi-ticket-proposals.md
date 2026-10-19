# Slice 6: Pi Ticket Proposals under Rails Authority

Status: delivered
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-6-pi-pi-ticket-proposals`
PR: [#15](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/15)

## Purpose

Use the independently selected ticket-proposal profile at the existing model
boundary while Rails retains context shaping, application, validation, local
Git finalization and ticket transitions.

## Delivered Behavior

- The production ticket requester resolves one project selection before model
  work. Null ticket selection preserves the existing direct-API requester;
  authoring selection is independent. Unavailable selected profiles fail
  without provider fallback.
- Selected structured calls reuse the ticket RequestEngine context policy,
  redaction, prompt and LlmContract. Host JSON Schema validates nested proposal
  data before domain validation. Transport completion alone cannot move a
  ticket to review.
- Corrections retain one binding, schema/policy identity and absolute deadline,
  with at most three attempts. Each attempt records its original file/index/HEAD
  fingerprint and output digest. Existing OutputApplier, validation commands,
  GitFinalizer and KanbanTransitioner continue to own their effects.
- Before application, all file/action/patch paths are preflighted. Absolute,
  traversal, Git-metadata and symlink paths fail before any valid prefix can
  mutate files. Unexpected workspace changes fail with a base conflict.
- Application, validation and finalization record pending effects before
  execution and durable result/base receipts before advancing correction
  context. A private workspace lock serializes participating ticket operations.
  Losing an effect or completion receipt retains an uncertain operation and
  capacity. Reusing its request ID or introducing a new ID cannot bypass that
  unresolved workspace operation; no inference or side effect is replayed.

## Implementation Notes

`Harnesses::TicketRequester` injects a scoped requester through ValidationLoop
and wraps ValidationExecutor through finalization. Its structured client plugs
into the existing RequestEngine, so context filtering is shared with the
preserved direct provider. Selected transports and host primitive calls share
the operation deadline; host timeouts are capped by the remaining lifetime.

`ProposalWorkspace` captures at most 4,096 entries and 64 MiB, including ignored
workspace files, without following symlinks. Git metadata is represented by
HEAD and the index digest. Retained fingerprints and receipts contain hashes,
counts and revisions rather than file bodies or private resource paths.
Owned application establishes the next correction base only after its receipt
persists. Uncertain effects require their owner's reconciliation; request
identity is never treated as proof of exactly-once inference or application.

## Contracts Added or Changed

- `LlmContract.schema` supplies the bounded host schema for selected ticket
  proposals; existing semantic validation remains authoritative.
- Ticket attempt evidence requires the current lease owner. Its base,
  schema/policy and output digest cannot be changed after recording.
- Existing saved work without the injected requester keeps its previous
  execution path. The current production boundary admits versioned harness
  bindings and refuses conflicting contract/base reuse.

## Files of Interest

- `apps/web/app/services/harnesses/ticket_requester.rb`
- `apps/web/app/services/harnesses/operation.rb`
- `apps/web/app/services/agent_ticket_execution/proposal_workspace.rb`
- `apps/web/app/services/agent_ticket_execution/validation_loop.rb`
- `apps/web/app/services/agent_ticket_execution/validation_executor.rb`
- `apps/web/test/services/harnesses/ticket_proposal_integration_test.rb`
- `apps/web/test/integration/pi_harness_acceptance_test.rb`

## Validation

Passed during implementation:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/services/agent_ticket_execution test/services/harnesses/ticket_proposal_integration_test.rb test/services/harnesses/operation_test.rb)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
```

Focused ticket/operation checks: 75 tests, 700 assertions, no failures, errors or
skips; 15.28 seconds. They cover context filtering, separate roles, retained
corrections, immutable evidence, invalid schema/domain/path proposals, changed
bases, host validation failure and uncertain application/Git/completion replay.
The selected end-to-end case reaches reviewing only after real Go tests and a
local commit; validation failure exhausts three attempts and keeps the ticket
blocked without a commit.

Native Pi acceptance: 6 tests, 77 assertions, no failures, errors or skips;
10.35 seconds. The added case runs pinned Pi with an owned loopback endpoint
and dummy selected resources. Pi returns a patch; Rails applies it, runs the
existing operational checks and makes a local commit with no remote. Endpoint
and sandbox fixtures stop after their checks. No provider authentication claim
is derived from this local acceptance.

Final clean-HEAD checks are recorded through `looper validate`, after all
PR-reference commits and pushes. Its exact-commit evidence owns final results:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
(cd apps/web && RAILS_ENV=test REDWRIGHT_PI_ACCEPTANCE=1 bundle exec rails test test/integration/pi_harness_acceptance_test.rb)
scripts/agent/tickets/check.sh
git diff --name-only --diff-filter=ACMR origin/dev...HEAD -- '*.rb' | xargs -r -n 1 ruby -wc
git diff --check
```

## Risks and Follow-ups

Uncertain work remains reserved until its existing owner reconciles the
observed effects. This slice does not guess a safe retry from request identity
or a changed default. Operator guidance and the integrated delivery-set gate
remain with the next recorded slice and the external controller.

## Integration

Canonical PR #15 was verified merged into `dev` at
`ae01006350d550fca8ad92dd79ab58e895d76ef8`. Its five ordered controller checks
passed: Rails 619 tests/5,013 assertions (77.42 seconds), native Pi
6 tests/77 assertions (10.76 seconds), ticket metadata, changed Ruby syntax
and whitespace. Acta records the controller-owned integration.
Slice 6 of 7 completed.
