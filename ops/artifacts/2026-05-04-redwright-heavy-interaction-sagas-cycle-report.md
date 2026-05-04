# Cycle Report: RedWright Heavy Interaction Sagas

## Metadata

- cycle_id: `cycle-2026-05-04-redwright-heavy-interaction-sagas`
- status: `implemented_pending_review`
- date: `2026-05-04`
- source_plan: `ops/plans/2026-05-04-redwright-heavy-interaction-sagas-cycle-plan.md`
- source_tracker: `ops/trackers/2026-05-04-redwright-heavy-interaction-sagas-cycle-tracker.md`
- source_spec: `ops/specs/specs/2026-05-04-redwright-heavy-interaction-sagas-spec.md`

## Summary

This cycle established a shared heavy-interaction saga contract in Rails and aligned Project Setup to it as the first reference saga.

Project Setup now exposes structured saga state, named materialization steps, explicit failure and reconciliation outcomes, visibility-classified effects, and structured prompt intents consumed by both the web API and the Telegram adapter.

## Delivered Slices

### Slice 1: Saga Contract Foundation

- branch: `fix/slice-1-heavy-interaction-saga-contract`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/285`
- status: `merged`

Delivered behavior:

- Rails owns a shared heavy-interaction saga contract shape.
- Saga effects have explicit visibility classes.
- Prompt intent and step result primitives are structured and serializable.
- Future sagas can reuse the same contract without adopting a workflow DSL.

### Slice 2: Project Setup Session Alignment

- branch: `fix/slice-2-project-setup-saga-alignment`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/286`
- status: `merged`

Delivered behavior:

- Project Setup projects the shared saga contract through persisted session state.
- Ordered turns and terminal reasons are explicit in Rails-owned state.
- Questionnaire boundaries remain separate from materialization semantics.
- Existing command/query and setup consumers continue to read a deterministic snapshot.

### Slice 3: Materialization Pipeline Extraction

- branch: `fix/slice-3-project-setup-materialization-pipeline`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/287`
- status: `merged`

Delivered behavior:

- Project Setup materialization is modeled as a named step pipeline.
- Context collection no longer hides materialization side effects inside ad hoc control flow.
- Step ordering and outputs are explicit and testable.
- Materialization metadata is preserved in setup session state.

### Slice 4: Failure, Reconciliation, and Observability

- branch: `fix/slice-4-saga-failure-reconciliation-observability`
- PR: `integrated to dev without a stable PR handoff`
- status: `merged_in_dev`

Delivered behavior:

- Failure and `needs_reconciliation` are explicit saga outcomes.
- Reconciliation metadata and preserved setup context remain available after failure.
- Saga effects distinguish `public`, `internal`, and `debug` visibility.
- Materialization step metadata is preserved as debug-visible observability data.

### Slice 5: Adapter Rendering and Prompt Intent Integration

- branch: `fix/slice-5-saga-adapter-prompt-intent`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/290`
- status: `merged`

Delivered behavior:

- Structured prompt intents now cover setup slot collection, repository clarification, and guided alignment.
- API `next_prompt` values are derived from the structured intent rather than transport-owned pending-question fallbacks.
- Telegram rendering consumes the same structured intent metadata while preserving user-visible prompt copy.
- Adapter parity is exercised through Rails-side and Ruby-side tests.

### Slice 6: End-to-End Closure and Architecture Hardening

- branch: `fix/slice-6-heavy-interaction-sagas-e2e`
- PR: `pending`
- status: `reviewing`

Delivered behavior:

- End-to-end coverage now includes a reconciled failure path with preserved saga context.
- Targeted saga validation was rerun after the full contract integration.
- The full Rails suite and repository coverage were rerun to close the cycle with broader confidence.
- Closure artifacts record residual risks and deferred follow-up items explicitly.

## Validation

- `cd apps/web && bundle exec bin/rails test test/services/project_initialization/orchestrator_test.rb test/services/project_initialization/setup_session_runner_test.rb test/services/project_setup/guided_alignment_service_test.rb test/controllers/api/v1/command_queries_controller_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb` (pass)
- `cd apps/web && bundle exec bin/rails test test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb test/controllers/api/v1/command_queries_controller_test.rb test/services/project_initialization/setup_session_runner_test.rb test/services/project_setup/context_loop_service_test.rb test/services/project_setup/guided_alignment_service_test.rb test/services/project_setup/materialization_pipeline_test.rb test/services/project_setup/setup_runtime_bridge_integration_test.rb test/services/heavy_interaction_sagas/contract_test.rb test/services/heavy_interaction_sagas/effect_test.rb test/services/heavy_interaction_sagas/prompt_intent_test.rb test/services/heavy_interaction_sagas/step_result_test.rb` (pass)
- `cd apps/web && bundle exec bin/rails test` (pass)
- `ruby -Ilib:test test/redwright/project_setup_prompt_renderer_test.rb test/redwright/telegram_project_setup_adapter_test.rb test/redwright/telegram_runtime_handler_test.rb` (pass)
- `bundle exec rake test:coverage` (pass, coverage 91.58)

## Coverage

- baseline_coverage: `91.46`
- final_coverage: `91.58`
- result: `improved`

## Residual Risks

- Slice 4 was integrated into `dev` without a stable PR handoff. The code is validated and present in `dev`, but the publication workflow for that slice was not clean.
- The shared saga contract is proven only through Project Setup in this cycle. Additional long-running workflows may still surface pressure for different persistence or step orchestration patterns.
- Prompt rendering still depends on per-intent metadata text for some non-slot questions. That is intentional and keeps adapter behavior stable, but a larger prompt catalog may eventually deserve stronger centralization.
- Failure and reconciliation are explicit in the setup saga snapshot, but there is still no generic operator workflow for resolving every future saga reconciliation path.

## Deferred Follow-Up Items

- Normalize the publication workflow after the Slice 4 incident so cycle trackers and PR references stay trustworthy.
- Apply the shared saga contract to additional heavyweight interactions beyond Project Setup.
- Decide whether non-slot prompt intents should move into a broader catalog instead of relying on inline metadata text.
- Revisit whether future sagas need shared persistence helpers beyond the current `ProjectSetupSession` reference implementation.

## Tuning Decision

No additional tuning slice is required before review. The cycle goal is covered: Project Setup now acts as a validated reference implementation for the heavy-interaction saga architecture, with explicit contract state, step pipelines, failure observability, adapter parity, and end-to-end coverage.
