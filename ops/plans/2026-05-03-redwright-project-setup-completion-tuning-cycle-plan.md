# Cycle Plan: RedWright Project Setup Completion Tuning

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-setup-completion-tuning`
- status: `completed`
- owner: `adrianpk`
- created: `2026-05-03`
- updated: `2026-05-03`
- goal: `make the project setup questionnaire complete into an observable, idempotent project materialization that applies every collected setup answer across Rails state, local workspace state, and Telegram closure UX`
- scope: `post-slice tuning`
- source_draft: `ops/tmp/drafts/2026-05-03-redwright-project-setup-corrective-slice-draft.md`
- source_cycle: `ops/artifacts/2026-05-03-redwright-rails-project-setup-conversational-saga-cycle-report.md`

## Context

Manual Telegram verification showed that the conversational setup loop now progresses correctly and persists Rails setup state, but the completion boundary is still incomplete from an operator perspective. The bot can say that a project was created while the repository-local workspace does not exist under `_workspace/Projects/<slug>`. The completion step must be treated as the single materialization boundary for all setup answers collected during the questionnaire.

This cycle is intentionally short and corrective. It does not continue the closed six-slice conversational saga cycle; it starts a new two-slice tuning cycle.

## Slice List

### Slice 1: Project Setup Completion Materialization

- status: `merged`
- branch: `fix/slice-1-project-setup-completion-materialization`
- pr_title: `feat(slice-1): project setup completion materialization`
- objective: `make questionnaire completion idempotently apply all collected setup slots into complete Rails project state`
- tasks:
- [ ] `T1.1 characterize completion replay and all-slot materialization expectations with Rails service and API coverage`
- [ ] `T1.2 harden setup completion idempotency so repeated completion requests reuse existing materialized state instead of failing or duplicating records`
- [ ] `T1.3 ensure every collected canonical slot is materialized into ProjectAttribute rows and completion metadata, including repository, runtime container profile, and agent workflow mode when present`
- [ ] `T1.4 ensure Project, setup summary Document, default Board, and optional starter workflow Ticket are reused or reconciled on replay`
- [ ] `T1.5 update tracker with commits and validation outcomes before opening the PR`
- acceptance:
- `questionnaire completion is the single Rails materialization boundary`
- `all collected canonical slots are applied to Rails state`
- `Project, ProjectAttribute, setup summary Document, default Board, and optional starter workflow Ticket are present after completion when applicable`
- `repository remains optional and local placeholder repositories still complete`
- `completion replay does not duplicate Projects, ProjectAttributes, Documents, Boards, Columns, Tickets, or ticket-document links`
- planned_commits:
- `test(web): cover setup completion materialization replay`
- `feat(web): harden setup completion materialization`
- `docs(ops): track slice 1 completion materialization`

### Slice 2: Workspace, Manifest, and Telegram Closure

- status: `reviewing`
- branch: `fix/slice-2-project-setup-workspace-and-telegram-closure`
- pr_title: `feat(slice-2): project setup workspace and telegram closure`
- objective: `create observable local workspace artifacts from completed setup and render Telegram completion without non-rendering shortcode artifacts`
- tasks:
- [ ] `T2.1 define repository-local workspace path mapping for local project setup without breaking runtime path assumptions`
- [ ] `T2.2 create or reconcile _workspace/Projects/<slug> when local setup completes`
- [ ] `T2.3 write an idempotent .redwright/manifest.yml from the collected setup slots`
- [ ] `T2.4 expose completion data so Telegram can state what was created and where`
- [ ] `T2.5 harden Telegram prompt rendering policy so default output avoids colon shortcode tokens while preserving LLM-localized wording`
- [ ] `T2.6 add simulated Telegram E2E coverage from conversation to Rails state, workspace directory, manifest, and shortcode-free completion message`
- [ ] `T2.7 publish cycle closure notes with residual risks and tuning decision`
- acceptance:
- `completed local setup creates a repository-local workspace directory under _workspace/Projects/<slug>`
- `a minimal .redwright/manifest.yml exists and reflects the canonical setup answers`
- `Project.root_path and physical workspace path are reconciled through explicit completion data or documented mapping`
- `Telegram completion confirms project creation and workspace location in human language`
- `Telegram default rendering does not emit :shortcode: artifacts`
- `workspace materialization is idempotent on replay`
- planned_commits:
- `feat(web): materialize setup workspace manifest`
- `feat(telegram): render setup completion closure`
- `test(integration): cover setup workspace telegram closure`
- `docs(ops): close project setup completion tuning cycle`

## Global Exit Criteria

- The setup questionnaire ends in project creation that applies every collected answer.
- Rails state, setup documents, board workflow, and optional starter ticket are consistent after completion.
- Local setup creates visible local workspace artifacts under `_workspace/Projects`.
- The local manifest records the setup context needed by later agents and runtime work.
- Telegram remains an adapter over Rails behavior and renders human localized prompts without raw internal state by default.
- No repository URL is required to complete a project setup.
- Repeated completion or replay does not duplicate or corrupt state.
- Test coverage is maintained or increased for the touched code paths.

## Non-Goals

- Do not add Projects CRUD UI.
- Do not create remote Git repositories.
- Do not redesign the questionnaire model.
- Do not replace Rails as the application source of truth.
- Do not start a `dev -> main` release alignment inside either slice.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository coverage must be run from repository root (`~/Projects/redwright/redwright`).
- Canonical repository coverage command: `bundle exec rake test:coverage`.
- PR validation entries must be reported as command plus `(pass)` or `(fail)`, without raw running traces.
