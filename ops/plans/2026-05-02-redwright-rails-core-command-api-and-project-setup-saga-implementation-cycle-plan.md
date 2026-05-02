# Cycle Plan: RedWright Rails Core Command API and Project Setup Saga Implementation

## Metadata

- cycle_id: `cycle-2026-05-02-redwright-rails-core-command-api-and-project-setup-saga`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-02`
- updated: `2026-05-02`
- goal: `make Rails the application source of truth and route Telegram/project setup/agent workflow through Rails command-query APIs`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-02-redwright-rails-core-command-api-and-project-setup-saga-spec.md`

## Slice List

### Slice 1: Rails Application Command/Query Foundation

- status: `pending`
- branch: `fix/slice-1-rails-command-query-foundation`
- pr_title: `feat(slice-1): rails command query foundation`
- objective: `introduce a Rails-owned command/query application boundary with deterministic envelopes and result contracts`
- tasks:
- [ ] `T1.1 define Rails command/query envelope and result objects`
- [ ] `T1.2 add Rails dispatcher with command/query registry and structured error handling`
- [ ] `T1.3 add focused tests for envelope validation, dispatch success, and unsupported command/query errors`
- acceptance:
- `Rails has an explicit command/query boundary that can be called by web and API layers`
- `unsupported commands and invalid payloads return structured errors`
- planned_commits:
- `feat(web): add rails command query envelope contract`
- `feat(web): add rails command query dispatcher`
- `test(web): cover rails command query dispatch contract`

### Slice 2: Project Setup Session Persistence and State Machine

- status: `pending`
- branch: `fix/slice-2-project-setup-session-state-machine`
- pr_title: `feat(slice-2): project setup session state machine`
- objective: `persist Rails project setup saga state and enforce deterministic transitions`
- tasks:
- [ ] `T2.1 add ProjectSetupSession and ProjectSetupTurn migrations/models`
- [ ] `T2.2 add setup state machine service with allowed transitions and terminal outcomes`
- [ ] `T2.3 add model and service tests for setup state, turn ordering, cancellation, and invalid transitions`
- acceptance:
- `project setup state is persisted in Rails`
- `invalid setup transitions are rejected before side effects occur`
- planned_commits:
- `feat(web): add project setup session persistence`
- `feat(web): add project setup state machine`
- `test(web): cover project setup state persistence and transitions`

### Slice 3: Unified Rails Project Initialization Services

- status: `pending`
- branch: `fix/slice-3-unified-rails-project-initialization-services`
- pr_title: `feat(slice-3): unified rails project initialization services`
- objective: `move web project creation onto the setup session and command service path without adding API transport yet`
- tasks:
- [ ] `T3.1 adapt ProjectInitialization services to create or advance ProjectSetupSession records`
- [ ] `T3.2 wire ProjectsController to the unified service path while preserving Rails HTML/Turbo ergonomics`
- [ ] `T3.3 add web/service tests proving repository-first setup, opt-in/out, cancellation, and no hidden partial state`
- acceptance:
- `web project creation uses the same Rails setup services intended for API use`
- `guided alignment no longer ends as only a textual flag when setup should continue`
- planned_commits:
- `feat(web): bind project initialization to setup sessions`
- `feat(web): route project creation form through unified setup service`
- `test(web): cover unified project initialization setup flow`

### Slice 4: Rails Project Setup Command API

- status: `pending`
- branch: `fix/slice-4-rails-project-setup-command-api`
- pr_title: `feat(slice-4): rails project setup command api`
- objective: `expose project setup commands and queries through a stable Rails API namespace`
- tasks:
- [ ] `T4.1 add /api/v1 command/query routes, controller base, request id handling, and actor context`
- [ ] `T4.2 register project setup commands and queries in the Rails dispatcher`
- [ ] `T4.3 add API integration tests for start, advance, cancel, status, and project listing`
- acceptance:
- `external adapters can operate project setup through Rails API responses`
- `API responses include request_id, status, state, summary, effects, and errors`
- planned_commits:
- `feat(web): add rails command query api namespace`
- `feat(web): expose project setup commands through rails api`
- `test(web): cover project setup command api`

### Slice 5: Telegram Project Setup Adapter Over Rails API

- status: `pending`
- branch: `fix/slice-5-telegram-project-setup-rails-api-adapter`
- pr_title: `feat(slice-5): telegram project setup rails api adapter`
- objective: `route Telegram project setup through Rails API instead of runtime-only project creation`
- tasks:
- [ ] `T5.1 add Telegram Rails API client/adapter for command/query envelopes`
- [ ] `T5.2 route /project new, project setup replies, /project list, and /project where through Rails API where applicable`
- [ ] `T5.3 add Telegram handler tests proving multi-turn setup and no runtime-only project creation for new projects`
- acceptance:
- `Telegram /project new starts or advances a Rails setup session`
- `Telegram does not terminate project setup with shallow runtime-only creation state`
- planned_commits:
- `feat(telegram): add rails command api adapter`
- `feat(telegram): route project setup commands through rails api`
- `test(telegram): cover rails-backed project setup flow`

### Slice 6: Rails-Governed Guided Alignment and Questionnaire Artifacts

- status: `pending`
- branch: `fix/slice-6-rails-guided-alignment-questionnaire-artifacts`
- pr_title: `feat(slice-6): rails guided alignment questionnaire artifacts`
- objective: `persist guided alignment turns in Rails and derive visible questionnaire/document/project context artifacts`
- tasks:
- [ ] `T6.1 implement one-question-per-turn setup alignment service using setup turns`
- [ ] `T6.2 persist normalized alignment output into project attributes and/or document artifacts per lifecycle rules`
- [ ] `T6.3 add tests for bounded turns, opt-out, turn reuse, artifact creation, and terminal outcomes`
- acceptance:
- `guided alignment is a persisted Rails application workflow`
- `questionnaire output becomes visible and reusable in project documents/context`
- planned_commits:
- `feat(web): add rails guided alignment setup service`
- `feat(web): persist setup alignment artifacts`
- `test(web): cover guided alignment setup artifacts`

### Slice 7: Rails Document, Ticket, and Board Command API

- status: `pending`
- branch: `fix/slice-7-rails-document-ticket-board-command-api`
- pr_title: `feat(slice-7): rails document ticket board command api`
- objective: `expose document, ticket, and board operations through Rails command/query APIs with shared service rules`
- tasks:
- [ ] `T7.1 register document commands/queries for draft creation, draft update, promotion, and project document listing`
- [ ] `T7.2 register ticket/board commands/queries for create, move, pick, attach documents, and board snapshot`
- [ ] `T7.3 add API and service tests for project consistency, document lifecycle, board transitions, and ticket/document links`
- acceptance:
- `Telegram and agents can operate board/document/ticket state through Rails APIs`
- `web/API paths enforce the same Rails model and service invariants`
- planned_commits:
- `feat(web): add document command query api handlers`
- `feat(web): add ticket board command query api handlers`
- `test(web): cover document ticket board command api behavior`

### Slice 8: Agent Runtime Bridge and Cross-Channel Parity

- status: `pending`
- branch: `fix/slice-8-agent-runtime-bridge-cross-channel-parity`
- pr_title: `feat(slice-8): agent runtime bridge cross channel parity`
- objective: `bridge Rails tickets to runtime execution while preserving Rails as application source of truth`
- tasks:
- [ ] `T8.1 add Rails-to-runtime execution bridge contract for starting work from tickets`
- [ ] `T8.2 persist runtime execution correlation on Rails tickets without duplicating board/application rules`
- [ ] `T8.3 add cross-channel E2E tests for web/API/Telegram project setup and ticket execution parity`
- acceptance:
- `agent/runtime work starts from Rails board/ticket context`
- `runtime state is executor-local or correlated, not a competing application source of truth`
- planned_commits:
- `feat(runtime): add rails ticket execution bridge contract`
- `feat(web): persist runtime execution correlation on tickets`
- `test(integration): cover rails telegram runtime parity`

## Global Exit Criteria

- `Rails owns canonical project, setup, document, ticket, and board application state`
- `Telegram project setup runs through Rails API and Rails setup sessions`
- `web and API paths share the same Rails service rules for mutations`
- `guided alignment persists as visible Rails application context`
- `document, ticket, and board operations are exposed through command/query APIs`
- `agent/runtime execution is correlated from Rails tickets without duplicating application workflow state`
- `coverage is maintained or improved against baseline for all added code`

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository coverage must be run from repository root (`~/Projects/redwright/redwright`).
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- Validation entries in PRs and trackers must be reported as `pass` or `fail`, without raw running traces.
