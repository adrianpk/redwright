# Cycle Tracker: RedWright Kanban-Centric Rails MVP

## Metadata

- cycle_id: `rw-2026-04-30-kanban-centric-rails-mvp`
- status: `in_progress`
- state: `planning`
- updated: `2026-04-30`
- active_slice: `slice-2`
- active_task: `T2.1`

## Slice Progress

### Slice 1: Spec and Contract Realignment

- status: `completed`
- branch: `dev`
- PR: `n/a`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T1.1 supersede dual-runtime and dual-bot ADR decisions`
- [x] `T1.2 define unified single_ticket/loop execution semantics`
- [x] `T1.3 define ticket metadata extensions for priority and time tracking`
- [x] `T1.4 publish open questions for future multi-agent pool topology`

Commits:

- [ ] `<sha> docs(architecture): realign kanban-centric runtime ADR and contracts`

Validation:

- [ ] `docs coherence review across ADR-003/004/005/008 and runtime reference contracts`

### Slice 2: Rails App Scaffolding and Repo Materialization

- status: `pending`
- branch: `feat/slice-2-rails-app-scaffold-and-repo-materialization`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 create apps/web rails app skeleton with baseline auth`
- [ ] `T2.2 wire project structure boundaries and update repository map`
- [ ] `T2.3 add smoke tests for rails boot and integration stubs`

Commits:

- [ ] `<sha> feat(web): scaffold rails kanban app baseline`
- [ ] `<sha> test(web): add rails boot and boundary smoke coverage`

Validation:

- [ ] `<cmd> rails app boot check`
- [ ] `<cmd> rails smoke tests`

### Slice 3: Ticket Domain and Kanban Board MVP

- status: `in_review`
- branch: `feat/slice-3-ticket-domain-and-kanban-mvp`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `00720b3`

Tasks:

- [x] `T3.1 add board/column/ticket/label models and migrations`
- [x] `T3.2 add priority and time-tracking schema support`
- [x] `T3.3 build kanban board UI with turbo-stream ticket movement`

Commits:

- [x] `359d785 feat(web): add kanban domain entities and persistence model`
- [x] `9b12b3e test(web): cover ticket priority and lifecycle timing semantics`
- [x] `259f584 feat(web): add turbo-stream kanban board movement and interaction tests`

Validation:

- [x] `<cmd> bundle exec bin/rails test test/models/ticket_test.rb`
- [x] `<cmd> bundle exec bin/rails test test/controllers/boards_controller_test.rb test/controllers/tickets_controller_test.rb`

### Slice 4: Unified Command/Query Bridge and Runtime Loop Controls

- status: `in_review`
- branch: `feat/slice-4-command-query-bridge-and-loop-controls`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `858d7f2`

Tasks:

- [x] `T4.1 add command/query endpoints for ticket start/select/list and loop controls`
- [x] `T4.2 implement ad-hoc request ticketization policy for telegram/tui`
- [x] `T4.3 implement default telegram ticket progress notifications`

Commits:

- [x] `<sha> feat(runtime): enforce ticket-first execution bridge across ingress channels`
- [x] `<sha> feat(runtime): add loop controls and telegram ticket progress notifications`

Validation:

- [x] `<cmd> ruby -Ilib:test test/redwright/server_runtime_dispatcher_test.rb`
- [x] `<cmd> ruby -Ilib:test test/redwright/telegram_control_router_test.rb`

### Slice 5: Time Aggregation, Reporting, and Hardening

- status: `in_review`
- branch: `feat/slice-5-time-aggregation-and-hardening`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `364914f`

Tasks:

- [x] `T5.1 implement per-phase and total elapsed time aggregation in board/report views`
- [x] `T5.2 add end-to-end tests for ticket lifecycle code->review->merge`
- [x] `T5.3 harden selection policy (assigned + highest priority fallback)`

Commits:

- [x] `b9af976 feat(web): add ticket time aggregation and board metrics`
- [x] `<sha> test(e2e): cover unified ticket lifecycle across ingress`

Validation:

- [x] `<cmd> cd apps/web && bundle exec bin/rails test test/models/ticket_test.rb`
- [x] `<cmd> cd apps/web && bundle exec bin/rails test test/controllers/boards_controller_test.rb test/controllers/tickets_controller_test.rb`

## Event Log

- `2026-04-30 00:00` state=`planning` note=`initialized kanban-centric rails MVP cycle with unified runtime and ticket-first execution semantics`
