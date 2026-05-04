# Cycle Tracker: RedWright Heavy Interaction Sagas

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-heavy-interaction-sagas`
- status: `planned`
- state: `planning`
- updated: `2026-05-04`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-04-redwright-heavy-interaction-sagas-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-04-redwright-heavy-interaction-sagas-spec.md`
- source_conversations:
  - `ops/specs/conv/2026-05-04-redwright-heavy-interaction-sagas-conv.md`
  - `ops/specs/conv/2026-05-04-redwright-heavy-interaction-sagas-conv-raw.md`

## Slice Progress

### Slice 1: Saga Contract Foundation

- status: `pending`
- branch: `fix/slice-1-heavy-interaction-saga-contract`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 define shared saga contract fields for state, stage, status, turns, effects, next_prompt_intent, terminal_reason, and metadata`
- [ ] `T1.2 add shared value objects or helpers for effect visibility, terminal reasons, and structured prompt intent`
- [ ] `T1.3 define structured step result primitives for status, data, effects, errors, and reconciliation`
- [ ] `T1.4 add focused tests for the shared contract shapes and serialization behavior`

Commits:

- [ ] `tbd feat(web): add heavy interaction saga contract`
- [ ] `tbd feat(web): add saga result and prompt intent primitives`
- [ ] `tbd test(web): cover heavy interaction saga contract`

Validation:

- [ ] `bundle exec bin/rails test <targeted heavy interaction saga contract paths>` (pending)

### Slice 2: Project Setup Session Alignment

- status: `pending`
- branch: `fix/slice-2-project-setup-saga-alignment`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 map ProjectSetupSession and related state to the common saga contract fields`
- [ ] `T2.2 persist or expose normalized turns and terminal reasons through the shared contract`
- [ ] `T2.3 make questionnaire boundaries explicit so context collection remains distinct from materialization intent`
- [ ] `T2.4 add targeted tests for setup session contract projection, turn ordering, and terminal outcomes`

Commits:

- [ ] `tbd feat(web): align project setup session with saga contract`
- [ ] `tbd feat(web): expose project setup turns and terminal reasons`
- [ ] `tbd test(web): cover project setup saga contract alignment`

Validation:

- [ ] `bundle exec bin/rails test <project setup session alignment paths>` (pending)

### Slice 3: Materialization Pipeline Extraction

- status: `pending`
- branch: `fix/slice-3-project-setup-materialization-pipeline`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 extract Project Setup materialization steps into explicit pipeline units`
- [ ] `T3.2 make project, board, protocol, runtime container, ticket, and workspace creation steps return structured step results`
- [ ] `T3.3 ensure question-answer collection no longer performs materialization side effects directly`
- [ ] `T3.4 add targeted tests for step ordering, step results, and preserved current setup outcomes`

Commits:

- [ ] `tbd refactor(web): extract project setup materialization pipeline`
- [ ] `tbd feat(web): add structured project setup step results`
- [ ] `tbd test(web): cover project setup materialization pipeline`

Validation:

- [ ] `bundle exec bin/rails test <project setup materialization pipeline paths>` (pending)

### Slice 4: Failure, Reconciliation, and Observability

- status: `pending`
- branch: `fix/slice-4-saga-failure-reconciliation-observability`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 add failure and reconciliation state handling consistent with the shared saga contract`
- [ ] `T4.2 classify saga effects with public, internal, and debug visibility`
- [ ] `T4.3 expose preserved-context and reconciliation signals in Project Setup failure paths`
- [ ] `T4.4 add targeted tests for partial failure, preserved context, reconciliation metadata, and effect visibility`

Commits:

- [ ] `tbd feat(web): add saga reconciliation state handling`
- [ ] `tbd feat(web): classify saga effects and debug visibility`
- [ ] `tbd test(web): cover saga failure and reconciliation behavior`

Validation:

- [ ] `bundle exec bin/rails test <saga failure and observability paths>` (pending)

### Slice 5: Adapter Rendering and Prompt Intent Integration

- status: `pending`
- branch: `fix/slice-5-saga-adapter-prompt-intent`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 replace remaining ad hoc next-question rendering dependencies with structured next_prompt_intent`
- [ ] `T5.2 adapt Telegram rendering to consume structured prompt intent while preserving current user-visible behavior`
- [ ] `T5.3 adapt web-facing setup surfaces to consume the same structured intent where applicable`
- [ ] `T5.4 add targeted tests for prompt intent shapes and adapter rendering parity`

Commits:

- [ ] `tbd feat(web): expose structured saga prompt intent`
- [ ] `tbd feat(telegram): render project setup from saga prompt intent`
- [ ] `tbd test(integration): cover saga prompt intent adapter parity`

Validation:

- [ ] `bundle exec bin/rails test <prompt intent and adapter parity paths>` (pending)

### Slice 6: End-to-End Closure and Architecture Hardening

- status: `pending`
- branch: `fix/slice-6-heavy-interaction-sagas-e2e`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 run targeted Rails and integration coverage for Project Setup through the refactored saga architecture`
- [ ] `T6.2 add end-to-end assertions for questionnaire progression, materialization, preserved failures, and final completion`
- [ ] `T6.3 publish cycle closure notes with residual risks and deferred follow-up items`
- [ ] `T6.4 update plan and tracker status to reflect completed slices and remaining future-saga open questions`

Commits:

- [ ] `tbd test(integration): cover heavy interaction saga end to end`
- [ ] `tbd docs(ops): close heavy interaction sagas cycle`

Validation:

- [ ] `bundle exec bin/rails test <heavy interaction saga e2e paths>` (pending)
- [ ] `bundle exec rake test:coverage` (pending)

## Event Log

- `2026-05-04` state=`planned` note=`promoted the heavy interaction sagas alignment work into a formal implementation cycle with Project Setup as the first reference saga and the curated/raw conversation artifacts preserved as implementation context`
