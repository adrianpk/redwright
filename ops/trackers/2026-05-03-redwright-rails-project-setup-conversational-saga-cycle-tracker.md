# Cycle Tracker: RedWright Rails Project Setup Conversational Saga

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-rails-project-setup-conversational-saga`
- status: `in_progress`
- state: `pr_creation_blocked`
- updated: `2026-05-03`
- active_slice: `Slice 1`
- active_task: `open Slice 1 PR when Codeberg pull request API recovers`
- source_plan: `ops/plans/2026-05-03-redwright-rails-project-setup-conversational-saga-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`

## Slice Progress

### Slice 1: Setup Context Slot Model, Repository Decoupling, and Minimal Conversational Trunk

- status: `ready_pr_blocked`
- branch: `fix/slice-1-project-setup-context-slots`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `0619204`

Tasks:

- [x] `T1.1 characterize current repository-first behavior with Rails and Telegram tests`
- [x] `T1.2 add canonical setup context slot helpers and semantic prompt intent metadata for ProjectSetupSession`
- [x] `T1.3 change StartProjectSetup payload handling so project name and description are not mapped to repository input`
- [x] `T1.4 allow repository input to be absent or skipped without invalidating setup start`
- [x] `T1.5 add tests for empty start, name-only start, quoted name with description, and repository URL input`
- [x] `T1.6 preserve Ariadne conversational workflow source in ignored ops/tmp working area`
- [x] `T1.7 add compact trunk slots for project type, language/runtime, framework, and libraries without asking stack as a mixed prompt`
- [x] `T1.8 implement setup context answer progression plus /skip, /done, and /cancel`
- [x] `T1.9 render Telegram setup prompts through the configured LLM renderer with deterministic fallback`
- [x] `T1.10 materialize completed setup into Project, setup attributes, setup summary document, and default board`

Commits:

- [x] `1758ed9 feat(web): add project setup context slot metadata`
- [x] `7a51dd4 feat(web): decouple project setup start from repository input`
- [x] `68bc824 feat(telegram): stop mapping project names to repository input`
- [x] `2270d10 feat(web): persist setup prompt intent`
- [ ] `feat(web): add project setup context loop`
- [ ] `feat(telegram): render project setup prompts`
- [ ] `docs(ops): track slice 1 conversational trunk extension`

Validation:

- [x] `ruby -wc lib/redwright/telegram_project_setup_adapter.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/models/project_setup_session_test.rb test/services/project_initialization/command_test.rb test/services/project_initialization/orchestrator_test.rb test/services/project_initialization/setup_session_runner_test.rb test/services/project_setup/context_loop_service_test.rb test/controllers/api/v1/command_queries_controller_test.rb (pass)`
- [x] `ruby -wc lib/redwright/project_setup_prompt_renderer.rb (pass)`
- [x] `ruby -Itest test/redwright/project_setup_prompt_renderer_test.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_runtime_handler_test.rb (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.38)`

### Slice 2: Deterministic Setup Question Loop Controls

- status: `pending`
- branch: `fix/slice-2-project-setup-question-loop-controls`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 add setup question intent selector for canonical slots and blocking/recommended/optional policy`
- [ ] `T2.2 implement AdvanceProjectSetup handling for normal answers and slot normalization`
- [ ] `T2.3 implement /skip and /done over Rails setup commands`
- [ ] `T2.4 preserve cancellation semantics and no-residue behavior before project creation`
- [ ] `T2.5 add tests for question progression, no-reask behavior, skip, done, cancel, and repeated ambiguity`

Commits:

- [ ] `feat(web): add project setup question intent selector`
- [ ] `feat(web): add project setup loop controls`
- [ ] `test(web): cover project setup conversational controls`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/services/project_setup (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending)`

### Slice 3: Human Telegram Rendering for Project Setup

- status: `pending`
- branch: `fix/slice-3-telegram-project-setup-human-rendering`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add Telegram project setup response renderer that asks the configured LLM to render semantic prompt intent as localized human text`
- [ ] `T3.2 hide raw state/session/trace details by default and keep debug/trace formatting opt-in`
- [ ] `T3.3 route setup replies, /skip, /done, and /cancel through the renderer`
- [ ] `T3.4 add Telegram adapter tests for sparse, rich, skipped, completed, and cancelled setup flows`

Commits:

- [ ] `feat(telegram): render human project setup prompts`
- [ ] `test(telegram): cover project setup rendering modes`

Validation:

- [ ] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb (pending)`
- [ ] `ruby -Itest test/redwright/telegram_runtime_handler_test.rb (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending)`

### Slice 4: Setup Completion and Rails Artifact Materialization

- status: `pending`
- branch: `fix/slice-4-project-setup-artifact-materialization`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 create project from canonical setup context with repository absent or present`
- [ ] `T4.2 materialize setup context into ProjectAttribute rows with weights and sources`
- [ ] `T4.3 write setup summary Document from canonical answers`
- [ ] `T4.4 ensure default board structure exists after setup completion`
- [ ] `T4.5 add tests for materialization, idempotency, and no duplicate artifacts on repeated request ids`

Commits:

- [ ] `feat(web): materialize project setup context artifacts`
- [ ] `test(web): cover setup completion materialization`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/services/project_setup test/models (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending)`

### Slice 5: Agent Workflow and Runtime Container Context Bridge

- status: `pending`
- branch: `fix/slice-5-project-setup-agent-workflow-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 define runtime container profile defaults and project attribute keys`
- [ ] `T5.2 expose setup-derived stack/framework/library/context values to runtime bridge inputs`
- [ ] `T5.3 create or update starter tickets when setup context requests agent workflow`
- [ ] `T5.4 add integration tests from setup completion to ticket execution bridge input`

Commits:

- [ ] `feat(runtime): pass project setup context to ticket execution bridge`
- [ ] `feat(web): seed setup-driven starter workflow tickets`
- [ ] `test(integration): cover setup context runtime bridge parity`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test test/services/runtime_bridge test/services/board_workflow (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending)`

### Slice 6: End-to-End Regression Closure

- status: `pending`
- branch: `fix/slice-6-project-setup-conversational-e2e`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 add Rails API end-to-end scenarios for sparse, rich, skip, done, cancel, and repository-backed setup`
- [ ] `T6.2 add Telegram simulated ingress scenarios for the same setup matrix`
- [ ] `T6.3 run full Rails tests and repository coverage from canonical locations`
- [ ] `T6.4 publish cycle closure notes with residual risks and tuning decision`

Commits:

- [ ] `test(integration): add project setup conversational e2e matrix`
- [ ] `docs(ops): close project setup conversational saga cycle`

Validation:

- [ ] `cd apps/web && bundle exec bin/rails test (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending)`

## Event Log

- `2026-05-03` state=`planning` note=`created draft, conversation notes, promoted spec, cycle plan, and tracker for Rails project setup conversational saga after manual Telegram verification showed repository-first behavior still exposed to users`
- `2026-05-03` state=`awaiting_review` slice=`Slice 1` note=`implemented repository-independent project setup start, canonical setup context slots, and Telegram payload routing that no longer maps project names to repository input`
- `2026-05-03` state=`awaiting_review` slice=`Slice 1` note=`corrected setup prompt handling to persist semantic prompt intent for LLM-localized rendering instead of treating fixed question text as the contract`
- `2026-05-03` state=`in_progress` slice=`Slice 1` note=`preserved Ariadne conversational workflow source under ignored ops/tmp and extended slice 1 to close the minimum Telegram setup loop instead of deferring renderer, controls, and materialization`
- `2026-05-03` state=`pr_creation_blocked` slice=`Slice 1` note=`branch pushed with passing validation, but Codeberg pull request creation POST timed out through tea, tea api, and direct authenticated API; open PR list was checked afterward and no PR was created`
