# Cycle Plan: RedWright Quiz Fast and Deep Question Tree

## Metadata

- cycle_id: `cycle-2026-05-07-redwright-quiz-fast-deep-question-tree`
- status: `planned`
- owner: `adrianpk`
- created: `2026-05-07`
- updated: `2026-05-07`
- goal: `reduce perceived quiz latency while preserving deep extraction quality and keeping fast strategy internals hidden from users`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-07-redwright-quiz-fast-deep-question-tree-spec.md`
- source_references:
  - `.agents/playbooks/quiz.md`
  - `ops/conv/quiz/2026-05-07-redwright-quiz-fast-deep-question-tree-quiz.md`
  - `ops/specs/drafts/2026-05-07-redwright-quiz-fast-deep-question-tree-draft.md`
  - `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
  - `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`

## Slice List

### Slice 1: Quiz Processing Feedback

- status: `planned`
- branch: `feat/slice-1-quiz-processing-feedback`
- pr_title: `feat(slice-1): add quiz processing feedback`
- objective: `make the current deep flow feel responsive by showing immediate generation feedback while preserving the existing request/response navigation`
- tasks:
- [ ] `T1.1 audit current web quiz request/response rendering and processing-feedback options`
- [ ] `T1.2 identify the existing quiz turn surface for feedback without changing navigation`
- [ ] `T1.3 show a processing state while the next question is being generated`
- [ ] `T1.4 preserve existing answer, skip, cancel, and done semantics`
- [ ] `T1.5 cover the partial update behavior with controller/system-level tests where practical`
- acceptance:
- `answer and skip show immediate processing feedback before the response returns`
- `generation feedback is visible during next-question processing`
- `the default deep flow remains behaviorally unchanged`
- planned_commits:
- `feat(web): add quiz processing feedback surface`
- `test(web): cover quiz processing feedback`

### Slice 2: Mode State and UI Switch

- status: `planned`
- branch: `feat/slice-2-quiz-mode-switch`
- pr_title: `feat(slice-2): add quiz fast and deep mode switch`
- objective: `introduce deep/fast mode state with deep as the default and a low-profile UI switch that affects future question generation`
- tasks:
- [ ] `T2.1 define quiz mode values and default new rounds to deep`
- [ ] `T2.2 persist current mode at the quiz or runtime-state boundary`
- [ ] `T2.3 add a low-profile web switch for deep versus fast`
- [ ] `T2.4 ensure mode changes affect only future question generation`
- [ ] `T2.5 cover default mode and mode switching with runtime/controller tests`
- acceptance:
- `new quiz rounds start in deep`
- `the user can switch to fast and back to deep during a quiz`
- `the UI does not expose batch/tree strategy choices`
- planned_commits:
- `feat(web): add quiz mode state`
- `feat(web): add quiz mode switch`
- `test(web): cover quiz mode switching`

### Slice 3: Fast Strategy Contract

- status: `planned`
- branch: `feat/slice-3-quiz-fast-strategy-contract`
- pr_title: `feat(slice-3): add quiz fast strategy contract`
- objective: `add an internal fast strategy boundary that can support batch, round, or tree generation without exposing strategy choice to users`
- tasks:
- [ ] `T3.1 audit existing runtime/provider boundaries for the smallest fast strategy insertion point`
- [ ] `T3.2 define a strategy-neutral fast generation contract`
- [ ] `T3.3 keep deep generation as the fallback and default`
- [ ] `T3.4 route fast generation through LLMRequestEngine`
- [ ] `T3.5 cover unavailable, invalid, and fallback fast generation behavior`
- acceptance:
- `fast strategy selection is internal`
- `LLMRequestEngine remains the LLM boundary`
- `failed or unavailable fast generation falls back to deep`
- planned_commits:
- `feat(llm): add quiz fast generation contract`
- `test(llm): cover quiz fast generation fallback`

### Slice 4: Candidate Storage and Cleanup

- status: `planned`
- branch: `feat/slice-4-quiz-candidate-cleanup`
- pr_title: `feat(slice-4): add quiz candidate lifecycle`
- objective: `support generated candidates without polluting QuizEntry or context retrieval material`
- tasks:
- [ ] `T4.1 decide from implementation context whether candidates need a table or serialized runtime metadata`
- [ ] `T4.2 keep QuizEntry creation limited to activated answered/skipped questions`
- [ ] `T4.3 prevent final retrieval tags on discarded candidates`
- [ ] `T4.4 prune sibling candidates after tree branch selection when tree strategy is used`
- [ ] `T4.5 add opportunistic cleanup for stale unused candidates`
- acceptance:
- `discarded candidates do not become normal QuizEntry records`
- `candidate cleanup prevents stale unused records from accumulating`
- `answer-context retrieval remains centered on QuizEntry`
- planned_commits:
- `feat(web): add quiz candidate lifecycle`
- `test(web): cover quiz candidate cleanup`

### Slice 5: First Fast Strategy Implementation

- status: `planned`
- branch: `feat/slice-5-quiz-first-fast-strategy`
- pr_title: `feat(slice-5): implement first quiz fast strategy`
- objective: `implement the simplest useful fast strategy after the contract and candidate lifecycle are in place`
- tasks:
- [ ] `T5.1 choose the first strategy from batch, round, tree, or minimal hybrid based on implementation simplicity`
- [ ] `T5.2 generate fast candidates through LLMRequestEngine`
- [ ] `T5.3 enforce deterministic node routing and deep fallback for ambiguous/free-text paths`
- [ ] `T5.4 enforce tree ceiling of 1 -> 3 -> 9 when tree strategy is used`
- [ ] `T5.5 cover fast progression, fallback, and no-local-semantic-matcher behavior`
- acceptance:
- `fast mode can produce a next question with lower perceived latency`
- `ambiguous or semantic paths fall back to deep`
- `the user sees normal quiz interaction, not strategy internals`
- planned_commits:
- `feat(llm): implement quiz fast generation strategy`
- `test(web): cover quiz fast progression`

### Slice 6: Tagging, Observability, and Cycle Closure

- status: `planned`
- branch: `feat/slice-6-quiz-fast-deep-closure`
- pr_title: `feat(slice-6): close quiz fast and deep cycle`
- objective: `finish tagging/provenance behavior, validate both modes, and close the implementation cycle`
- tasks:
- [ ] `T6.1 ensure final tags are applied only after activation and answer interpretation`
- [ ] `T6.2 keep mode/strategy metadata out of context-ranking behavior`
- [ ] `T6.3 add cheap observability for mode, strategy, fallback, and candidate cleanup when useful`
- [ ] `T6.4 update tracker, spec notes, and residual-risk documentation`
- [ ] `T6.5 run targeted web, runtime, LLM provider, and full Rails validation`
- acceptance:
- `discarded candidates do not create retrieval-tag noise`
- `mode/strategy provenance is observability-only`
- `deep and fast flows pass targeted and full validation`
- planned_commits:
- `fix(web): align quiz fast tagging semantics`
- `feat(llm): trace quiz fast and deep decisions`
- `chore(ops): close quiz fast deep question tree cycle`

## Global Exit Criteria

- Deep is the default mode for new quiz rounds.
- Fast is available through a low-profile switch.
- Users do not choose concrete fast strategies.
- Processing feedback applies to both modes.
- Answer and skip expose processing feedback while preserving request/response behavior.
- Fast mode uses an internal strategy through `LLMRequestEngine`.
- No broad local semantic matcher is introduced.
- Generated candidates do not pollute final `QuizEntry` context material.
- Tags are applied after activation and answer interpretation.
- Candidate cleanup is explicit and tested.
- All slice PRs target `dev` and are reviewed independently.

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>`.
- Full Rails validation must run from `apps/web` with `bundle exec bin/rails test`.
- Repository workflow checks must run from repository root with `scripts/agent/tickets/check.sh` when ticket metadata changes.
- Validation entries must include command plus `(pass)` or `(fail)`.
- Each slice PR body must use `Summary`, `Changes`, and `Validation`.

## Non-Goals

- Do not expose batch/tree strategy selection in UI.
- Do not introduce a generic semantic classifier.
- Do not redesign the full quiz page beyond the question/answer interaction surface.
- Do not align `dev -> main` as part of this cycle.
