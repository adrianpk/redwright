# Cycle Tracker: RedWright Heavy Interaction Sagas

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-heavy-interaction-sagas`
- status: `in_progress`
- state: `slice_3_pr_open`
- updated: `2026-05-04`
- active_slice: `Slice 3`
- active_task: `none`
- source_plan: `ops/plans/2026-05-04-redwright-heavy-interaction-sagas-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-04-redwright-heavy-interaction-sagas-spec.md`
- source_conversations:
  - `ops/specs/conv/2026-05-04-redwright-heavy-interaction-sagas-conv.md`
  - `ops/specs/conv/2026-05-04-redwright-heavy-interaction-sagas-conv-raw.md`

## Slice Progress

### Slice 1: Saga Contract Foundation

- status: `pr_open`
- branch: `fix/slice-1-heavy-interaction-saga-contract`
- PR: `#285 https://codeberg.org/adrianpk/redwright/pulls/285`
- merge_target: `dev`
- last_sync_commit: `231ca07`

Tasks:

- [x] `T1.1 define shared saga contract fields for state, stage, status, turns, effects, next_prompt_intent, terminal_reason, and metadata`
- [x] `T1.2 add shared value objects or helpers for effect visibility, terminal reasons, and structured prompt intent`
- [x] `T1.3 define structured step result primitives for status, data, effects, errors, and reconciliation`
- [x] `T1.4 add focused tests for the shared contract shapes and serialization behavior`

Commits:

- [x] `8d5af4a feat(web): add heavy interaction saga contract`
- [x] `4827af7 feat(web): add saga result and prompt intent primitives`
- [x] `231ca07 test(web): cover heavy interaction saga contract`

Validation:

- [x] `bundle exec bin/rails test test/services/heavy_interaction_sagas/effect_test.rb test/services/heavy_interaction_sagas/prompt_intent_test.rb test/services/heavy_interaction_sagas/step_result_test.rb test/services/heavy_interaction_sagas/contract_test.rb` (pass)

### Slice 2: Project Setup Session Alignment

- status: `pr_open`
- branch: `fix/slice-2-project-setup-saga-alignment`
- PR: `#286 https://codeberg.org/adrianpk/redwright/pulls/286`
- merge_target: `dev`
- last_sync_commit: `ec5c341`

Tasks:

- [x] `T2.1 map ProjectSetupSession and related state to the common saga contract fields`
- [x] `T2.2 persist or expose normalized turns and terminal reasons through the shared contract`
- [x] `T2.3 make questionnaire boundaries explicit so context collection remains distinct from materialization intent`
- [x] `T2.4 add targeted tests for setup session contract projection, turn ordering, and terminal outcomes`

Commits:

- [x] `debf6cf feat(web): align project setup session with saga contract`
- [x] `ec5c341 test(web): cover project setup saga contract alignment`

Validation:

- [x] `bundle exec bin/rails test test/models/project_setup_session_test.rb test/models/project_setup_turn_test.rb test/services/project_setup/state_machine_test.rb test/services/project_setup/context_loop_service_test.rb test/services/project_setup/guided_alignment_service_test.rb test/integration/project_setup_conversational_e2e_test.rb` (pass)

### Slice 3: Materialization Pipeline Extraction

- status: `pr_open`
- branch: `fix/slice-3-project-setup-materialization-pipeline`
- PR: `#287 https://codeberg.org/adrianpk/redwright/pulls/287`
- merge_target: `dev`
- last_sync_commit: `4052f6b`

Tasks:

- [x] `T3.1 extract Project Setup materialization steps into explicit pipeline units`
- [x] `T3.2 make project, board, protocol, runtime container, ticket, and workspace creation steps return structured step results`
- [x] `T3.3 ensure question-answer collection no longer performs materialization side effects directly`
- [x] `T3.4 add targeted tests for step ordering, step results, and preserved current setup outcomes`

Commits:

- [x] `1fbd6ce refactor(web): extract project setup materialization pipeline`
- [x] `4052f6b test(web): cover project setup materialization pipeline`

Validation:

- [x] `bundle exec bin/rails test test/services/project_setup/materialization_pipeline_test.rb test/services/project_setup/context_loop_service_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/services/project_setup/setup_runtime_bridge_integration_test.rb` (pass)

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
- `2026-05-04` state=`slice_1_implemented` note=`implemented shared heavy interaction saga contract primitives, effect visibility, structured prompt intent, structured step results, and focused Rails-side tests on fix/slice-1-heavy-interaction-saga-contract`
- `2026-05-04` state=`slice_1_pr_open` note=`opened Codeberg PR #285 from fix/slice-1-heavy-interaction-saga-contract into dev`
- `2026-05-04` state=`slice_2_implemented` note=`aligned Project Setup saga snapshot to the shared contract, exposed ordered turns and contract metadata, preserved current setup snapshot consumers, and validated the projection through model, service, and conversational integration tests on fix/slice-2-project-setup-saga-alignment`
- `2026-05-04` state=`slice_2_pr_open` note=`opened Codeberg PR #286 from fix/slice-2-project-setup-saga-alignment into dev`
- `2026-05-04` state=`slice_3_implemented` note=`extracted Project Setup materialization into an explicit named pipeline, preserved the existing step order and side effects, exposed structured materialization step results, and validated the behavior through direct pipeline, setup service, Telegram, conversational, and runtime-bridge coverage on fix/slice-3-project-setup-materialization-pipeline`
- `2026-05-04` state=`slice_3_pr_open` note=`opened Codeberg PR #287 from fix/slice-3-project-setup-materialization-pipeline into dev`
