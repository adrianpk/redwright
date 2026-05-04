# Cycle Plan: RedWright Heavy Interaction Sagas

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-heavy-interaction-sagas`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-04`
- updated: `2026-05-04`
- goal: `establish a robust, extensible heavy-interaction saga architecture in Rails, using Project Setup as the first reference saga without changing current external behavior`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-04-redwright-heavy-interaction-sagas-spec.md`

## Slice List

### Slice 1: Saga Contract Foundation

- status: `pending`
- branch: `fix/slice-1-heavy-interaction-saga-contract`
- pr_title: `feat(slice-1): add heavy interaction saga contract`
- objective: `introduce the common heavy-interaction saga contract, shared result shapes, and transport-neutral prompt intent primitives without forcing a generic workflow engine`
- tasks:
- [ ] `T1.1 define shared saga contract fields for state, stage, status, turns, effects, next_prompt_intent, terminal_reason, and metadata`
- [ ] `T1.2 add shared value objects or helpers for effect visibility, terminal reasons, and structured prompt intent`
- [ ] `T1.3 define structured step result primitives for status, data, effects, errors, and reconciliation`
- [ ] `T1.4 add focused tests for the shared contract shapes and serialization behavior`
- acceptance:
- `shared saga contract primitives exist in Rails application code`
- `effect visibility and prompt intent are structured rather than ad hoc`
- `step result primitives support both robust and lightweight usage`
- planned_commits:
- `feat(web): add heavy interaction saga contract`
- `feat(web): add saga result and prompt intent primitives`
- `test(web): cover heavy interaction saga contract`

### Slice 2: Project Setup Session Alignment

- status: `pending`
- branch: `fix/slice-2-project-setup-saga-alignment`
- pr_title: `feat(slice-2): align project setup with saga contract`
- objective: `align Project Setup persistence and state handling with the new saga contract while preserving current external command/query and Telegram behavior`
- tasks:
- [ ] `T2.1 map ProjectSetupSession and related state to the common saga contract fields`
- [ ] `T2.2 persist or expose normalized turns and terminal reasons through the shared contract`
- [ ] `T2.3 make questionnaire boundaries explicit so context collection remains distinct from materialization intent`
- [ ] `T2.4 add targeted tests for setup session contract projection, turn ordering, and terminal outcomes`
- acceptance:
- `Project Setup exposes the common saga contract without breaking current behavior`
- `questionnaire state and terminal outcomes are explicit in Rails-owned state`
- `turn and status semantics are deterministic`
- planned_commits:
- `feat(web): align project setup session with saga contract`
- `feat(web): expose project setup turns and terminal reasons`
- `test(web): cover project setup saga contract alignment`

### Slice 3: Materialization Pipeline Extraction

- status: `pending`
- branch: `fix/slice-3-project-setup-materialization-pipeline`
- pr_title: `feat(slice-3): extract project setup materialization pipeline`
- objective: `separate Project Setup context collection from materialization and express materialization as named step pipelines with one responsibility per step`
- tasks:
- [ ] `T3.1 extract Project Setup materialization steps into explicit pipeline units`
- [ ] `T3.2 make project, board, protocol, runtime container, ticket, and workspace creation steps return structured step results`
- [ ] `T3.3 ensure question-answer collection no longer performs materialization side effects directly`
- [ ] `T3.4 add targeted tests for step ordering, step results, and preserved current setup outcomes`
- acceptance:
- `Project Setup materialization is modeled as a named step pipeline`
- `questionnaire/context collection is separated from side-effectful materialization`
- `step results are structured and testable`
- planned_commits:
- `refactor(web): extract project setup materialization pipeline`
- `feat(web): add structured project setup step results`
- `test(web): cover project setup materialization pipeline`

### Slice 4: Failure, Reconciliation, and Observability

- status: `pending`
- branch: `fix/slice-4-saga-failure-reconciliation-observability`
- pr_title: `feat(slice-4): add saga reconciliation and observability`
- objective: `make partial failure, preserved context, reconciliation choices, and debug visibility explicit in saga execution paths`
- tasks:
- [ ] `T4.1 add failure and reconciliation state handling consistent with the shared saga contract`
- [ ] `T4.2 classify saga effects with public, internal, and debug visibility`
- [ ] `T4.3 expose preserved-context and reconciliation signals in Project Setup failure paths`
- [ ] `T4.4 add targeted tests for partial failure, preserved context, reconciliation metadata, and effect visibility`
- acceptance:
- `late materialization failure does not silently discard valuable setup context`
- `reconciliation signals are explicit and machine-readable`
- `observability includes step, effect, and failure visibility data`
- planned_commits:
- `feat(web): add saga reconciliation state handling`
- `feat(web): classify saga effects and debug visibility`
- `test(web): cover saga failure and reconciliation behavior`

### Slice 5: Adapter Rendering and Prompt Intent Integration

- status: `pending`
- branch: `fix/slice-5-saga-adapter-prompt-intent`
- pr_title: `feat(slice-5): integrate saga prompt intent rendering`
- objective: `route Project Setup prompting through structured next_prompt_intent so Telegram and web remain adapters over shared Rails behavior`
- tasks:
- [ ] `T5.1 replace remaining ad hoc next-question rendering dependencies with structured next_prompt_intent`
- [ ] `T5.2 adapt Telegram rendering to consume structured prompt intent while preserving current user-visible behavior`
- [ ] `T5.3 adapt web-facing setup surfaces to consume the same structured intent where applicable`
- [ ] `T5.4 add targeted tests for prompt intent shapes and adapter rendering parity`
- acceptance:
- `Project Setup prompting is driven by structured intent rather than transport-owned control flow`
- `Telegram and web remain renderers over the same Rails saga behavior`
- `current external prompting behavior remains stable unless explicitly changed`
- planned_commits:
- `feat(web): expose structured saga prompt intent`
- `feat(telegram): render project setup from saga prompt intent`
- `test(integration): cover saga prompt intent adapter parity`

### Slice 6: End-to-End Closure and Architecture Hardening

- status: `pending`
- branch: `fix/slice-6-heavy-interaction-sagas-e2e`
- pr_title: `feat(slice-6): close heavy interaction sagas cycle`
- objective: `validate the reference saga end to end, close residual gaps, and record the cycle outcome for future saga implementations`
- tasks:
- [ ] `T6.1 run targeted Rails and integration coverage for Project Setup through the refactored saga architecture`
- [ ] `T6.2 add end-to-end assertions for questionnaire progression, materialization, preserved failures, and final completion`
- [ ] `T6.3 publish cycle closure notes with residual risks and deferred follow-up items`
- [ ] `T6.4 update plan and tracker status to reflect completed slices and remaining future-saga open questions`
- acceptance:
- `Project Setup works through the refactored heavy-interaction saga architecture end to end`
- `the architecture is validated without changing existing external behavior by accident`
- `residual future-saga questions are documented instead of hidden in implementation`
- planned_commits:
- `test(integration): cover heavy interaction saga end to end`
- `docs(ops): close heavy interaction sagas cycle`

## Global Exit Criteria

- `Rails exposes a shared heavy-interaction saga contract suitable for future sagas`
- `Project Setup is aligned as the first reference saga under that contract`
- `questionnaire/context collection is separated from materialization`
- `materialization runs through named steps with structured results`
- `failure, reconciliation, and observability are explicit`
- `Telegram and web remain adapters over shared Rails saga behavior`
- `targeted and end-to-end validation preserve current external behavior while improving modularity`

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Ruby targeted tests must be run from repository root with `ruby -Itest <paths>` when non-Rails runtime code is touched.
- Repository coverage must be run from repository root.
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces.

## Non-Goals

- Do not introduce a generic workflow engine DSL in this cycle.
- Do not force every future workflow to use a questionnaire.
- Do not replace Rails RESTful surfaces with command naming where Rails semantics are already natural.
- Do not change Telegram copy or command/query response shapes unless a slice explicitly covers that behavior.
- Do not implement a generic shared `SagaRun` table in this cycle.
