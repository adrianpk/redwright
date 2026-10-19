# Slice 1: Validated Codex Structured Calls

Status: reviewing
Delivery set: pi-harness
Plan: [Pi Harness plan](../../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)
Tracker: [Pi Harness tracker](../../../trackers/2026-10-19-redwright-pi-harness-cycle-tracker.md)
Branch: `fix/slice-1-pi-validated-codex`
PR: [#10](https://forge.adrianpk.com/adrianpk/redwrigh/pulls/10)

## Purpose

Preserve existing Codex authoring through a shared Rails call boundary that
validates the entire host-owned output schema before domain publication.

## Delivered Behavior

- Specifications, slicing, dump curation and protocol references use one Codex
  adapter with their original instructions and executable overrides.
- Draft 2020-12 validation rejects nested type, required-field, enum, cardinality
  and unknown-property violations. Local schema references work; external
  resolution and default insertion are disabled.
- Invalid JSON, failed processes, missing output, oversized results and deadlines
  cannot return a successful structured value. Existing nonblank domain checks,
  file revisions, locks, statuses and publication remain with their callers.
- Requests retain the 180-second default and enforce a 1 MiB encoded request,
  64 KiB schema and 2 MiB result ceiling. Stricter result limits are preserved.

## Implementation Notes

`Harnesses::Request` snapshots the prompt and schema. `StructuredCall` validates
the contract and resolves references before invoking an adapter, then parses and
validates its final output. `CodexAdapter` preserves the read-only, ephemeral
command and final-file protocol; a bounded file read prevents a growing result
from bypassing the byte ceiling. Timeouts stop and reap the owned process group.
Provider/model observations and usage remain unknown when Codex supplies none.

The existing feature harnesses own instructions and semantic checks. Their
generators and file stores retain publication authority. No caller imports Pi
or requires its executable to use Codex.

## Contracts Added or Changed

- Added `Harnesses::Request`, `Result`, `Error`, `StructuredCall` and `CodexAdapter`.
- Added the approved Rails dependency `json_schemer` 2.5.0 and its locked dependencies.
- Preserved the `generate(context:, workspace:)` interface and Codex-compatible
  executable override semantics. Unknown harness names fail before invocation.
- PI-01 and PI-03 have Codex-only subprocess evidence. PI-05 has nested host-schema
  evidence. Artifact preservation relevant to PI-04 is proven for Codex here;
  Pi publication acceptance belongs to its later approved slices.

## Files of Interest

- `apps/web/app/services/harnesses/`: shared request, validation and adapter boundary.
- `apps/web/app/services/specifications/harness.rb`: existing consumer facade.
- `apps/web/test/services/harnesses/structured_call_test.rb`: host contract and real subprocess cases.
- Existing generator, feature workflow, dump curation and protocol document tests:
  success, rejection and file/status preservation across all four consumers.

## Validation

Development validation passed from the repository root:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test test/services/harnesses/structured_call_test.rb test/services/specifications/generator_test.rb test/services/specifications/feature_workflow_test.rb test/services/dumps/curation_test.rb test/services/project_protocols/documents_test.rb)
```

Result: 35 tests, 389 assertions, zero failures, errors or skips; 8.99 seconds.
Changed Ruby syntax, ticket metadata and whitespace checks also passed during
task implementation. Real executable fixtures require no model or network call.
The timeout fixture verifies reaping and preservation of an unrelated owned process.

Final clean-HEAD checks are executed through `looper validate`; its retained
exact-commit evidence is authoritative before PR readiness and integration:

```sh
(cd apps/web && RAILS_ENV=test bundle exec rails test)
scripts/agent/tickets/check.sh
git diff --name-only --diff-filter=ACMR origin/dev...HEAD -- '*.rb' | xargs -r -n 1 ruby -wc
git diff --check
```

## Risks and Follow-ups

This slice establishes the Codex/host contract. Profile persistence, shared
cross-process admission, Pi transport, Linux containment and live Pi acceptance
remain assigned to the subsequent approved slices. The external controller owns
integration into `dev` and the final delivery-set gate.
