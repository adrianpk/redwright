# Cycle Plan: RedWright Kanban-Centric Rails MVP

## Metadata

- cycle_id: `rw-2026-04-30-kanban-centric-rails-mvp`
- status: `approved`
- owner: `adrianpk`
- created: `2026-04-30`
- updated: `2026-04-30`
- goal: `implement a ticket-first Rails Kanban app side-by-side with the harness using unified command/query execution semantics`
- scope: `feature`

## Slice List

### Slice 1: Spec and Contract Realignment

- status: `completed`
- branch: `dev`
- objective: `align ADRs, reference contracts, and execution vocabulary to unified ticket-centric runtime`
- tasks:
- [x] `T1.1 supersede dual-runtime and dual-bot ADR decisions`
- [x] `T1.2 define unified single_ticket/loop execution semantics`
- [x] `T1.3 define ticket metadata extensions for priority and time tracking`
- [x] `T1.4 publish open questions for future multi-agent pool topology`
- acceptance:
- `no reference docs describe dual-bot as active policy`
- `kanban contract includes priority/time-tracking fields and ticketization rules`
- planned_commits:
- `docs(architecture): realign kanban-centric runtime ADR and contracts`
- PR:
- `n/a (direct dev update requested)`

### Slice 2: Rails App Scaffolding and Repo Materialization

- status: `pending`
- branch: `feat/slice-2-rails-app-scaffold-and-repo-materialization`
- objective: `materialize apps/web Rails skeleton and enforce side-by-side boundaries with harness`
- tasks:
- [ ] `T2.1 create apps/web rails app skeleton with baseline auth`
- [ ] `T2.2 wire project structure boundaries and update repository map`
- [ ] `T2.3 add smoke tests for rails boot and integration stubs`
- acceptance:
- `apps/web boots locally`
- `repo structure reflects documented ownership`
- planned_commits:
- `feat(web): scaffold rails kanban app baseline`
- `test(web): add rails boot and boundary smoke coverage`
- PR:
- `tbd`

### Slice 3: Ticket Domain and Kanban Board MVP

- status: `pending`
- branch: `feat/slice-3-ticket-domain-and-board-mvp`
- objective: `implement board/column/ticket models with priority and time-tracking metadata`
- tasks:
- [ ] `T3.1 add board/column/ticket/label models and migrations`
- [ ] `T3.2 add priority and time-tracking schema support`
- [ ] `T3.3 build kanban board UI with turbo-stream ticket movement`
- acceptance:
- `tickets can move across columns with live updates`
- `ticket metadata includes priority and tracked phase times`
- planned_commits:
- `feat(web): implement kanban domain models and board views`
- `feat(web): add turbo-stream drag-drop ticket transitions`
- PR:
- `tbd`

### Slice 4: Unified Command/Query Bridge and Runtime Loop Controls

- status: `pending`
- branch: `feat/slice-4-command-query-bridge-and-loop-controls`
- objective: `wire rails/telegram/tui into unified ticket-first command/query execution with single_ticket and loop controls`
- tasks:
- [ ] `T4.1 add command/query endpoints for ticket start/select/list and loop controls`
- [ ] `T4.2 implement ad-hoc request ticketization policy for telegram/tui`
- [ ] `T4.3 implement default telegram ticket progress notifications`
- acceptance:
- `every mutating request resolves to a ticket`
- `single_ticket and loop execution modes are operable via slash commands and rails controls`
- planned_commits:
- `feat(runtime): enforce ticket-first execution bridge across ingress channels`
- `feat(runtime): add loop controls and telegram ticket progress notifications`
- PR:
- `tbd`

### Slice 5: Time Aggregation, Reporting, and Hardening

- status: `pending`
- branch: `feat/slice-5-time-aggregation-and-hardening`
- objective: `add kanban-native time aggregation and stabilize full lifecycle flow`
- tasks:
- [ ] `T5.1 implement per-phase and total elapsed time aggregation in board/report views`
- [ ] `T5.2 add end-to-end tests for ticket lifecycle code->review->merge`
- [ ] `T5.3 harden selection policy (assigned + highest priority fallback)`
- acceptance:
- `board shows partial and total times per ticket`
- `e2e flow proves deterministic lifecycle transitions`
- planned_commits:
- `feat(web): add ticket time aggregation and board metrics`
- `test(e2e): cover unified ticket lifecycle across ingress`
- PR:
- `tbd`

## Global Exit Criteria

- `rails app is materialized in apps/web and integrated with runtime contracts`
- `all mutating work is ticketized across rails/telegram/tui`
- `single_ticket and loop modes are functional and tested`
