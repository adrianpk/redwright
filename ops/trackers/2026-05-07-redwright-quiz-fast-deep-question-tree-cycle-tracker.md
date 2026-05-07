# Cycle Tracker: RedWright Quiz Fast and Deep Question Tree

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-quiz-fast-deep-question-tree`
- status: `planned`
- state: `not_started`
- updated: `2026-05-07`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-07-redwright-quiz-fast-deep-question-tree-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-07-redwright-quiz-fast-deep-question-tree-spec.md`

## Slice Progress

### Slice 1: Quiz Partial Update and Processing Feedback

- status: `planned`
- branch: `feat/slice-1-quiz-partial-processing-feedback`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T1.1 audit current web quiz request/response rendering and Turbo availability`
- [ ] `T1.2 isolate the question/answer region into a reusable partial or frame-compatible surface`
- [ ] `T1.3 show a processing state while the next question is being generated`
- [ ] `T1.4 preserve existing answer, skip, cancel, and done semantics`
- [ ] `T1.5 cover the partial update behavior with controller/system-level tests where practical`

Commits:

- [ ] `feat(web): add quiz processing feedback surface`
- [ ] `test(web): cover quiz partial question updates`

Validation:

- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`

### Slice 2: Mode State and UI Switch

- status: `planned`
- branch: `feat/slice-2-quiz-mode-switch`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 define quiz mode values and default new rounds to deep`
- [ ] `T2.2 persist current mode at the quiz or runtime-state boundary`
- [ ] `T2.3 add a low-profile web switch for deep versus fast`
- [ ] `T2.4 ensure mode changes affect only future question generation`
- [ ] `T2.5 cover default mode and mode switching with runtime/controller tests`

Commits:

- [ ] `feat(web): add quiz mode state`
- [ ] `feat(web): add quiz mode switch`
- [ ] `test(web): cover quiz mode switching`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`

### Slice 3: Fast Strategy Contract

- status: `planned`
- branch: `feat/slice-3-quiz-fast-strategy-contract`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T3.1 audit existing runtime/provider boundaries for the smallest fast strategy insertion point`
- [ ] `T3.2 define a strategy-neutral fast generation contract`
- [ ] `T3.3 keep deep generation as the fallback and default`
- [ ] `T3.4 route fast generation through LLMRequestEngine`
- [ ] `T3.5 cover unavailable, invalid, and fallback fast generation behavior`

Commits:

- [ ] `feat(llm): add quiz fast generation contract`
- [ ] `test(llm): cover quiz fast generation fallback`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/question_provider_test.rb`
- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`

### Slice 4: Candidate Storage and Cleanup

- status: `planned`
- branch: `feat/slice-4-quiz-candidate-cleanup`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 decide from implementation context whether candidates need a table or serialized runtime metadata`
- [ ] `T4.2 keep QuizEntry creation limited to activated answered/skipped questions`
- [ ] `T4.3 prevent final retrieval tags on discarded candidates`
- [ ] `T4.4 prune sibling candidates after tree branch selection when tree strategy is used`
- [ ] `T4.5 add opportunistic cleanup for stale unused candidates`

Commits:

- [ ] `feat(web): add quiz candidate lifecycle`
- [ ] `test(web): cover quiz candidate cleanup`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/models/quiz_entry_test.rb`

### Slice 5: First Fast Strategy Implementation

- status: `planned`
- branch: `feat/slice-5-quiz-first-fast-strategy`
- PR: `none`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 choose the first strategy from batch, round, tree, or minimal hybrid based on implementation simplicity`
- [ ] `T5.2 generate fast candidates through LLMRequestEngine`
- [ ] `T5.3 enforce deterministic node routing and deep fallback for ambiguous/free-text paths`
- [ ] `T5.4 enforce tree ceiling of 1 -> 3 -> 9 when tree strategy is used`
- [ ] `T5.5 cover fast progression, fallback, and no-local-semantic-matcher behavior`

Commits:

- [ ] `feat(llm): implement quiz fast generation strategy`
- [ ] `test(web): cover quiz fast progression`

Validation:

- [ ] `bundle exec bin/rails test test/services/quiz_loops/question_provider_test.rb`
- [ ] `bundle exec bin/rails test test/services/quiz_loops/runtime_test.rb`
- [ ] `bundle exec bin/rails test test/controllers/project_quizzes_controller_test.rb`

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

## Residual Risks

- The first fast strategy may improve only some quiz paths.
- Candidate persistence may be unnecessary if serialized runtime metadata is enough.
- Turbo Streams may require adjustment if the existing quiz controller shape does not fit partial updates cleanly.

## Tuning Decision

- tuning needed: `unknown`
- evidence: `cycle not started`
