# RedWright Quiz Fast and Deep Question Tree Specification

## Metadata

- id: `spec-2026-05-07-redwright-quiz-fast-deep-question-tree`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-07`
- updated: `2026-05-07`
- scope: `rails-web/telegram/quiz/llm/question-routing/perceived-latency`
- derived_from:
  - `ops/specs/drafts/2026-05-07-redwright-quiz-fast-deep-question-tree-draft.md`
  - `ops/quiz/2026-05-07-redwright-quiz-fast-deep-question-tree-quiz.md`
  - `ops/quiz/2026-05-07-redwright-quiz-fast-deep-question-tree-quiz-raw.md`
  - `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
  - `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`

## Problem Statement

The current web quiz flow behaves like a deep per-question LLM loop. It can produce good adaptive follow-up questions, but it can feel slow because each answer may wait for a new LLM-generated next question before the page settles.

The main product problem is perceived latency, not a formal performance metric. Telegram can feel lighter under a similar model because the client typing indicator communicates that work is happening. The web UI currently behaves more like traditional request/response navigation and gives weaker feedback.

RedWright needs a quiz progression model that keeps deep extraction quality by default, allows a faster low-latency mode when the user wants it, avoids exposing internal strategy mechanics, and keeps all LLM calls behind `LLMRequestEngine`.

## Goals

- keep `deep` as the default quiz mode
- introduce `fast` as a user-facing lower-latency mode
- allow mode switching during an active quiz round
- keep the visible quiz interaction mostly unchanged across modes
- make processing feedback apply to both modes
- evaluate partial web updates or processing feedback for the question/answer region without preselecting a frontend technique
- treat `fast` as a family of internal strategies, not a user-selected implementation detail
- support fast strategies such as one-shot round generation, batch generation, and speculative question trees
- avoid a broad local semantic matcher
- preserve Ariadne-style bounded branch and trunk-return behavior
- keep `QuizEntry` focused on activated answered/skipped question-and-answer material
- avoid retrieval noise from speculative or discarded branches
- keep final retrieval tags tied to activated answer interpretation
- keep all LLM-backed generation behind `LLMRequestEngine`

## Non-Goals

- do not replace `LLMRequestEngine`
- do not expose batch/tree strategy selection to users
- do not redesign the whole quiz UI
- do not use fast/deep mode as a context retrieval ranking signal in the first design
- do not tag discarded speculative branches as retrieval material
- do not build a generic local semantic classifier
- do not require a background job unless simple cleanup cannot handle candidate lifecycle
- do not introduce first-class quiz sessions unless a later spec changes the base quiz model

## Modes

### Deep

`deep` is the default mode.

Deep mode:

- asks the LLM for the next question after each answer, skip, or control transition
- uses prior quiz context to bias the next question
- supports adaptive follow-up and trunk return
- remains the best extraction path for rich future context injection
- is authoritative when answers are free-text, ambiguous, unexpected, or semantically rich

### Fast

`fast` is a user-facing low-latency intent.

Fast mode:

- does not define one fixed implementation strategy
- may use one-shot round generation
- may use generated batches with reload on exhaustion or near exhaustion
- may use speculative question trees
- may use another later low-latency strategy if it preserves quiz semantics
- should make the next question arrive faster or feel faster
- should not change normal visible quiz dynamics

The user chooses speed versus depth, not batch versus tree.

## Mode Selection

New quiz rounds start in `deep`.

The user may switch to `fast` during a quiz when lower latency is preferred.

The user may switch back to `deep` during a quiz when questions feel shallow, missed nesting opportunities become visible, or richer extraction is desired.

The switch should be simple and low-profile. It must not turn each question into a configuration flow.

## Mode Switching Semantics

Mode switching affects future question generation.

Already persisted quiz entries remain stable.

For the first implementation:

- `fast -> deep` should switch immediately
- unused speculative fast state may be invalidated or ignored
- RedWright should not defer the switch merely to exhaust an existing tree
- `deep -> fast` may choose an internal fast strategy at the next generation point
- deep generation after a switch should receive prior quiz context

Exhausting an already-generated fast tree before switching is a future reference idea, not a first-version requirement.

## Perceived Latency UX

Processing feedback is part of both modes.

The web UI should communicate that the next question is being generated.

The current full-page request/response flow limits useful in-progress feedback. The quiz question/answer area should be evaluated as a candidate partial-update region, but the implementation should choose the least invasive mechanism from the current Rails app shape rather than preselecting one frontend technique.

The UI should update only the region that changes when possible.

The success signal is perceived responsiveness. Raw request count, generation time, and tree hit rate are useful diagnostics only when they explain perceived waiting.

## Fast Strategy Family

Fast strategy selection is internal to RedWright.

Supported candidate strategies:

- `round`: generate the full planned question set in one request
- `batch`: generate a subset of upcoming questions and reload when exhausted or nearly exhausted
- `tree`: generate a bounded speculative question tree

Batch size and tree shape are separate design axes. A batch may contain linear questions, tree-shaped candidates, or another structured plan.

Speculative trees, when used, may have variable shape but should not exceed the default hard maximum:

```text
1 -> 3 -> 9
```

This is a ceiling, not a target.

## Routing Discipline

Fast mode must not become a second semantic engine.

Deterministic routing is allowed only when an active node has explicit route identifiers or equivalent stable deterministic choices.

If the answer is open-ended, ambiguous, unexpected, out-of-set, or requires interpretation, the runtime should use `deep`.

The deterministic-routing capability belongs to individual question nodes, not to an entire quiz or use case. A single use case may contain both explicit and open-ended questions.

## Follow-Up Discipline

Not every clear answer needs a follow-up.

A pragmatic LLM should not invent follow-up questions merely because it can. RedWright should ask follow-ups only when they materially improve extraction.

Examples:

- a clear binary choice can close in one step
- a library choice may justify a follow-up if the selected library has meaningful downstream implications
- a broad architectural answer likely belongs in deep mode

## Candidate Persistence

`QuizEntry` should remain the primary answered/skipped question-and-answer tuple.

Speculative or generated candidate questions may use a separate persistence model if that materially simplifies fast mode.

If a candidate model is introduced:

- it must stay distinct from `QuizEntry`
- it must not complicate normal answer-context retrieval
- it must not create unbounded database garbage
- unused candidates must have an explicit cleanup policy
- final `QuizEntry` records should be created when a question is activated, answered, or skipped

Runtime metadata remains acceptable when it is simpler than a first-class candidate table.

## Candidate Cleanup

Tree branch selection prunes sibling branches.

Cleanup may be:

- inline at branch selection or round boundary
- opportunistic during the next quiz operation
- job-based only if simple lifecycle cleanup is not enough

The first implementation should prefer local or opportunistic cleanup over new async infrastructure.

## Tags and Context Retrieval

Existing quiz context establishes `QuizEntry` as the tagged question-and-answer tuple.

LLM-based final retrieval tags should be applied during answer interpretation, after a question is activated and the answer or skip outcome is known.

Candidate questions may carry internal non-retrieval hints, but discarded candidates must not receive final retrieval tags.

Answer tags should reflect what the user actually chose or answered, not the full option space implied by the question.

Fast/deep mode should not affect context injection ranking in the first design. Mode or strategy may be stored only if cheap and useful for statistics or observability.

## UI Rules

The quiz interaction should stay mostly transparent across modes.

Fast mode should not expose:

- generated trees
- candidate queues
- batch internals
- strategy selection

The main visible difference should be that the next question appears faster or that generation progress is communicated better.

Options should appear only when the question itself naturally needs options, not because the backend used a fast strategy.

## LLM Boundary

All generation must use `Redwright::LLM::RequestEngine`.

Fast mode may introduce additional structured output contracts, but it must not bypass:

- model resolution
- configured clients
- trace recording
- redaction
- context section composition

## Acceptance Criteria

- New quiz rounds start in `deep`.
- The UI can switch future question generation between `deep` and `fast`.
- The switch does not expose internal fast strategies.
- Processing feedback applies to both modes.
- The question/answer region can be updated without relying on full-page churn where practical.
- Fast strategy selection is internal.
- Fast mode can use at least one low-latency strategy without changing normal quiz interaction.
- Free-text or ambiguous answers are not routed by a broad local semantic matcher.
- Speculative or generated candidates do not pollute final `QuizEntry` retrieval material.
- Final tags are applied after activation and answer interpretation.
- Candidate cleanup prevents stale unused records from accumulating.
- `LLMRequestEngine` remains the only LLM request boundary.

## Open Implementation Decisions

- Which fast strategy should be implemented first: batch, full round, tree, or a minimal hybrid?
- Should generated candidates use a table or serialized runtime metadata in the first slice that needs them?
- What is the smallest interaction surface that delivers useful processing feedback?
- What candidate cleanup rule is simplest in the actual Rails model?
- Which mode/strategy metadata is worth storing for observability without complicating retrieval?
