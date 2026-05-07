# RedWright Quiz Fast and Deep Question Tree Draft

## Status

- type: `spec-draft`
- date: `2026-05-07`
- source: engineering alignment conversation about reducing quiz latency while preserving adaptive follow-up behavior

## Quiz

- `../../quiz/2026-05-07-redwright-quiz-fast-deep-question-tree-quiz.md`

## Scope

This draft captures a possible optimization for RedWright quiz progression:

- keep the current adaptive per-question behavior as a `deep` mode
- introduce a faster mode for bounded question spaces
- evaluate whether a single LLM request can return a small speculative question tree
- preserve Ariadne-style trunk and branch behavior
- avoid introducing fragile local semantic matching as a replacement for LLM reasoning

This draft does not authorize implementation by itself.

## Source Context

The current quiz flow can use `LLMRequestEngine` to generate each next question through centralized LLM request infrastructure. That restores correctness and traceability, but each answer may require waiting for another LLM call before the next question appears.

The user raised the possibility of returning a small tree from one request, for example `1 -> 3 -> 9`, and selecting the next question locally when possible.

The main concern is that connecting arbitrary free-text answers to speculative questions without an additional LLM call can require a fragile local semantic matcher. That is precisely the kind of parallel reasoning mechanism RedWright should avoid.

The user clarified that the fast/deep split is not only a technical routing concern. It also represents user intent and user agency:

- `fast` means less waiting and lower interaction latency. It may or may not reduce refinement depending on the selected strategy.
- `deep` means better extraction, better follow-up questions, and stronger future context injection.
- Mode preference can change during a quiz. It is closer to choosing an LLM model based on current tolerance for cost and latency than to selecting a permanent quiz configuration.

The primary problem is perceived waiting. The current flow can feel slow in the web app, while a similar Telegram interaction can feel lighter because the typing indicator communicates that generation is in progress. Processing feedback should contribute to both `deep` and `fast`; it is not an alternative to fast generation.

The current web flow behaves like traditional request/response navigation. To show meaningful processing feedback and avoid full-page churn, the quiz question/answer area may need to become a partial-update region, for example through Turbo Streams.

## Working Notes

### 1) Two Runtime Modes

- provisional_status: `keep`
- current issue:
  - The current deep flow is accurate but can feel slow because each progression step may wait for a new LLM call.
  - The user may not always want the most refined extraction path.
- desired behavior:
  - Support a `deep` mode that asks the LLM for one next question at a time.
  - Support a `fast` mode as a family of low-latency strategies.
  - Treat mode selection as a user-facing tradeoff between speed and extraction quality.
  - Allow mode changes during the quiz when the user wants to trade speed for depth or depth for speed.
  - Start quiz rounds in `deep` mode by default.
  - Let the user switch to `fast` when lower latency is preferred.
  - Do not ask the user to choose the concrete fast strategy.
  - Keep strategy selection internal to RedWright.
  - Keep both modes behind one quiz runtime/provider contract rather than duplicating quiz engines.

### 1.1) Fast Strategy Family

- provisional_status: `keep`
- current issue:
  - Fast should not be overdefined as only a question tree implementation.
  - Fast should not be overdefined as necessarily follow-up-free.
- desired behavior:
  - Allow multiple fast strategies under one mode contract.
  - Include one-shot round generation as a valid candidate strategy.
  - Include batch generation as a valid candidate strategy, with reload on exhaustion or near exhaustion.
  - Include speculative question trees as a valid candidate strategy.
  - Treat batch loading and tree shape as separate design axes.
  - Leave room for other low-latency strategies if they reduce per-question waiting without breaking quiz semantics.
  - Evaluate strategy quality by latency, extraction loss, determinism, traceability, and compatibility with Ariadne-style routing.
  - Hide strategy selection from the user.

### 2) Fast Routing Should Be Node-Level

- provisional_status: `keep`
- current issue:
  - A speculative tree is only useful if the next branch can be selected without another LLM request.
  - A complex local semantic matcher would duplicate reasoning and introduce opaque failure modes.
  - RedWright cannot assume that a whole use case is explicit-choice-friendly or open-ended.
  - A single use case can contain both explicit and non-explicit questions.
- desired behavior:
  - Decide deterministic routing at the individual question or tree-node level.
  - Route by deterministic choice identifiers, not by broad free-text interpretation.
  - Allow explicit and open-ended nodes to coexist in the same quiz flow.
  - Fall back to deep mode when the active node cannot be routed deterministically.

### 3) Deep Mode Remains the Semantic Path

- provisional_status: `keep`
- current issue:
  - Some answers open branches that cannot be known ahead of time.
  - Example: a Go CLI library answer may lead to valid follow-ups about `stdlib`, `cobra`, `urfave/cli`, configuration, subcommands, plugin systems, or undecided constraints.
- desired behavior:
  - Let deep mode handle semantic interpretation and unexpected branching.
  - Let fast mode accelerate only the portions that are safe to precompute.
  - Allow automatic `fast -> deep` fallback without losing quiz state.
  - Prefer deep mode when the explicit goal is high-quality context extraction for later injection.

### 3.1) User Agency and Extraction Quality

- provisional_status: `keep`
- current issue:
  - A technically optimal extraction flow may be too slow or too tedious for the user.
  - A fast flow may intentionally skip useful follow-ups.
  - The user's tolerance for slowness and desire for refinement can change during the same quiz.
  - Some answers are unambiguous in one step and do not benefit from follow-up.
- desired behavior:
  - Let users choose or signal whether they want speed or depth.
  - Make the product semantics clear: fast mode is lower friction, deep mode is richer context capture.
  - Provide a UI-level switch or equivalent affordance for changing mode during the quiz.
  - Do not automatically treat fast mode as low confidence.
  - Do not use mode as a context retrieval ranking signal in the first design.
  - Treat mode or strategy as optional provenance for statistics or observability only.
  - Avoid complicating persistence merely to record how the question was obtained.
  - Ask follow-ups only when they materially improve extraction.
  - Avoid generating follow-ups just because the LLM can invent one.
  - Preserve enough metadata to know which quiz entries came from fast or deep extraction.

### 3.2) Mode Switching

- provisional_status: `keep`
- current issue:
  - A user may notice around question 10 that fast-mode questions are not relevant enough or that useful nested opportunities are being missed.
  - A user may also decide that deep mode is too slow and switch back to fast.
- desired behavior:
  - Support changing mode on the fly.
  - Keep already answered entries stable.
  - Prefer immediate mode switching for the first implementation.
  - Invalidate or ignore speculative fast state that no longer matches the selected mode.
  - Do not defer a fast-to-deep switch merely to exhaust an already-generated tree unless later evidence shows the extra complexity is worthwhile.
  - Mention deferred tree exhaustion only as a future reference point, not as a first-version requirement.
  - Pass previous quiz context into deep mode after a switch, following the same broad principle already used by `/project new` style context-aware progression.
  - Record mode changes for later audit and context-quality interpretation.
  - Record the mode that produced each generated question or persisted answer when practical.
  - Keep the switch simple and visible without turning every question into a configuration flow.
  - Keep the question interaction model nearly unchanged across modes.
  - Let faster next-question delivery be the main visible effect of fast mode.

### 3.3) Generated Question Persistence

- provisional_status: `keep`
- current issue:
  - Linear one-shot or batch generation could materialize questions and later attach answers.
  - Speculative trees can generate questions for branches that are never selected.
  - Persisting every speculative branch question as a normal quiz entry would create unanswered records for discarded branches.
  - The current `QuizEntry` meaning is a question-and-answer tuple, so speculative questions may not fit that model.
  - A separate candidate entity may simplify fast mode, but it can create stale unused records.
  - A separate candidate entity must not make later context retrieval queries significantly more complex.
  - Tags, labels, and foreign keys may need careful placement if questions and answers become separate persistence concepts.
  - Existing quiz references define tags on `QuizEntry` and place LLM-based tag generation in the answer interpretation flow.
  - A generated question may imply several possible tags, while the user's answer may justify only one or a different set.
- desired behavior:
  - Avoid polluting `QuizEntry` with inactive speculative questions.
  - Allow a separate generated-question or candidate-question entity if it simplifies fast mode.
  - Create normal entries only when a question is answered, skipped, or explicitly activated.
  - If a persistent generated-question model is introduced, keep it distinct from answered quiz entries.
  - Keep answer-centered context retrieval simple.
  - Prefer post-tagging after activation and answer interpretation.
  - Do not attach final retrieval tags to discarded speculative branches.
  - Allow candidate questions to carry non-retrieval hints if useful, but keep final context tags tied to the activated question/answer outcome.
  - Require an explicit cleanup strategy for unused candidates.
  - Consider inline cleanup at round boundaries, opportunistic cleanup during quiz operations, or a background cleanup job.
  - Avoid adding jobs or async tasks unless the cleanup lifecycle cannot stay simple.

### 3.4) Tree Pruning and Cleanup

- provisional_status: `keep`
- current issue:
  - In tree mode, selecting one branch makes sibling branches obsolete.
  - Persisted candidates from discarded branches can become garbage if not pruned.
- desired behavior:
  - Treat branch selection as a pruning point for sibling candidate branches.
  - Prefer cheap opportunistic cleanup in the next quiz round or operation if immediate cleanup is not necessary.
  - Keep cleanup local to quiz candidate state before introducing broader async cleanup infrastructure.

### 4) Ariadne Thread Preservation

- provisional_status: `keep`
- current issue:
  - Speculative branching can cause a quiz to overfit to a local branch and lose broader coverage.
- desired behavior:
  - Every branch should carry explicit trunk-return metadata.
  - Follow-up depth should remain bounded.
  - If a speculative tree is used, allow variable shape but keep the default hard maximum at `1 -> 3 -> 9`.
  - The runtime should be able to resume broader coverage after a branch is exhausted or no longer useful.

### 4.1) Pragmatic Follow-Up Discipline

- provisional_status: `keep`
- current issue:
  - An LLM can always invent a reason to ask another question.
  - RedWright should not reward unnecessary questioning.
- desired behavior:
  - Let a single unambiguous answer close a question when no useful refinement is needed.
  - Bias generated questions toward pragmatic extraction.
  - Use trees or follow-ups only when the answer space or downstream context need justifies them.

### 4.2) UI Transparency

- provisional_status: `keep`
- current issue:
  - Fast mode could accidentally become a separate interaction design if it exposes candidates, branches, or implementation mechanics.
- desired behavior:
  - Keep fast/deep mostly transparent to the user.
  - Do not change normal quiz dynamics solely because fast mode is active.
  - Show options only when the question itself naturally needs options, not because the backend used a fast strategy.
  - Avoid exposing speculative candidates or tree mechanics in the quiz UI.
  - Provide lightweight processing feedback while the next question is being generated.
  - Treat typing/processing affordances as part of the latency solution space.
  - Apply processing feedback consistently across deep and fast modes.

### 4.3) Success Signal

- provisional_status: `keep`
- current issue:
  - Request count, raw generation time, and tree hit rate are measurable, but they are not the user's primary complaint.
  - The real issue is that waiting can feel slow.
- desired behavior:
  - Optimize for perceived responsiveness.
  - Treat the current user's perception as sufficient evidence; do not require a formal study before improving the interaction.
  - Use technical metrics only as diagnostics or supporting evidence.
  - Evaluate whether better web feedback can improve perceived speed even before deeper generation strategy changes.

### 4.4) Partial Update Surface

- provisional_status: `keep`
- current issue:
  - Full-page request/response navigation makes it hard to display a useful in-progress state during question generation.
  - The question/answer area is the part that changes on each quiz turn.
- desired behavior:
  - Evaluate making the quiz question/answer area a partial-update surface.
  - Prefer updating only the changing region when moving between questions.
  - Consider Turbo Streams or an equivalent Rails-native mechanism for processing feedback and question replacement.

### 5) Request Engine Boundary

- provisional_status: `keep`
- current issue:
  - Quiz question generation must not bypass centralized LLM infrastructure.
- desired behavior:
  - `LLMRequestEngine` remains the request boundary for both modes.
  - Fast mode changes the structured response schema, not the LLM integration path.
  - Tracing should identify mode, strategy, tree size, fallback usage, and branch decisions.

## Open Questions

- Should `fast` be opt-in per quiz, per use case, or selected automatically by the runtime?
- How should RedWright choose the concrete fast strategy internally?
- What web affordance should communicate that the next question is being generated?
- Should the quiz question/answer area become a Turbo Stream-updated region?
- How should the UI expose a fast/deep switch during the quiz?
- What state should be invalidated when switching modes?
- How should generated-question mode and answer mode be represented in persisted metadata?
- Should generated-but-not-activated questions be persisted as first-class records or stored as quiz runtime metadata?
- If generated candidates are persisted, should cleanup be inline, opportunistic, or job-based?
- Should candidate questions carry non-retrieval hints before activation?
- Is mode/strategy provenance worth storing for statistics if it does not affect context retrieval?
- How should the UI expose mode switching without exposing tree or batch internals?
- How should a generated tree declare which nodes support deterministic routing and which nodes require deep interpretation?
- How should fast-mode tree state be persisted: on `Quiz`, as a dedicated state object, or as structured current-question metadata?
- Should speculative trees be generated synchronously on the first question request, or asynchronously after the current question is shown?
- What is the smallest tree shape that gives useful speed improvement without excessive prompt cost?

## Out of Scope

- Replacing `LLMRequestEngine`.
- Building a generic semantic classifier.
- Adding broad background job infrastructure unless required by the final implementation plan.
- Redesigning quiz UI layout beyond controls needed for explicit-choice questions.
- Introducing first-class quiz sessions unless a later decision changes the existing quiz model.

## Next Iteration Inputs

- Compare current `QuizLoops::Runtime`, `QuestionProvider`, and prompt intent metadata with the proposed mode strategy.
- Verify whether project setup or Telegram flows already encode reusable explicit-choice routing.
- Define a concrete response schema for `deep` and `fast`.
- Decide the first implementation shape for deterministic fast branching.
