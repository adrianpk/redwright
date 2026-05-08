# RedWright Quiz Fast and Deep Question Tree Raw Capture

## Status

Raw capture; curated into `2026-05-07-redwright-quiz-fast-deep-question-tree-quiz.md`.

## Purpose

This raw capture preserves the question-and-answer flow behind the curated quiz notes for the RedWright quiz fast/deep question-tree design.

It is polished for spelling and clarity while preserving the user's intent. It is working-memory context, not the final curated artifact.

## Session 2026-05-07

### Q1. Should `fast` exist only for questions with explicit options, or also for limited free text with exact deterministic aliases?

Answer:

RedWright probably cannot reliably distinguish entire question trees that can be resolved through explicit choices. A single use case can include both explicit and less explicit questions. The decision should not be made at the use-case level.

### Q2. When a node cannot be resolved deterministically, should the flow immediately fall back to `deep`, or keep the surrounding tree and use `deep` only for that jump?

Answer:

The core issue is not just technical routing. It is more about user intent and user agency: the user may prefer a faster but less refined flow, or a deeper flow that extracts better data for later context injection.

### Q3. Should `fast` mean no follow-up questions except in critical cases, or limited follow-ups without waiting for one LLM request per step?

Answer:

`fast` means a low-latency strategy, not necessarily one of only two options. It may mean generating all questions in one request, generating a speculative tree of possible question paths, or another strategy that proves effective.

### Q4. Should `fast` be chosen explicitly at quiz start, or should RedWright choose a fast strategy by default and let the user switch to `deep`?

Answer:

Mode choice is not a fixed setup choice. It depends on the user's current mood or tolerance, similar to selecting between an LLM model that is slower and better versus one that is faster and cheaper. It would be useful to change mode during a quiz with a UI switch. For example, around question 10 the user may notice that questions are not relevant enough or that nested opportunities are being missed, then switch modes.

### Q5. When switching to `deep` during a round, should `deep` use all previous answers as context, or only the current question/answer and summarized quiz state?

Answer:

Mode switching should first be evaluated for implementation complexity, but it likely is not too complex. The simple behavior should be immediate switching. An optimization where RedWright finishes an already-generated fast tree before switching can be mentioned only as a future reference, not as a first implementation requirement.

Deep mode should receive previous quiz context, similar in spirit to `/project new`, so it starts with useful bias from prior answers. Recording production mode may be valid and probably not costly.

### Q6. Should the first fast strategy be one-shot full-round generation or speculative tree generation?

Answer:

Possible fast strategies include:

- generating the full set of questions in the first request
- generating batches of `total / n` questions and reloading when exhausted or almost exhausted
- using a speculative tree, which is transversal to the loading strategy and may or may not be the selected way

If generated questions are materialized in persistence and only answers are added later, speculative trees complicate the model because many questions from discarded branches remain unanswered.

### Q7. Should `QuizEntry = question + answer` be preserved, or is a separate generated-question/candidate entity acceptable if it simplifies `fast`?

Answer:

A separate entity is acceptable if it simplifies `fast`, and it probably does. However, it must not generate database garbage. RedWright should either clean unused candidates directly, clean stale records from previous cycles opportunistically, run a post-round cleanup, or use a dedicated cleanup mechanism. A dedicated job reduces responsibility in the question flow but adds moving parts such as jobs or async tasks.

### Q8. Should cleanup use TTL/age, or semantic lifecycle events such as mode change, round completion, or tree discard?

Answer:

The separate entity must not complicate queries. Answers are the primary material for later context injection, so this probably is not a retrieval issue if kept separate. If questions and answers become separate entities, tags, labels, and foreign keys may need to apply carefully to both sides.

In tree mode, selecting one branch naturally prunes sibling branches. Cleanup in the next round or next quiz operation may be cheap enough.

### Q9. Should generated candidate questions have tags immediately, or should tags apply only when a question is activated, answered, or skipped?

Answer:

Tags are ultimately LLM-generated. A question may suggest certain tags, but the answer may not share those tags. For example, a question may invite choosing between three related libraries; the chosen library should drive the answer's tag, not all discarded options.

When using the question/answer tandem, RedWright should avoid retrieval noise from tags attached to discarded branches. Post-tagging is preferred. Existing drafts and specs should be reviewed because this was discussed previously.

### Q10. Should fast-extracted answers be marked as lower confidence or fast-extracted for later context injection?

Answer:

Some questions are answered unambiguously in one step and do not need follow-up. A pragmatic LLM should avoid inventing follow-ups merely because it can. For example, `Do you want white or black?` usually does not need another question.

Fast mode should not automatically imply lower quality. If a tree exists, its amplitude can vary, but it should not go beyond `1 -> 3 -> 9`.

### Q11. Should `fast` metadata affect context injection ranking, or only be stored as provenance/statistics?

Answer:

Do not complicate context injection ranking with this. How a question was obtained is not especially relevant to context retrieval. It may have statistical value, but no more than that in the first design.

### Q12. Should the fast/deep switch change only future generation, or also change the presentation of the current question?

Answer:

The switch should be almost transparent to the user and should not change the quiz dynamic. At most, the user should notice that the next question appears faster.

### Q13. Should the default mode be `deep`, or should RedWright start in `fast` and let the user switch to `deep`?

Answer:

The default should be `deep`.

### Q14. Should the user choose the concrete fast strategy, such as `batch` versus `tree`?

Answer:

No. Do not overwhelm the user with this kind of implementation decision.

### Q15. What metric should determine whether `fast` is worthwhile?

Answer:

The only meaningful metric here is psychological or perceived latency. This idea came from using the current single-mode flow, which is similar to `deep`, and noticing that it sometimes feels slow.

Some UX trick may improve how request processing is perceived. Telegram can feel lighter with the same model because the typing indicator shows that something is being generated.

### Q16. Should perceived-latency UX be a separate slice before fast generation, or part of each slice?

Answer:

The processing feedback contributes to both modes. It is not an alternative to fast mode.

The current quiz flow is traditional request/response navigation. To include something like animation or a processing indicator, RedWright probably needs something like Turbo Streams so only the question/answer area reloads, because that is the part that actually changes.

### Q17. Is there enough clarity to close the quiz and produce a formal spec?

Answer:

Yes. There is no significant remaining topic that justifies extending the round.
