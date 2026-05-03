# Cycle Tracker: RedWright Project Setup Completion Tuning

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-setup-completion-tuning`
- status: `in_progress`
- state: `slice_1_ready_for_pr`
- updated: `2026-05-03`
- active_slice: `Slice 1`
- active_task: `T1.5`
- source_plan: `ops/plans/2026-05-03-redwright-project-setup-completion-tuning-cycle-plan.md`
- source_draft: `ops/tmp/drafts/2026-05-03-redwright-project-setup-corrective-slice-draft.md`

## Slice Progress

### Slice 1: Project Setup Completion Materialization

- status: `ready_for_pr`
- branch: `fix/slice-1-project-setup-completion-materialization`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `2f8f6d1`

Tasks:

- [x] `T1.1 characterize completion replay and all-slot materialization expectations with Rails service and API coverage`
- [x] `T1.2 harden setup completion idempotency so repeated completion requests reuse existing materialized state instead of failing or duplicating records`
- [x] `T1.3 ensure every collected canonical slot is materialized into ProjectAttribute rows and completion metadata, including repository, runtime container profile, and agent workflow mode when present`
- [x] `T1.4 ensure Project, setup summary Document, default Board, and optional starter workflow Ticket are reused or reconciled on replay`
- [x] `T1.5 update tracker with commits and validation outcomes before opening the PR`

Commits:

- [x] `e6206e1 feat(web): harden setup completion materialization`

Validation:

- [x] `ruby -wc apps/web/app/services/project_setup/context_loop_service.rb (pass)`
- [x] `ruby -wc apps/web/app/services/project_setup/command_query_handlers.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/services/project_setup/context_loop_service_test.rb test/controllers/api/v1/command_queries_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/integration/project_setup_conversational_e2e_test.rb test/integration/project_setup_telegram_e2e_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.38)`

### Slice 2: Workspace, Manifest, and Telegram Closure

- status: `planned`
- branch: `fix/slice-2-project-setup-workspace-and-telegram-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 define repository-local workspace path mapping for local project setup without breaking runtime path assumptions`
- [ ] `T2.2 create or reconcile _workspace/Projects/<slug> when local setup completes`
- [ ] `T2.3 write an idempotent .redwright/manifest.yml from the collected setup slots`
- [ ] `T2.4 expose completion data so Telegram can state what was created and where`
- [ ] `T2.5 harden Telegram prompt rendering policy so default output avoids colon shortcode tokens while preserving LLM-localized wording`
- [ ] `T2.6 add simulated Telegram E2E coverage from conversation to Rails state, workspace directory, manifest, and shortcode-free completion message`
- [ ] `T2.7 publish cycle closure notes with residual risks and tuning decision`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

## Coverage Guard

- baseline_coverage: `91.38`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `pending`
- tuning_needed: `yes`
- tuning_evidence: `manual Telegram verification showed project setup completion creating Rails state without a matching _workspace/Projects directory and showed non-rendering colon shortcode artifacts in prompt text`

## Event Log

- `2026-05-03` state=`planned` note=`created a two-slice corrective tuning cycle from the ignored ops/tmp working draft after the previous conversational saga cycle was closed and aligned to main`
- `2026-05-03` state=`ready_for_pr` slice=`Slice 1` note=`hardened setup completion materialization with all-slot Rails state coverage, materialized setup metadata, idempotent board/column reconciliation, request-id completion replay, and terminal /done reuse through the command API`
