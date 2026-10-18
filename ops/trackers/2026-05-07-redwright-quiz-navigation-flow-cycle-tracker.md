# Cycle Tracker: RedWright Quiz Navigation Flow

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-quiz-navigation-flow`
- status: `completed`
- state: `completed`
- updated: `2026-10-18`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-07-redwright-quiz-navigation-flow-cycle-plan.md`
- source_ticket: `ops/tickets/solved/20260507074859-review-quiz-navigation-flow-and-question-routing-semantics.md`

## Slice Progress

### Slice 1: Quiz Question State Foundation

- status: `pr_merged`
- branch: `fix/slice-1-quiz-question-state-foundation`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/341`
- merge_target: `dev`
- last_sync_commit: `2f9596b`

Tasks:

- [x] `T1.1 audit existing quiz and project setup routing/state mechanisms for reuse or configurable generalization`
- [x] `T1.2 persist current quiz question metadata outside URL query parameters`
- [x] `T1.3 resolve the current web quiz question from backend state on show/open`
- [x] `T1.4 cover current-question state with runtime and controller tests`

Commits:

- [x] `875037d docs(ops): record quiz routing reuse audit`
- [x] `c79fdfc feat(web): persist quiz current question state`
- [x] `test(web): cover quiz current question state`

Validation:

- [x] `scripts/agent/tickets/check.sh` (pass)
- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)

### Slice 2: Answer and Skip Progression Semantics

- status: `pr_merged`
- branch: `fix/slice-2-quiz-answer-skip-progression`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/342`
- merge_target: `dev`
- last_sync_commit: `8c6d9db`

Tasks:

- [x] `T2.1 route web answer submissions through backend current-question state`
- [x] `T2.2 route web skip submissions through backend current-question state`
- [x] `T2.3 ensure answered and skipped entries persist the exact current question`
- [x] `T2.4 remove question payload query redirects from answer and skip flows`
- [x] `T2.5 cover answer and skip progression with runtime and controller tests`

Commits:

- [x] `ec1cc4d fix(web): bind quiz answer progression to state`
- [x] `6f9e8f8 fix(web): bind quiz skip progression to state`
- [x] `test(web): cover quiz answer and skip routing`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 3: Control Semantics and Port Parity

- status: `pr_merged`
- branch: `fix/slice-3-quiz-control-port-parity`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/343`
- merge_target: `dev`
- last_sync_commit: `c0588d8`

Tasks:

- [x] `T3.1 verify Done and Cancel semantics against the quiz spec and Telegram behavior`
- [x] `T3.2 align web Done behavior with sufficiently-answered-for-now semantics`
- [x] `T3.3 align web Cancel behavior with stop-without-sufficient-answer semantics`
- [x] `T3.4 keep quiz reopening behavior after Done and Cancel`
- [x] `T3.5 cover control semantics through targeted web and Telegram tests`

Commits:

- [x] `c6429b9 fix(web): align quiz done and cancel semantics`
- [x] `test(web): cover quiz control port parity`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test test/integration/project_setup_telegram_e2e_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 4: Adaptive Routing Closure

- status: `pr_merged`
- branch: `fix/slice-4-quiz-adaptive-routing-closure`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/344`
- merge_target: `dev`
- last_sync_commit: `5b49868`

Tasks:

- [x] `T4.1 make follow-up depth, prompt intent, and trunk/coverage state explicit enough for routing decisions`
- [x] `T4.2 reuse existing LLMRequestEngine and question contract behavior`
- [x] `T4.3 prevent local follow-up loops from losing broader quiz coverage`
- [x] `T4.4 update tracker, ticket metadata, and residual-risk notes`
- [x] `T4.5 run targeted and broad validation for the completed cycle`

Commits:

- [x] `fix(web): clarify adaptive quiz routing state`
- [x] `test(web): cover adaptive quiz routing closure`
- [x] `chore(ops): close quiz navigation flow cycle`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test test/services/quiz_loops/question_contract_test.rb test/services/quiz_loops/question_provider_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

## Cycle Notes

- Work is split into four PRs so each slice can be reviewed and merged independently.
- Slice execution stops after each PR until the previous slice is merged into `dev`.
- Reuse checks are part of Slice 1 and Slice 4 to avoid duplicating existing quiz or project setup routing mechanisms.

## Slice 1 Reuse Audit

- `QuizLoops::Runtime` already owns quiz resolution, entry persistence, control detection, and next-question generation. It is the correct place to own current-question state for web and Telegram ports.
- `QuizLoops::QuestionContract` already carries `follow_up_depth` and `completion_recommended`, so Slice 1 should persist generated prompt metadata rather than inventing a second contract.
- `ProjectSetup::GuidedAlignmentService` shows the adjacent Ariadne-style pattern: deterministic question sequence, stored answers, pending question state, and prompt intent metadata. That pattern is reusable as a design reference, but its fixed `ProjectSetupSession` lifecycle should not be generalized into quiz sessions in this ticket.
- `ProjectSetup::PromptIntentBuilder` provides structured prompt intent metadata. Quiz prompt intent should continue to use `QuizLoops::PromptIntentBuilder` and store the generated intent with the current question.
- `ProjectSetupSession` already demonstrates JSON-backed backend state through `metadata_json`. For quizzes, storing current question metadata on `Quiz` is the smallest compatible state mechanism because the original quiz spec excludes first-class questionnaire sessions.
- No existing service fully models reusable current-question routing for arbitrary workflows. The reusable boundary for this slice is the runtime contract, not a new generic state machine.
- Slice 4 corrected the quiz LLM boundary to use the already implemented `Redwright::LLM::RequestEngine`, `Redwright::LLM::ContextSection`, and `Redwright::LLM::TraceRecorder` path instead of a quiz-specific raw client protocol.

## Residual Risks

- The quiz still does not introduce first-class questionnaire session records; this is intentional per the referenced first-version spec.
- Adaptive routing remains LLM-question based through `LLMRequestEngine`, with runtime guardrails for follow-up depth and trunk return, not a full deterministic coverage engine.

## Tuning Decision

- tuning needed: `no`
- evidence: `targeted runtime, contract, provider, controller, Telegram, and full Rails validation are part of Slice 4 closure`

## Completion Reconciliation

Reconciled on 2026-10-18: all listed slice commits are integrated into `dev`, the recorded validation is complete, and the source ticket is now `solved`.
