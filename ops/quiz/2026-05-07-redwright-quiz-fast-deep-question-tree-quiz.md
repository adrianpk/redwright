# RedWright Quiz Fast and Deep Question Tree Quiz Notes

## Status

Curated quiz; sufficient clarity reached on 2026-05-07.

## Related Draft

`../specs/drafts/2026-05-07-redwright-quiz-fast-deep-question-tree-draft.md`

## Purpose

Curated quiz notes supporting `2026-05-07-redwright-quiz-fast-deep-question-tree-draft.md`.

## Sessions

### Session 2026-05-07

#### Context

- The web quiz flow was made deterministic and backend-state-driven.
- The quiz question provider should use the existing centralized `LLMRequestEngine`.
- The remaining concern is latency: waiting for one LLM request per next question can make quiz rounds feel tedious.

#### Questions Raised

- Can RedWright ask for more than one future question in a single LLM request?
- Can a request return a shallow question tree such as `1 -> 3 -> 9`?
- Would a background job or prefetch queue improve perceived speed?
- Would speculative generation damage useful nesting and Ariadne-style return behavior?
- How can the system connect a user answer to a speculative branch without introducing another LLM request?
- Should there be two modes, `fast` and `deep`, where `deep` preserves the current behavior and `fast` uses tree-based speculation?
- Can RedWright reliably know ahead of time which question trees can be resolved through explicit choices?
- Is `fast` primarily a technical routing optimization, or a user-facing choice between speed and richer context extraction?
- Which implementation strategies can count as `fast`?
- Should mode be selected once at quiz start, or changed during the quiz?
- Should fast generation materialize questions immediately, and how does that interact with speculative trees?
- Should generated speculative questions have a separate persistence model?
- Should tags apply to generated candidates or only after activation and answer interpretation?
- Should fast-extracted answers be marked differently for later context injection?
- Should the fast/deep switch change the visible question interaction?
- What metric determines whether fast mode is worthwhile?

#### Candidate Answers

- A linear prefetch is weaker than a branched speculative tree because quiz answers can open different valid follow-up paths.
- A tree can be useful when the active question has a bounded answer space.
- A tree is risky for broad free-text questions because local semantic routing would duplicate LLM reasoning.
- `fast` should not be a second semantic engine. It should be deterministic branching over explicit choices or strongly bounded answer domains.
- `deep` remains the correct mode for open-ended answers, ambiguous answers, and unexpected branches.
- A hybrid default can use `fast` when deterministic routing is available and fall back to `deep` when confidence is not structurally guaranteed.
- A whole use case should not be classified as explicit or non-explicit. A single use case can contain both explicit and open-ended questions.
- The decision about deterministic routing must happen at the question or node level, not at the use-case level.
- RedWright should not assume it can reliably identify all explicit-choice-capable trees ahead of time.
- The core distinction is also experiential: the user may choose a faster but less refined flow, or a deeper flow that asks better follow-up questions and produces richer data for later context injection.
- Fast mode may intentionally reduce or avoid follow-up questioning. Its value is lower friction, not maximum extraction quality.
- Deep mode is the higher-quality extraction path for future context injection because it can adapt, reprompt, and refine unclear answers.
- Fast mode is a family of low-latency strategies, not one fixed algorithm.
- Fast mode may mean generating all questions for the round in one request.
- Fast mode may mean generating batches of `total / n` questions and reloading when the batch is exhausted or almost exhausted.
- Fast mode may mean generating a speculative tree of potential question paths.
- Other low-latency strategies may qualify if they reduce per-question waiting while preserving acceptable quiz behavior.
- Batch size and speculative tree shape are separate axes. A batch can contain linear questions, tree-shaped questions, or another structured plan.
- The speculative tree idea is transversal to the loading strategy. It may become the selected strategy, or it may be only one candidate shape.
- Materializing every generated question immediately into persistence is simple for linear batches, but risky for speculative trees because discarded branches would create unanswered questions.
- For speculative trees, persistence may need to distinguish candidate/generated questions from active/current/answered entries.
- An alternative is to persist speculative state as runtime metadata and only create `QuizEntry` records when a question is actually answered, skipped, or otherwise activated.
- A separate generated-question or candidate-question entity is acceptable if it materially simplifies fast mode.
- A separate entity must not create unbounded database garbage.
- Cleanup should be an explicit part of the design. Options include cleaning unused candidates when the round ends, cleaning stale candidates from previous cycles opportunistically, or adding a dedicated cleanup job.
- A continuously running cleanup mechanism can remove responsibility from the question flow, but it introduces additional moving parts such as jobs or async tasks.
- A separate generated-question entity should not make later context retrieval queries significantly more complex.
- Answers are the primary material for later context injection, so candidate questions should not pollute answer-context queries.
- If questions and answers become separate entities, tags, labels, and foreign keys may need to apply to both sides carefully.
- In tree mode, selecting a branch naturally prunes sibling branches.
- Cleanup after branch pruning may be cheap enough to run opportunistically in the next quiz round or next quiz operation.
- Existing quiz references favor post-tagging: `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md` defines tags on `QuizEntry`, and `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md` says LLM-based tag generation should happen during answer interpretation.
- Candidate questions can imply possible tags, but the answer may justify a narrower or different tag set.
- Example: a question may offer `stdlib`, `cobra`, and `urfave/cli` as related Go CLI library choices, but the final answer should be tagged only with the selected library and any answer-specific implications.
- Tagging discarded branches would introduce retrieval noise.
- The preferred direction is post-tagging: apply final retrieval tags when the question is activated and the answer or skip outcome is known.
- Some questions can be answered unambiguously in one step and do not need follow-up.
- A pragmatic LLM should avoid inventing follow-up questions merely because a follow-up is possible.
- Example: `Do you want white or black?` can be fully answered with one clear choice in many contexts.
- Fast mode should not automatically imply lower-quality extraction. The quality depends on whether the question needed adaptation or not.
- If a speculative tree is used, branch factor and depth may vary, but the default hard maximum should not exceed `1 -> 3 -> 9`.
- The LLM can be useful when generating the initial question because it may anticipate whether a later decision tree is likely to be needed.
- Fast/deep provenance should not affect context injection ranking in the first design.
- How a question was obtained is not expected to be meaningful context retrieval data.
- Mode/strategy provenance may have statistical or observability value, but it should not complicate the data model or retrieval logic.
- The fast/deep switch should be almost transparent to the user.
- The quiz interaction dynamics should not change merely because fast mode is active.
- At most, the user should notice that the next question appears faster.
- Fast mode should not require showing extra candidate/options UI unless a question naturally needs options for its own content.
- `deep` should be the default initial mode.
- `fast` should be available as a mode the user can activate during the quiz when lower latency is preferred.
- The user should not choose the concrete fast strategy.
- The UI should not expose choices such as `batch` versus `tree`.
- RedWright should choose the concrete fast strategy internally.
- The primary success metric is psychological/perceived latency.
- The idea came from using the current single-mode flow, which behaves like deep mode and sometimes feels slow.
- Technical metrics such as request count or generation time are secondary unless they correlate with perceived waiting.
- UX feedback during generation may reduce perceived latency without changing the generation strategy.
- Telegram can feel lighter with the same model because the client typing indicator communicates that work is happening.
- The web UI should consider an equivalent processing/typing affordance while the next question is being generated.
- Processing feedback contributes to both deep and fast modes.
- Processing feedback is not an alternative to fast mode; it is a cross-cutting UX improvement.
- This does not need a formal measurement committee. The current user perception is sufficient evidence that the flow can feel slow.
- The current web quiz cycle is traditional request/response navigation.
- To show an animation or processing state effectively, the question/answer area probably needs partial replacement, for example with Turbo Streams.
- The UI should refresh only the area that actually changes instead of relying on full-page navigation for every question transition.
- Mode is not a one-time user-selected setup choice.
- Mode choice depends on the user's current tolerance for latency versus quality, similar to choosing between cheaper/faster and slower/better LLM models.
- The user may start in fast mode and later switch to deep when questions feel shallow or missed nesting opportunities become visible.
- The user may start in deep mode and later switch to fast when the round feels too slow.
- A UI switch for changing mode during the quiz should be evaluated.
- Mode switching should first be evaluated for implementation complexity, but it is expected to be manageable.
- When switching from fast to deep, the simple behavior should be to switch immediately and invalidate or ignore unused speculative state.
- Deferring the switch until an already-generated fast tree is exhausted is a possible later optimization, but probably not worth the first implementation complexity.
- Deep mode should receive previous quiz context, similar in spirit to `/project new`, so it can restart or continue with useful bias from prior answers.
- Recording the production mode of each generated question or persisted answer is likely valid and not expected to be costly.

#### Current Convergences

- Keep `deep` as the current per-question LLM progression model.
- Introduce `fast` as a bounded optimization, not as a replacement for semantic reasoning.
- Avoid complex local semantic matching.
- Prefer explicit choices or stable route ids for fast-mode branch selection.
- Preserve Ariadne thread behavior with branch depth, trunk return, and coverage metadata.
- Keep `LLMRequestEngine` as the central LLM boundary.
- Treat deterministic fast routing as a per-question capability, not a quiz-wide or use-case-wide mode assumption.
- Treat `fast` and `deep` as user-visible intent modes: speed versus richer extraction.
- Treat fast-mode implementation as strategy-pluggable.
- Treat mode as mutable during a quiz round.
- Start new quiz rounds in `deep` by default.
- Expose only `deep` versus `fast`, not individual fast strategies.

#### Open Tensions

- Fast mode may need some UI affordance for explicit choices.
- The UI should avoid making fast mode feel like a different questionnaire product.
- Lack of processing feedback can make deep mode feel slower than it is.
- The same perceived-latency issue can exist in fast mode if the UI gives no feedback during generation or reload.
- Traditional full-page request/response limits what the UI can communicate during question generation.
- A tree request can be more expensive than a single-question request, so the useful cost metric is latency and total round efficiency, not just request count.
- If the first question is open-ended, fast mode may not apply until a later bounded decision point.
- Background prefetch may help perceived speed, but it does not solve semantic branch selection by itself.
- The implementation needs a way to mix explicit and open-ended nodes inside the same quiz flow.
- The design must account for user agency: the user can prefer speed even when extraction quality would be lower.
- Switching modes on the fly may invalidate prefetched or speculative state.
- There is a potential but probably unnecessary optimization where an existing fast tree is allowed to finish before deep mode takes over.
- Persisting generated-but-unanswered questions may affect the current `QuizEntry` meaning, which is currently a question-and-answer tuple.
- Candidate persistence creates lifecycle and cleanup responsibility.
- Splitting generated questions from answers may introduce tag, label, and foreign-key duplication or coordination.
- Context retrieval should remain answer-centered unless a later design proves candidate questions are useful retrieval material.
- Candidate-level hints must not participate in normal context retrieval unless promoted through activation and answer interpretation.
- Marking an answer as fast-extracted may be useful for statistics, but it should not affect retrieval weight.

#### Provisional Decisions

- `keep`: define two modes, `deep` and `fast`.
- `keep`: `deep` is the semantic fallback and remains authoritative for free-text progression.
- `keep`: `fast` only routes deterministically over explicit choices or bounded branches.
- `keep`: speculative trees should carry Ariadne metadata.
- `keep`: explicit-choice routing is a property of an individual question node.
- `keep`: user intent is central to mode choice.
- `keep`: fast mode may be acceptable even when it produces less context refinement.
- `keep`: deep mode is preferred when the goal is stronger context injection material.
- `keep`: do not define fast mode as only tree-based routing.
- `keep`: do not define fast mode as necessarily follow-up-free.
- `keep`: fast mode is strategy-pluggable under one speed-oriented intent.
- `keep`: mode should be changeable during a quiz, not only selected at the beginning.
- `keep`: switching mode should be explicit in the UI when supported.
- `keep`: first implementation should prefer immediate mode switching over delayed tree exhaustion.
- `keep`: deep mode should use prior quiz context after a switch.
- `keep`: store or expose the production mode for generated questions and/or quiz entries.
- `unsure`: whether deferred switching after fast-tree exhaustion is ever worth adding.
- `keep`: treat batch loading and speculative tree shape as separate design axes.
- `keep`: avoid polluting answered-entry persistence with discarded speculative branch questions.
- `keep`: a separate generated-question/candidate entity is acceptable if it simplifies fast mode.
- `keep`: candidate cleanup is mandatory if candidates are persisted.
- `keep`: candidate persistence must not complicate normal answer-context retrieval.
- `keep`: tree branch selection should prune sibling branches.
- `keep`: opportunistic cleanup in the next round or operation is a plausible first cleanup strategy.
- `keep`: prefer post-tagging after activation and answer interpretation.
- `keep`: avoid final retrieval tags on discarded speculative branches.
- `keep`: answer tags should reflect what the user actually chose or answered, not the full option space implied by the question.
- `keep`: not every clear answer requires a follow-up.
- `keep`: fast mode does not automatically mean low-confidence context.
- `keep`: do not make mode/strategy a context-ranking signal in the first design.
- `keep`: store mode/strategy only if cheap and useful for observability or statistics.
- `keep`: fast/deep mode should not change the normal visible quiz interaction.
- `keep`: faster next-question delivery is the main user-visible difference.
- `keep`: default initial mode is `deep`.
- `keep`: `fast` is opt-in during the quiz.
- `keep`: concrete fast strategy selection is internal to RedWright.
- `keep`: perceived latency is the primary success signal.
- `keep`: evaluate UX processing feedback as part of the solution space.
- `keep`: processing feedback applies to both deep and fast modes.
- `keep`: user perception is enough justification for latency UX work.
- `keep`: consider Turbo Streams or equivalent partial updates for the quiz question/answer region.
- `discard`: do not ask the user to choose between fast strategies such as batch and tree.
- `keep`: speculative trees, when used, should have variable shape with a hard default maximum of `1 -> 3 -> 9`.
- `keep`: LLM-generated questions should remain pragmatic and avoid unnecessary follow-up pressure.
- `unsure`: whether cleanup should happen inline at round boundaries, opportunistically during quiz operations, or through a background job.
- `discard`: do not introduce a broad local semantic matcher.
- `discard`: do not classify an entire use case as fast-compatible or deep-only.
- `unsure`: whether fast mode should be default, opt-in, or runtime-selected.

#### Deferred / Out of Scope

- Broad UI redesign for fast mode.
- Background job implementation details.
- Persistence schema details for speculative trees.
- Analytics for measuring fast-mode correctness and savings.
- Exhaustive enumeration of every possible fast strategy.

## Open Questions

- What mode-selection policy should be used first?
- How should RedWright choose the concrete fast strategy internally?
- What web affordance should communicate that the next question is being generated?
- Should the quiz question/answer area become a Turbo Stream-updated region?
- What state needs to be invalidated when switching from fast to deep or deep to fast?
- How should generated-question mode and answer mode be represented in persisted metadata?
- Should generated-but-not-activated questions be persisted as first-class records or stored as quiz runtime metadata?
- If candidates are persisted, what cleanup policy should prevent stale unused records from accumulating?
- Should candidate questions carry non-retrieval hints separately from final retrieval tags?
- Is mode/strategy provenance worth storing for statistics if it does not affect context retrieval?
- How should the UI expose mode switching without changing the quiz interaction model?
- How should the runtime represent mixed flows where one node is explicit and the next node is open-ended?
- What tree depth and branch factor should be allowed by default?
- How should the runtime report fallback reasons in traces and UI diagnostics?

## Edit Notes

- This file is intentionally curated and non-final.
- Keep useful reasoning; remove irrelevant detours.
