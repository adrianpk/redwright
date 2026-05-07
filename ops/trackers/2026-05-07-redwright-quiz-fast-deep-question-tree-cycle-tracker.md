# Cycle Tracker: RedWright Quiz Fast and Deep Question Tree

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-quiz-fast-deep-question-tree`
- status: `planned`
- state: `slice_5_implemented`
- updated: `2026-05-07`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-07-redwright-quiz-fast-deep-question-tree-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-07-redwright-quiz-fast-deep-question-tree-spec.md`

## Slice Progress

### Slice 1: Quiz Processing Feedback

- status: `pr_merged`
- branch: `feat/slice-1-quiz-processing-feedback`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/347`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [x] `T1.1 audit current web quiz request/response rendering and processing-feedback options`
- [x] `T1.2 identify the existing quiz turn surface for feedback without changing navigation`
- [x] `T1.3 show a processing state while the next question is being generated`
- [x] `T1.4 preserve existing answer, skip, cancel, and done semantics`
- [x] `T1.5 cover the partial update behavior with controller/system-level tests where practical`

Commits:

- [x] `6676531 docs(ops): record quiz partial update audit`
- [x] `9376737 feat(web): add quiz processing feedback surface`
- [x] `6985fe4 test(web): cover quiz processing feedback`

Validation:

- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 2: Mode State and UI Switch

- status: `pr_merged`
- branch: `feat/slice-2-quiz-mode-switch`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/348`
- merge_target: `dev`
- last_sync_commit: `7eb847d`

Tasks:

- [x] `T2.1 define quiz mode values and default new rounds to deep`
- [x] `T2.2 persist current mode at the quiz or runtime-state boundary`
- [x] `T2.3 add a low-profile web switch for deep versus fast`
- [x] `T2.4 ensure mode changes affect only future question generation`
- [x] `T2.5 cover default mode and mode switching with runtime/controller tests`

Commits:

- [x] `748eeb5 feat(web): add quiz mode state`
- [x] `ca985a9 feat(web): add quiz mode switch`
- [x] `test(web): cover quiz mode switching`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails db:test:prepare && bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 3: Fast Strategy Contract

- status: `pr_merged`
- branch: `feat/slice-3-quiz-fast-strategy-contract`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/349`
- merge_target: `dev`
- last_sync_commit: `61281cf`

Tasks:

- [x] `T3.1 audit existing runtime/provider boundaries for the smallest fast strategy insertion point`
- [x] `T3.2 define a strategy-neutral fast generation contract`
- [x] `T3.3 keep deep generation as the fallback and default`
- [x] `T3.4 route fast generation through LLMRequestEngine`
- [x] `T3.5 cover unavailable, invalid, and fallback fast generation behavior`

Commits:

- [x] `da2fc62 feat(llm): add quiz fast generation contract`
- [x] `1bcc301 test(llm): cover quiz fast generation fallback`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/question_provider_test.rb` (pass)
- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 4: Candidate Storage and Cleanup

- status: `pr_merged`
- branch: `feat/slice-4-quiz-candidate-cleanup`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/350`
- merge_target: `dev`
- last_sync_commit: `f060aba`

Tasks:

- [x] `T4.1 decide from implementation context whether candidates need a table or serialized runtime metadata`
- [x] `T4.2 keep QuizEntry creation limited to activated answered/skipped questions`
- [x] `T4.3 prevent final retrieval tags on discarded candidates`
- [x] `T4.4 prune sibling candidates after tree branch selection when tree strategy is used`
- [x] `T4.5 add opportunistic cleanup for stale unused candidates`

Commits:

- [x] `b0b4407 feat(web): add quiz candidate lifecycle`
- [x] `435e4b2 test(web): cover quiz candidate cleanup`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test test/models/quiz_entry_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 5: First Fast Strategy Implementation

- status: `implemented`
- branch: `feat/slice-5-quiz-first-fast-strategy`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [x] `T5.1 choose the first strategy from batch, round, tree, or minimal hybrid based on implementation simplicity`
- [x] `T5.2 generate fast candidates through LLMRequestEngine`
- [x] `T5.3 enforce deterministic node routing and deep fallback for ambiguous/free-text paths`
- [x] `T5.4 enforce tree ceiling of 1 -> 3 -> 9 when tree strategy is used`
- [x] `T5.5 cover fast progression, fallback, and no-local-semantic-matcher behavior`

Commits:

- [x] `fb8fc37 feat(llm): implement quiz fast generation strategy`
- [x] `4af65bf test(web): cover quiz fast progression`

Validation:

- [x] `bundle exec bin/rails test test/services/quiz_loops/question_provider_test.rb` (pass)
- [x] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb` (pass)
- [x] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb` (pass)
- [x] `bundle exec bin/rails test` (pass)
- [x] `scripts/agent/tickets/check.sh` (pass)

### Slice 6: Tagging, Observability, and Cycle Closure

- status: `planned`
- branch: `feat/slice-6-quiz-fast-deep-closure`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T6.1 ensure final tags are applied only after activation and answer interpretation`
- [ ] `T6.2 keep mode/strategy metadata out of context-ranking behavior`
- [ ] `T6.3 add cheap observability for mode, strategy, fallback, and candidate cleanup when useful`
- [ ] `T6.4 update tracker, spec notes, and residual-risk documentation`
- [ ] `T6.5 run targeted web, runtime, LLM provider, and full Rails validation`

Commits:

- [ ] `fix(web): align quiz fast tagging semantics`
- [ ] `feat(llm): trace quiz fast and deep decisions`
- [ ] `chore(ops): close quiz fast deep question tree cycle`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/services/quiz_loops/question_provider_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`
- [ ] `bundle exec bin/rails test`

## Cycle Notes

- The cycle has six slices so UI responsiveness, mode selection, strategy contract, candidate lifecycle, first fast strategy, and closure can be reviewed independently.
- Slice execution must stop after each PR until the previous slice is merged into `dev`.
- The implementation should keep `deep` as the default and should not expose concrete fast strategies to users.

## Slice 1 Audit

- The current quiz show page uses full-page request/response navigation for answer, skip, cancel, and done.
- The user-visible issue is perceived waiting, not a requirement for a specific frontend mechanism.
- The smallest behavior surface to evaluate is the existing quiz answer/skip interaction, because that is where the user waits for the next generated question.
- Any partial-update or processing-feedback mechanism must preserve answer, skip, cancel, and done semantics.
- The first implementation should prefer immediate submit feedback over changing navigation or introducing a partial-update mechanism.

## Residual Risks

- The first fast strategy may improve only some quiz paths.
- Candidate persistence may be unnecessary if serialized runtime metadata is enough.
- The first processing-feedback mechanism may need adjustment after manual browser review.

## Tuning Decision

- tuning needed: `unknown`
- evidence: `cycle not started`
