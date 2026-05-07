# Cycle Tracker: RedWright Quiz Navigation Flow

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-quiz-navigation-flow`
- status: `in_progress`
- state: `slice_1_ready`
- updated: `2026-05-07`
- active_slice: `Slice 1`
- active_task: `T1.1`
- source_plan: `ops/plans/2026-05-07-redwright-quiz-navigation-flow-cycle-plan.md`
- source_ticket: `ops/tickets/in_progress/20260507074859-review-quiz-navigation-flow-and-question-routing-semantics.md`

## Slice Progress

### Slice 1: Quiz Question State Foundation

- status: `planned`
- branch: `fix/slice-1-quiz-question-state-foundation`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T1.1 audit existing quiz and project setup routing/state mechanisms for reuse or configurable generalization`
- [ ] `T1.2 persist current quiz question metadata outside URL query parameters`
- [ ] `T1.3 resolve the current web quiz question from backend state on show/open`
- [ ] `T1.4 cover current-question state with runtime and controller tests`

Commits:

- [ ] `docs(ops): record quiz routing reuse audit`
- [ ] `feat(web): persist quiz current question state`
- [ ] `test(web): cover quiz current question state`

Validation:

- [ ] `scripts/agent/tickets/check.sh`
- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`

### Slice 2: Answer and Skip Progression Semantics

- status: `pending`
- branch: `fix/slice-2-quiz-answer-skip-progression`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 route web answer submissions through backend current-question state`
- [ ] `T2.2 route web skip submissions through backend current-question state`
- [ ] `T2.3 ensure answered and skipped entries persist the exact current question`
- [ ] `T2.4 remove question payload query redirects from answer and skip flows`
- [ ] `T2.5 cover answer and skip progression with runtime and controller tests`

Commits:

- [ ] `fix(web): bind quiz answer progression to state`
- [ ] `fix(web): bind quiz skip progression to state`
- [ ] `test(web): cover quiz answer and skip routing`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`

### Slice 3: Control Semantics and Port Parity

- status: `pending`
- branch: `fix/slice-3-quiz-control-port-parity`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T3.1 verify Done and Cancel semantics against the quiz spec and Telegram behavior`
- [ ] `T3.2 align web Done behavior with sufficiently-answered-for-now semantics`
- [ ] `T3.3 align web Cancel behavior with stop-without-sufficient-answer semantics`
- [ ] `T3.4 keep quiz reopening behavior after Done and Cancel`
- [ ] `T3.5 cover control semantics through targeted web and Telegram tests`

Commits:

- [ ] `fix(web): align quiz done and cancel semantics`
- [ ] `test(web): cover quiz control port parity`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`
- [ ] `bundle exec bin/rails test test/integration/project_setup_telegram_e2e_test.rb`

### Slice 4: Adaptive Routing Closure

- status: `pending`
- branch: `fix/slice-4-quiz-adaptive-routing-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 make follow-up depth, prompt intent, and trunk/coverage state explicit enough for routing decisions`
- [ ] `T4.2 reuse or configure existing question contract behavior where practical`
- [ ] `T4.3 prevent local follow-up loops from losing broader quiz coverage`
- [ ] `T4.4 update tracker, ticket metadata, and residual-risk notes`
- [ ] `T4.5 run targeted and broad validation for the completed cycle`

Commits:

- [ ] `fix(web): clarify adaptive quiz routing state`
- [ ] `test(web): cover adaptive quiz routing closure`
- [ ] `chore(ops): close quiz navigation flow cycle`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/services/quiz_loops/question_contract_test.rb test/services/quiz_loops/question_provider_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`
- [ ] `bundle exec bin/rails test`
- [ ] `scripts/agent/tickets/check.sh`

## Cycle Notes

- Work is split into four PRs so each slice can be reviewed and merged independently.
- Slice execution stops after each PR until the previous slice is merged into `dev`.
- Reuse checks are part of Slice 1 and Slice 4 to avoid duplicating existing quiz or project setup routing mechanisms.

## Residual Risks

- pending

## Tuning Decision

- tuning needed: `pending`
