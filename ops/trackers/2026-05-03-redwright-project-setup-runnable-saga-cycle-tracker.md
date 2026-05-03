# Cycle Tracker: RedWright Project Setup Runnable Saga

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-setup-runnable-saga`
- status: `in_progress`
- state: `slice_3_reviewing`
- updated: `2026-05-03`
- active_slice: `Slice 3`
- active_task: `waiting for Slice 3 PR review`
- source_plan: `ops/plans/2026-05-03-redwright-project-setup-runnable-saga-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-setup-runnable-saga-spec.md`
- source_draft: `ops/specs/drafts/2026-05-03-redwright-project-setup-runnable-saga-draft.md`

## Slice Progress

### Slice 1: Setup LLM Traces and Semantic Slot Normalization

- status: `completed`
- branch: `fix/slice-1-setup-llm-traces-and-slot-normalization`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/263`
- merge_target: `dev`
- last_sync_commit: `ec38edf`

Tasks:

- [x] `T1.1 characterize missing setup LLM traces and raw slot persistence with focused tests`
- [x] `T1.2 instrument ProjectSetupPromptRenderer with Trace.llm_request and Trace.llm_response`
- [x] `T1.3 add semantic answer normalization contract with strict JSON output, deterministic fallback, and malformed-output handling`
- [x] `T1.4 integrate normalized slot updates into project setup advancement without losing raw answer audit data`
- [x] `T1.5 prevent prompt-confusion/meta answers from filling framework, language_runtime, libraries, or stack`
- [x] `T1.6 synthesize stack from normalized context instead of blindly deriving it from framework`
- [x] `T1.7 add tests for Go CLI answers, framework confusion, fallback normalization, and trace output`

Commits:

- [x] `7c74db2 feat(telegram): trace setup prompt rendering`
- [x] `fcb6eb0 feat(web): normalize project setup slot answers`
- [x] `2620a8f docs(ops): track slice 1 setup normalization`
- [x] `ec38edf docs(ops): record slice 1 pr`

Validation:

- [x] `ruby -wc lib/redwright/project_setup_prompt_renderer.rb && ruby -wc apps/web/app/models/project_setup_session.rb && ruby -wc apps/web/app/services/project_setup/context_loop_service.rb && ruby -wc apps/web/app/services/project_setup/semantic_answer_normalizer.rb` (pass)
- [x] `cd apps/web && bundle exec bin/rails test` (pass)
- [x] `bundle exec rake test:coverage` (pass, coverage 91.42)

### Slice 2: Explicit Setup Saga State and Query Surface

- status: `completed`
- branch: `fix/slice-2-project-setup-saga-state`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/264`
- merge_target: `dev`
- last_sync_commit: `3630d0f`

Tasks:

- [x] `T2.1 define persisted saga stage metadata compatible with existing ProjectSetupSession states`
- [x] `T2.2 add materialization and initial implementation result structures to setup session metadata`
- [x] `T2.3 expose structured saga state through Rails command/query responses`
- [x] `T2.4 update /project where to report setup stage, workspace, and runnable/planned status when available`
- [x] `T2.5 add tests for stage transitions, repeated completion, and API/query shape`

Commits:

- [x] `4bd86ea feat(web): add project setup saga state`
- [x] `ec2ef71 feat(web): persist project setup saga milestones`
- [x] `b810034 feat(web): expose project setup saga status`
- [x] `af81afa feat(telegram): render project setup saga status`
- [x] `dbc1f70 test(integration): cover setup saga query status`
- [x] `02194ff docs(ops): track slice 2 saga state`

Validation:

- [x] `ruby -wc apps/web/app/services/project_setup/saga_state.rb && ruby -wc apps/web/app/services/project_setup/guided_alignment_service.rb && ruby -wc apps/web/app/services/project_setup/context_loop_service.rb && ruby -wc apps/web/app/services/project_initialization/setup_session_runner.rb` (pass)
- [x] `cd apps/web && bundle exec bin/rails test` (pass)
- [x] `bundle exec rake test:coverage` (pass, coverage 91.43)

### Slice 3: Materialization Outcome and Planned Fallback

- status: `reviewing`
- branch: `fix/slice-3-project-setup-materialization-outcome`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `3630d0f`

Tasks:

- [x] `T3.1 extend workspace manifest with materialization status, initial implementation status, validation status, and linked ticket ids`
- [x] `T3.2 create or update README/setup notes during local workspace materialization`
- [x] `T3.3 create starter implementation ticket when the project is not yet runnable`
- [x] `T3.4 ensure unsupported stack/archetype combinations become materialized_planned with reason`
- [x] `T3.5 add idempotency tests for manifest, README, document, board, and starter ticket reconciliation`

Commits:

- [x] `df84d44 feat(web): record setup materialization outcomes`
- [x] `c3f82d2 feat(web): create planned setup fallback artifacts`
- [x] `38c2714 test(web): cover setup materialization fallback`

Validation:

- [x] `ruby -wc apps/web/app/services/project_setup/local_workspace_materializer.rb && ruby -wc apps/web/app/services/project_setup/context_loop_service.rb && ruby -wc apps/web/app/services/project_setup/saga_state.rb && ruby -wc lib/redwright/project_setup_prompt_renderer.rb` (pass)
- [x] `cd apps/web && bundle exec bin/rails test test/services/project_setup/context_loop_service_test.rb test/controllers/api/v1/command_queries_controller_test.rb test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb` (pass)
- [x] `ruby -Itest test/redwright/project_setup_prompt_renderer_test.rb test/redwright/telegram_project_setup_adapter_test.rb` (pass)
- [x] `cd apps/web && bundle exec bin/rails test` (pass)
- [x] `bundle exec rake test:coverage` (pass, coverage 91.44)

### Slice 4: Go CLI Initial Implementation Scaffold

- status: `planned`
- branch: `fix/slice-4-go-cli-initial-scaffold`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 add deterministic scaffold profile selection for Go CLI projects`
- [ ] `T4.2 generate go.mod, main entrypoint, README, and basic test when Go CLI context is detected`
- [ ] `T4.3 support optional urfave/cli dependency when libraries include it`
- [ ] `T4.4 run or record go test ./... validation depending on local toolchain availability`
- [ ] `T4.5 update Rails materialization data and manifest with runnable scaffold results`
- [ ] `T4.6 add filesystem and API tests for the Go CLI setup scenario`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 5: Telegram and Rails End-to-End Closure

- status: `planned`
- branch: `fix/slice-5-runnable-setup-e2e-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 add Telegram E2E for project new through Go CLI runnable or validation-skipped setup`
- [ ] `T5.2 add Telegram E2E for unsupported setup planned fallback`
- [ ] `T5.3 verify completion messages distinguish runnable, planned, and failed outcomes`
- [ ] `T5.4 run full Rails tests and repository coverage from canonical locations`
- [ ] `T5.5 publish cycle closure report with residual risks and tuning decision`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

## Coverage Guard

- baseline_coverage: `91.39`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `91.44`
- tuning_needed: `pending`
- tuning_evidence: `manual Telegram verification showed complete setup manifests but no runnable local project files, no visible setup LLM traces, and raw prompt-confusion text persisted as framework/stack context`

## Event Log

- `2026-05-03` state=`planned` note=`created runnable setup saga draft, conversation notes, promoted spec, cycle plan, and tracker after manual Telegram verification showed setup completion still ended at metadata/materialization instead of runnable or explicitly planned project state`
- `2026-05-03` state=`slice_1_reviewing` note=`rebased Slice 1 on origin/dev@85c9afb after typing-indicator and planning PRs were merged or closed, added setup prompt LLM traces and semantic slot normalization, and validated syntax, Rails tests, and repository coverage`
- `2026-05-03` state=`slice_1_reviewing` note=`opened Slice 1 PR #263 against dev with no reported conflicts`
- `2026-05-03` state=`slice_2_reviewing` note=`started from origin/dev@ec38edf after Slice 1 merge, added persisted setup saga state, exposed it through Rails command/query responses, rendered it in /project where, and validated full Rails tests plus repository coverage`
- `2026-05-03` state=`slice_2_reviewing` note=`opened Slice 2 PR #264 against dev with no reported conflicts`
- `2026-05-03` state=`slice_3_reviewing` note=`started from origin/dev@3630d0f after Slice 2 merge, added explicit planned materialization outcomes, fallback workspace README/setup notes, starter implementation ticket reconciliation, and validated syntax, targeted tests, full Rails tests, and repository coverage`
