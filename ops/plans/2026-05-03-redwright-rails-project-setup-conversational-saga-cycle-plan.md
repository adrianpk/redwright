# Cycle Plan: RedWright Rails Project Setup Conversational Saga

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-rails-project-setup-conversational-saga`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- goal: `make /project new a Rails-owned conversational setup saga with optional repository input, canonical slot persistence, human Telegram prompts, and Rails workflow materialization`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`

## Slice List

### Slice 1: Setup Context Slot Model and Repository Decoupling

- status: `pending`
- branch: `fix/slice-1-project-setup-context-slots`
- pr_title: `feat(slice-1): project setup context slots`
- objective: `make project setup start without repository input and persist canonical setup slots in Rails setup session metadata`
- tasks:
- [ ] `T1.1 characterize current repository-first behavior with Rails and Telegram tests`
- [ ] `T1.2 add canonical setup context slot helpers for ProjectSetupSession metadata`
- [ ] `T1.3 change StartProjectSetup payload handling so project name and description are not mapped to repository input`
- [ ] `T1.4 allow repository input to be absent or skipped without invalidating setup start`
- [ ] `T1.5 add tests for empty start, name-only start, quoted name with description, and repository URL input`
- acceptance:
- `/project new` starts a Rails setup session without repository input
- `plain project names fill project_name and never trigger repository ambiguity by themselves`
- `canonical slots are persisted in ProjectSetupSession.metadata and audited through setup turns where applicable`
- planned_commits:
- `test(web): characterize repository independent project setup start`
- `feat(web): add project setup context slot metadata`
- `feat(telegram): stop mapping project names to repository input`

### Slice 2: Deterministic Setup Question Loop Controls

- status: `pending`
- branch: `fix/slice-2-project-setup-question-loop-controls`
- pr_title: `feat(slice-2): project setup question loop controls`
- objective: `implement deterministic next-question selection and control commands for skip, done, and cancel`
- tasks:
- [ ] `T2.1 add setup question selector for canonical slots and blocking/recommended/optional policy`
- [ ] `T2.2 implement AdvanceProjectSetup handling for normal answers and slot normalization`
- [ ] `T2.3 implement /skip and /done over Rails setup commands`
- [ ] `T2.4 preserve cancellation semantics and no-residue behavior before project creation`
- [ ] `T2.5 add tests for question progression, no-reask behavior, skip, done, cancel, and repeated ambiguity`
- acceptance:
- `the setup loop asks one useful next question at a time`
- `/done` completes when only defaultable slots remain
- `/cancel` leaves only an auditable cancelled setup session before creation
- planned_commits:
- `feat(web): add project setup question selector`
- `feat(web): add project setup loop controls`
- `test(web): cover project setup conversational controls`

### Slice 3: Human Telegram Rendering for Project Setup

- status: `pending`
- branch: `fix/slice-3-telegram-project-setup-human-rendering`
- pr_title: `feat(slice-3): telegram project setup human rendering`
- objective: `render setup responses as human prompts while preserving structured Rails API data for adapters and tests`
- tasks:
- [ ] `T3.1 add Telegram project setup response renderer for summary, understood context, next prompt, and controls`
- [ ] `T3.2 hide raw state/session/trace details by default and keep debug/trace formatting opt-in`
- [ ] `T3.3 route setup replies, /skip, /done, and /cancel through the renderer`
- [ ] `T3.4 add Telegram adapter tests for sparse, rich, skipped, completed, and cancelled setup flows`
- acceptance:
- `Telegram users see setup prompts instead of internal state names`
- `debug metadata remains available only when explicitly enabled`
- `Telegram remains an adapter over Rails command/query responses`
- planned_commits:
- `feat(telegram): render human project setup prompts`
- `test(telegram): cover project setup rendering modes`

### Slice 4: Setup Completion and Rails Artifact Materialization

- status: `pending`
- branch: `fix/slice-4-project-setup-artifact-materialization`
- pr_title: `feat(slice-4): project setup artifact materialization`
- objective: `turn completed setup context into Rails project, weighted attributes, setup summary document, and default workflow structure`
- tasks:
- [ ] `T4.1 create project from canonical setup context with repository absent or present`
- [ ] `T4.2 materialize setup context into ProjectAttribute rows with weights and sources`
- [ ] `T4.3 write setup summary Document from canonical answers`
- [ ] `T4.4 ensure default board structure exists after setup completion`
- [ ] `T4.5 add tests for materialization, idempotency, and no duplicate artifacts on repeated request ids`
- acceptance:
- `completed setup creates visible Rails application state`
- `canonical setup context is reusable by web, documents, board, and agents`
- `repository absence does not block local project setup completion`
- planned_commits:
- `feat(web): materialize project setup context artifacts`
- `test(web): cover setup completion materialization`

### Slice 5: Agent Workflow and Runtime Container Context Bridge

- status: `pending`
- branch: `fix/slice-5-project-setup-agent-workflow-context`
- pr_title: `feat(slice-5): project setup agent workflow context`
- objective: `make setup context available to agent workflow through Rails tickets, project attributes, and runtime bridge settings`
- tasks:
- [ ] `T5.1 define runtime container profile defaults and project attribute keys`
- [ ] `T5.2 expose setup-derived stack/framework/library/context values to runtime bridge inputs`
- [ ] `T5.3 create or update starter tickets when setup context requests agent workflow`
- [ ] `T5.4 add integration tests from setup completion to ticket execution bridge input`
- acceptance:
- `agent execution starts from Rails workflow context with setup-derived settings`
- `runtime container settings are deterministic when user input is absent`
- `agents do not need adapter-local setup logic to operate project work`
- planned_commits:
- `feat(runtime): pass project setup context to ticket execution bridge`
- `feat(web): seed setup-driven starter workflow tickets`
- `test(integration): cover setup context runtime bridge parity`

### Slice 6: End-to-End Regression Closure

- status: `pending`
- branch: `fix/slice-6-project-setup-conversational-e2e`
- pr_title: `feat(slice-6): project setup conversational e2e`
- objective: `close the cycle with end-to-end coverage and tracker/report updates`
- tasks:
- [ ] `T6.1 add Rails API end-to-end scenarios for sparse, rich, skip, done, cancel, and repository-backed setup`
- [ ] `T6.2 add Telegram simulated ingress scenarios for the same setup matrix`
- [ ] `T6.3 run full Rails tests and repository coverage from canonical locations`
- [ ] `T6.4 publish cycle closure notes with residual risks and tuning decision`
- acceptance:
- `all core setup scenarios pass end-to-end`
- `coverage is maintained or improved`
- `the cycle tracker maps completed slices to spec acceptance criteria`
- planned_commits:
- `test(integration): add project setup conversational e2e matrix`
- `docs(ops): close project setup conversational saga cycle`

## Global Exit Criteria

- `/project new` starts a Rails setup saga without repository input
- `repository is optional, skippable, and not confused with project name`
- `setup answers are persisted canonically before creation and materialized after completion`
- `Telegram renders human setup prompts by default`
- `web and Telegram share Rails service rules`
- `completed setup creates visible Rails project workflow context`
- `agents can consume setup-derived context through Rails tickets/runtime bridge`
- `test coverage is maintained or increased for new code paths`

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository coverage must be run from repository root (`~/Projects/redwright/redwright`).
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces.
