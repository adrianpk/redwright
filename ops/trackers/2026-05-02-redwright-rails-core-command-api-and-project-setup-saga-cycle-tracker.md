# Cycle Tracker: RedWright Rails Core Command API and Project Setup Saga Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-rails-core-command-api-and-project-setup-saga`
- status: `in_progress`
- state: `awaiting_review`
- updated: `2026-05-02`
- active_slice: `Slice 6`
- active_task: `none`
- source_plan: `ops/plans/2026-05-02-redwright-rails-core-command-api-and-project-setup-saga-implementation-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-02-redwright-rails-core-command-api-and-project-setup-saga-spec.md`

## Slice Progress

### Slice 1: Rails Application Command/Query Foundation

- status: `completed`
- branch: `fix/slice-1-rails-command-query-foundation`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/245`
- merge_target: `dev`
- last_sync_commit: `f9371a2`

Tasks:

- [x] `T1.1 define Rails command/query envelope and result objects`
- [x] `T1.2 add Rails dispatcher with command/query registry and structured error handling`
- [x] `T1.3 add focused tests for envelope validation, dispatch success, and unsupported command/query errors`

Commits:

- [x] `fce076b feat(web): add rails command query envelope contract`
- [x] `edd0d23 feat(web): add rails command query dispatcher`
- [x] `0b0769f test(web): cover rails command query dispatch contract`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/services/command_query (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.2)`

### Slice 2: Project Setup Session Persistence and State Machine

- status: `completed`
- branch: `fix/slice-2-project-setup-session-state-machine`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/246`
- merge_target: `dev`
- last_sync_commit: `aebe21c`

Tasks:

- [x] `T2.1 add ProjectSetupSession and ProjectSetupTurn migrations/models`
- [x] `T2.2 add setup state machine service with allowed transitions and terminal outcomes`
- [x] `T2.3 add model and service tests for setup state, turn ordering, cancellation, and invalid transitions`

Commits:

- [x] `65ed479 feat(web): add project setup session persistence`
- [x] `a0dc5d9 feat(web): add project setup state machine`
- [x] `393667e test(web): cover project setup state persistence and transitions`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/models/project_setup_session_test.rb test/models/project_setup_turn_test.rb test/services/project_setup/state_machine_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.2)`

### Slice 3: Unified Rails Project Initialization Services

- status: `completed`
- branch: `fix/slice-3-unified-rails-project-initialization-services`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/247`
- merge_target: `dev`
- last_sync_commit: `a928421`

Tasks:

- [x] `T3.1 adapt ProjectInitialization services to create or advance ProjectSetupSession records`
- [x] `T3.2 wire ProjectsController to the unified service path while preserving Rails HTML/Turbo ergonomics`
- [x] `T3.3 add web/service tests proving repository-first setup, opt-in/out, cancellation, and no hidden partial state`

Commits:

- [x] `742c200 feat(web): bind project initialization to setup sessions`
- [x] `0c1896c feat(web): route project creation form through unified setup service`
- [x] `a6bb7bd test(web): cover unified project initialization setup flow`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/services/project_initialization/setup_session_runner_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/controllers/projects_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.2)`

### Slice 4: Rails Project Setup Command API

- status: `completed`
- branch: `fix/slice-4-rails-project-setup-command-api`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/248`
- merge_target: `dev`
- last_sync_commit: `3d57b63`

Tasks:

- [x] `T4.1 add /api/v1 command/query routes, controller base, request id handling, and actor context`
- [x] `T4.2 register project setup commands and queries in the Rails dispatcher`
- [x] `T4.3 add API integration tests for start, advance, cancel, status, and project listing`

Commits:

- [x] `ba69969 feat(web): add rails command query api namespace`
- [x] `207964d feat(web): expose project setup commands through rails api`
- [x] `808ee08 test(web): cover project setup command api`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/services/command_query test/controllers/api/v1/command_queries_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.2)`

### Slice 5: Telegram Project Setup Adapter Over Rails API

- status: `completed`
- branch: `fix/slice-5-telegram-project-setup-rails-api-adapter`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/249`
- merge_target: `dev`
- last_sync_commit: `cf26501`

Tasks:

- [x] `T5.1 add Telegram Rails API client/adapter for command/query envelopes`
- [x] `T5.2 route /project new, project setup replies, /project list, and /project where through Rails API where applicable`
- [x] `T5.3 add Telegram handler tests proving multi-turn setup and no runtime-only project creation for new projects`

Commits:

- [x] `62a1332 feat(telegram): add rails command api adapter`
- [x] `c49522f feat(telegram): route project setup commands through rails api`
- [x] `3874752 test(telegram): cover rails-backed project setup flow`
- [x] `0449e3d test(telegram): harden rails project setup adapter coverage`

Validation:

- [x] `ruby -Itest test/redwright/telegram_rails_api_client_test.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_runtime_handler_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.28)`

### Slice 6: Rails-Governed Guided Alignment and Questionnaire Artifacts

- status: `awaiting_review`
- branch: `fix/slice-6-rails-guided-alignment-questionnaire-artifacts`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `cf26501`

Tasks:

- [x] `T6.1 implement one-question-per-turn setup alignment service using setup turns`
- [x] `T6.2 persist normalized alignment output into project attributes and/or document artifacts per lifecycle rules`
- [x] `T6.3 add tests for bounded turns, opt-out, turn reuse, artifact creation, and terminal outcomes`

Commits:

- [x] `13deb12 feat(web): add rails guided alignment setup service`
- [x] `3c9035e feat(web): persist setup alignment artifacts`
- [x] `53e8145 test(web): cover guided alignment setup artifacts`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/services/project_setup/guided_alignment_service_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/controllers/api/v1/command_queries_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/controllers/projects_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/services/project_setup/state_machine_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/services/project_initialization/setup_session_runner_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.28)`

### Slice 7: Rails Document, Ticket, and Board Command API

- status: `pending`
- branch: `fix/slice-7-rails-document-ticket-board-command-api`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 register document commands/queries for draft creation, draft update, promotion, and project document listing`
- [ ] `T7.2 register ticket/board commands/queries for create, move, pick, attach documents, and board snapshot`
- [ ] `T7.3 add API and service tests for project consistency, document lifecycle, board transitions, and ticket/document links`

Commits:

- [ ] `feat(web): add document command query api handlers`
- [ ] `feat(web): add ticket board command query api handlers`
- [ ] `test(web): cover document ticket board command api behavior`

Validation:

- [ ] `targeted Rails document/ticket/board API tests (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending before slice closure)`

### Slice 8: Agent Runtime Bridge and Cross-Channel Parity

- status: `pending`
- branch: `fix/slice-8-agent-runtime-bridge-cross-channel-parity`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T8.1 add Rails-to-runtime execution bridge contract for starting work from tickets`
- [ ] `T8.2 persist runtime execution correlation on Rails tickets without duplicating board/application rules`
- [ ] `T8.3 add cross-channel E2E tests for web/API/Telegram project setup and ticket execution parity`

Commits:

- [ ] `feat(runtime): add rails ticket execution bridge contract`
- [ ] `feat(web): persist runtime execution correlation on tickets`
- [ ] `test(integration): cover rails telegram runtime parity`

Validation:

- [ ] `targeted bridge/integration tests (pending)`
- [ ] `bundle exec rake test:coverage from repository root (pending before cycle closure)`

## Coverage Guard

- baseline_coverage: `91.2`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`

## Event Log

- `2026-05-02` state=`planning` note=`created formal spec, implementation plan, and tracker for Rails core command API plus project setup saga cycle`
- `2026-05-02` state=`awaiting_review` slice=`Slice 1` note=`implemented Rails command/query envelope, result, registry, dispatcher, structured error handling, and focused service coverage`
- `2026-05-02` state=`slice_merged` slice=`Slice 1` note=`Slice 1 merged to dev via PR 245`
- `2026-05-02` state=`slice_merged` slice=`Slice 2` note=`Slice 2 merged to dev via PR 246`
- `2026-05-02` state=`awaiting_review` slice=`Slice 3` note=`implemented unified project initialization setup runner, routed ProjectsController through setup sessions, and added service/controller coverage for opt-in, opt-out, cancellation, ambiguity, and failed partial state`
- `2026-05-02` state=`slice_merged` slice=`Slice 3` note=`Slice 3 merged to dev via PR 247`
- `2026-05-02` state=`awaiting_review` slice=`Slice 4` note=`implemented Rails API command/query namespace, project setup command/query handlers, and integration coverage for start, advance, cancel, status, and project listing`
- `2026-05-02` state=`slice_merged` slice=`Slice 4` note=`Slice 4 merged to dev via PR 248`
- `2026-05-02` state=`awaiting_review` slice=`Slice 5` note=`implemented Telegram Rails API client/adapter, routed Telegram project setup commands and replies through Rails API when configured, and added coverage proving no runtime-only project creation for Rails-backed project setup`
- `2026-05-02` state=`slice_merged` slice=`Slice 5` note=`Slice 5 merged to dev via PR 249`
- `2026-05-02` state=`awaiting_review` slice=`Slice 6` note=`implemented Rails-governed guided alignment turns, persisted project attributes and a guided alignment draft artifact, and added coverage for bounded turns, opt-out, request replay, artifact creation, and terminal outcomes`
