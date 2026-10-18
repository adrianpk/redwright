# Cycle Plan: RedWright Quiz Navigation Flow

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-quiz-navigation-flow`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-07`
- updated: `2026-05-07`
- goal: `make web quiz question routing deterministic, state-consistent, adaptive, and aligned with Telegram quiz semantics without relying on URL-carried question payloads`
- scope: `fix`
- source_ticket: `ops/tickets/solved/20260507074859-review-quiz-navigation-flow-and-question-routing-semantics.md`
- source_references:
  - `.agents/playbooks/quiz.md`
  - `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
  - `ops/conv/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`
  - `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`
  - `ops/plans/2026-05-03-redwright-rails-project-setup-conversational-saga-cycle-plan.md`
  - `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`
  - `ops/conv/quiz/2026-05-04-redwright-heavy-interaction-sagas-quiz.md`

## Slice List

### Slice 1: Quiz Question State Foundation

- status: `planned`
- branch: `fix/slice-1-quiz-question-state-foundation`
- pr_title: `feat(slice-1): add quiz question state foundation`
- objective: `establish server-side current-question state and document reusable adjacent routing mechanisms before changing all control semantics`
- tasks:
- [ ] `T1.1 audit existing quiz and project setup routing/state mechanisms for reuse or configurable generalization`
- [ ] `T1.2 persist current quiz question metadata outside URL query parameters`
- [ ] `T1.3 resolve the current web quiz question from backend state on show/open`
- [ ] `T1.4 cover current-question state with runtime and controller tests`
- acceptance:
- `the web show route can render the active question without requiring question content in the URL`
- `current question metadata is owned by the quiz runtime or quiz state, not by browser query payloads`
- `reuse decisions are recorded before introducing additional architecture`
- planned_commits:
- `docs(ops): record quiz routing reuse audit`
- `feat(web): persist quiz current question state`
- `test(web): cover quiz current question state`

### Slice 2: Answer and Skip Progression Semantics

- status: `planned`
- branch: `fix/slice-2-quiz-answer-skip-progression`
- pr_title: `feat(slice-2): align quiz answer and skip progression`
- objective: `make Answer and Skip act on the backend-resolved current question and advance deterministically to the next runtime-resolved question`
- tasks:
- [ ] `T2.1 route web answer submissions through backend current-question state`
- [ ] `T2.2 route web skip submissions through backend current-question state`
- [ ] `T2.3 ensure answered and skipped entries persist the exact current question`
- [ ] `T2.4 remove question payload query redirects from answer and skip flows`
- [ ] `T2.5 cover answer and skip progression with runtime and controller tests`
- acceptance:
- `Answer records the active question and answer, then advances`
- `Skip records the active question as skipped, then advances`
- `answer and skip correctness no longer depends on question text copied through the URL`
- planned_commits:
- `fix(web): bind quiz answer progression to state`
- `fix(web): bind quiz skip progression to state`
- `test(web): cover quiz answer and skip routing`

### Slice 3: Control Semantics and Port Parity

- status: `planned`
- branch: `fix/slice-3-quiz-control-port-parity`
- pr_title: `feat(slice-3): align quiz control port semantics`
- objective: `validate and align Done and Cancel semantics across web and Telegram while preserving reopen behavior`
- tasks:
- [ ] `T3.1 verify Done and Cancel semantics against the quiz spec and Telegram behavior`
- [ ] `T3.2 align web Done behavior with sufficiently-answered-for-now semantics`
- [ ] `T3.3 align web Cancel behavior with stop-without-sufficient-answer semantics`
- [ ] `T3.4 keep quiz reopening behavior after Done and Cancel`
- [ ] `T3.5 cover control semantics through targeted web and Telegram tests`
- acceptance:
- `Done and Cancel remain distinct`
- `both controls stop the current loop without permanently closing the quiz`
- `web and Telegram use shared runtime semantics instead of duplicated controller rules`
- planned_commits:
- `fix(web): align quiz done and cancel semantics`
- `test(web): cover quiz control port parity`

### Slice 4: Adaptive Routing Closure

- status: `planned`
- branch: `fix/slice-4-quiz-adaptive-routing-closure`
- pr_title: `feat(slice-4): close adaptive quiz routing flow`
- objective: `finish the adaptive progression model, preserve Ariadne-style trunk/follow-up clarity, and close the ticket with validation evidence`
- tasks:
- [ ] `T4.1 make follow-up depth, prompt intent, and trunk/coverage state explicit enough for routing decisions`
- [ ] `T4.2 reuse or configure existing question contract behavior where practical`
- [ ] `T4.3 prevent local follow-up loops from losing broader quiz coverage`
- [ ] `T4.4 update tracker, ticket metadata, and residual-risk notes`
- [ ] `T4.5 run targeted and broad validation for the completed cycle`
- acceptance:
- `adaptive progression has a visible backend state model instead of URL-driven routing`
- `Ariadne-style follow-up/trunk behavior is represented or explicitly bounded by existing runtime configuration`
- `the ticket records implementation outcome, validation, and any residual follow-up`
- planned_commits:
- `fix(web): clarify adaptive quiz routing state`
- `test(web): cover adaptive quiz routing closure`
- `chore(ops): close quiz navigation flow cycle`

## Global Exit Criteria

- web quiz navigation does not expose the active question payload as URL state
- Answer and Skip operate on the backend-resolved current question
- Done and Cancel semantics match the quiz spec and Telegram interaction model
- adaptive progression keeps deterministic state while still allowing useful LLM follow-up questions
- existing reusable runtime, contract, or project setup mechanisms are reused or explicitly ruled out before adding parallel abstractions
- all slice PRs target `dev` and are reviewed independently

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Repository ticket checks must run from repository root after ticket or tracker changes.
- Validation entries must include command plus `(pass)` or `(fail)`.
- Each slice PR body must use `Summary`, `Changes`, and `Validation`.

## Non-Goals

- Do not introduce first-class questionnaire session records unless required by an approved later spec.
- Do not redesign the quiz UI beyond behavior needed for this navigation flow.
- Do not create a generic workflow engine if existing quiz-specific runtime state is sufficient.
