# Slice 2: Rails Selection and Retained Operations

Status: delivered
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-2-pi-rails-harness-selection`
PR: [#11](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/11)

## Purpose

Give Rails one database authority for each project's profile selections and
retain the resolved configuration for every logical harness operation.

## Delivered Behavior

- Independent authoring and ticket-proposal selections use optimistic revisions,
  authenticated actor references and exact retry receipts. Omitted fields remain
  unchanged; an explicit clear restores the existing role default.
- Prepared profiles come from a private, bounded local file. Public projections
  exclude executable/resource paths, private run references and ownership tokens.
  Missing provider/model observations remain unknown.
- Each operation snapshots its selection revision, schema/policy contract,
  workspace authority, profile identity and private resolved references. Existing
  operations reuse this binding after defaults or profile files change.
- Owned call leases serialize two active calls across the application database.
  Uncertainty retains capacity until its owner reconciles the outcome. Authoring
  keeps one attempt; ticket proposals keep three. Technical completion does not
  approve a document or complete a ticket.
- Receipts are limited to 128 per project for seven days. Expiration does not
  restore stale revision authority. Operations are limited to 1,024 per project;
  reclamation removes only unreferenced terminal records older than thirty days.
- Database preparation copies the new domain rows and opaque references while
  preserving existing projects, tickets, documents, dumps and file associations.
  Preparing a legacy database leaves its source schema unchanged.

## Implementation Notes

`ProjectHarnessSetting` and `HarnessOperation` own constrained persistence.
Original create-table migrations supply foreign keys, unique identities and
JSON, state, role and byte checks. Project deletion retains referenced operations.

`Harnesses::Selection` owns mutation and logical admission. Rails' SQLite write
transactions begin with `BEGIN IMMEDIATE`, serializing settings changes and
admission across processes. No transaction remains open during a harness call.
`Harnesses::Operation` issues per-attempt ownership tokens and requires the
matching owner for finalization. Identical completed outcomes are idempotent;
conflicting completion or stale ownership cannot release another call's slot.

`ProfileRegistry` and `BindingStore` keep private configuration outside public
projections. Profile resolution performs local checks without credential reads,
provider probes or executable invocation. Binding snapshots use private files
addressed by opaque UUIDs; database rollback removes newly owned snapshots and
committed reclamation removes obsolete snapshots. Unknown, incomplete or damaged
mandatory binding formats fail before a call can start.

## Contracts Added or Changed

- Added project settings and retained operation models, associations and tables.
- Added version 1 private profile files and `harness-binding/v1` operation bindings.
- Added coherent selection changes, immutable logical admission, owned call
  lifecycle and bounded receipt/operation retention services.
- Null authoring selections preserve Codex-compatible executable overrides.
  Null ticket-proposal selections retain the distinct direct API default.
- PI-02, PI-10, PI-11 and PI-12 have selection, retention, ownership and capacity
  evidence at this Rails service boundary.

## Files of Interest

- `apps/web/app/models/project_harness_setting.rb` and `harness_operation.rb`:
  constrained state and safe public projections.
- `apps/web/app/services/harnesses/selection.rb` and `operation.rb`: serialized
  settings/admission and owned lifecycle.
- `apps/web/app/services/harnesses/profile_registry.rb` and `binding_store.rb`:
  private prepared profiles and retained references.
- `apps/web/test/support/harness_database_fixture.rb`: owned SQLite databases
  and separate-process race fixtures with bounded cleanup.
- `apps/web/test/services/specifications/database_rebuild_test.rb`: legacy and
  current source preservation through separate-database preparation.

## Validation

Development validation passed from the repository root:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/models/project_harness_setting_test.rb test/services/harnesses/selection_test.rb test/services/harnesses/operation_test.rb test/services/specifications/database_rebuild_test.rb)
```

Result: 18 tests, 214 assertions, zero failures, errors or skips; 11.62 seconds.
Changed Ruby syntax, ticket metadata and whitespace checks also passed during
implementation. Race fixtures use independent processes and SQLite connections.
All fixture databases, workspace files and child processes are owned by tests.

Final clean-HEAD checks are executed through `looper validate`; its retained
exact-commit evidence is authoritative before PR readiness and integration:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
scripts/agent/tickets/check.sh
git diff --name-only --diff-filter=ACMR origin/dev...HEAD -- '*.rb' | xargs -r -n 1 ruby -wc
git diff --check
```

Canonical PR #11 merged at `07b22440fc1ae520429382bf44cafaf135c871b5`.
Retained controller evidence for that exact commit passed all four commands
above: 567 Rails tests, 4,257 assertions, zero failures, errors or skips;
the Rails suite took 77.37 seconds.

## Risks and Follow-ups

This slice supplies the Rails selection and operation services. Existing
authoring consumers are connected to retained operations in the later approved
integration slice. Pi profiles fail readiness until verified containment is
delivered. Provider authentication, Pi execution and public settings controls
retain their assigned later-slice acceptance boundaries.
