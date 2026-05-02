# Cycle Tracker: RedWright Rails Core Command API and Project Setup Saga Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-rails-core-command-api-and-project-setup-saga`
- status: `awaiting_review`
- state: `post_slice_tuning`
- updated: `2026-05-02`
- active_slice: `Slice 9`
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

- status: `completed`
- branch: `fix/slice-6-rails-guided-alignment-questionnaire-artifacts`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/250`
- merge_target: `dev`
- last_sync_commit: `9356310`

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

- status: `completed`
- branch: `fix/slice-7-rails-document-ticket-board-command-api`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/251`
- merge_target: `dev`
- last_sync_commit: `fb14be7`

Tasks:

- [x] `T7.1 register document commands/queries for draft creation, draft update, promotion, and project document listing`
- [x] `T7.2 register ticket/board commands/queries for create, move, pick, attach documents, and board snapshot`
- [x] `T7.3 add API and service tests for project consistency, document lifecycle, board transitions, and ticket/document links`

Commits:

- [x] `e58e958 feat(web): add document command query api handlers`
- [x] `69d7856 feat(web): add ticket board command query api handlers`
- [x] `119e2e9 test(web): cover document ticket board command api behavior`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/services/document_management/command_query_handlers_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/services/board_workflow/command_query_handlers_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/controllers/api/v1/command_queries_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/controllers/tickets_controller_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.28)`

### Slice 8: Agent Runtime Bridge and Cross-Channel Parity

- status: `completed`
- branch: `fix/slice-8-agent-runtime-bridge-cross-channel-parity`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/252`
- merge_target: `dev`
- last_sync_commit: `bc08a86`

Tasks:

- [x] `T8.1 add Rails-to-runtime execution bridge contract for starting work from tickets`
- [x] `T8.2 persist runtime execution correlation on Rails tickets without duplicating board/application rules`
- [x] `T8.3 add cross-channel E2E tests for web/API/Telegram project setup and ticket execution parity`

Commits:

- [x] `a8d9655 feat(runtime): add rails ticket execution bridge contract`
- [x] `126dd9b feat(web): persist runtime execution correlation on tickets`
- [x] `9e52c1f test(integration): cover rails telegram runtime parity`

Validation:

- [x] `cd apps/web && bundle exec bin/rails test test/services/runtime_bridge/ticket_execution_bridge_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/services/board_workflow/command_query_handlers_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test test/controllers/api/v1/command_queries_controller_test.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb (pass)`
- [x] `cd apps/web && bundle exec bin/rails test (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.28)`

### Slice 9: Telegram Project New Quoted Saga Routing

- status: `awaiting_review`
- type: `post_slice_tuning`
- branch: `fix/slice-9-telegram-project-new-quoted-saga-routing`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/253`
- merge_target: `dev`
- last_sync_commit: `e95a33b`

Tasks:

- [x] `T9.1 capture post-slice tuning evidence for quoted Telegram project creation falling through to runtime`
- [x] `T9.2 route quoted /project new commands through the Rails setup adapter before planner/runtime dispatch`
- [x] `T9.3 add regression tests and coverage validation for the observed Telegram command shape`

Commits:

- [x] `cb202d3 fix(telegram): harden rails setup routing in foreground`
- [x] `4f486b2 test(telegram): cover quoted project setup routing`

Validation:

- [x] `bundle exec ruby bin/redwright trace show --dev trc-96f22d35 (pass, trace shows runtime project_new path for quoted /project new)`
- [x] `ruby -wc lib/redwright/telegram_project_setup_adapter.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_project_setup_adapter_test.rb (pass)`
- [x] `ruby -Itest test/redwright/telegram_runtime_handler_test.rb (pass)`
- [x] `bundle exec rake test:coverage from repository root (pass, coverage=91.29)`

## Coverage Guard

- baseline_coverage: `91.2`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `91.29`
- tuning_needed: `yes`
- tuning_evidence: `manual Telegram check showed a quoted /project new command with a description returning the legacy runtime response; runtime trace trc-96f22d35 confirmed planner/runtime project_new execution instead of Rails setup adapter handling`

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
- `2026-05-02` state=`slice_merged` slice=`Slice 6` note=`Slice 6 merged to dev via PR 250`
- `2026-05-02` state=`awaiting_review` slice=`Slice 7` note=`implemented Rails command/query APIs for document drafts, document promotion, project documents, ticket creation/update/move/pick, ticket-document linking, board snapshots, and project ticket listings`
- `2026-05-02` state=`slice_merged` slice=`Slice 7` note=`Slice 7 merged to dev via PR 251`
- `2026-05-02` state=`awaiting_review` slice=`Slice 8` note=`implemented Rails-to-runtime ticket execution bridge, persisted runtime execution correlation on tickets, routed Telegram ticket commands through Rails API, and added API/Telegram/runtime bridge parity coverage`
- `2026-05-02` state=`slice_merged` slice=`Slice 8` note=`Slice 8 merged to dev via PR 252`
- `2026-05-02` state=`completed` note=`completed all 8 planned slices for the Rails core command API and project setup saga cycle`
- `2026-05-02` state=`post_slice_tuning` slice=`Slice 9` note=`manual Telegram verification found quoted /project new commands falling through to runtime project creation instead of Rails setup saga routing`
- `2026-05-02` state=`awaiting_review` slice=`Slice 9` note=`quoted Telegram project creation commands are routed through the Rails setup adapter before planner/runtime dispatch, with targeted tests and coverage passing`
