# Discovery Artifact Contract

This document defines structured quizzes and user-led knowledge dumps. These
artifacts preserve pre-specification context without turning ordinary
conversation into delivery state.

Create a quiz or dump only when authorized under `.agents/ROUTING.md`. Follow
`.agents/LANGUAGE.md` for artifact language.

## Artifact Bundles

Use the `ops-layout/v1` bundle for both artifact types:

```text
ops/<namespace>/<quiz-or-dump>/<NNNNN>-<topic>/
  metadata.json
  artifact.md
  files/raw.md
  evidence/ (optional)
```

- Allocate `<NNNNN>-<topic>` from the namespace-global sequence while holding
  `ops/<namespace>/lock/id.lock`.
- Store curated content in `artifact.md`.
- Store persisted source capture in `files/raw.md`.
- Use `evidence/` only for material evidence that belongs to the artifact.
- Preserve decisions, constraints, tensions, assumptions, and open questions.
- Do not turn raw capture into a polished specification or map it one-to-one
  into the curated artifact.
- Do not create downstream artifacts without separate authorization.

## Quiz Contract

A quiz is a structured, bounded interview for defining or refining a software
engineering use case.

- Ask exactly one question at a time.
- Use a finite candidate set with a hard cap of 50 questions.
- Limit follow-up chains to three levels: primary question, follow-up, and deep
  clarification.
- Stop when the use case is sufficiently clear, the budget is exhausted, or
  further questions have diminishing value.
- Maintain the current question index, remaining budget, topic, nesting level,
  and coverage distribution.
- Prefer information gain and balanced coverage over exhausting the candidate
  set.
- Do not continue exploratory questions after a termination condition.
- Treat a completed curated quiz as sufficient pre-specification alignment
  when it preserves the necessary decisions and open questions. A separate
  specification draft is not mandatory.

The curated quiz contains distilled findings, not a transcript. For a long
session, preserve enough question-and-answer context in `files/raw.md` to avoid
information loss, then curate it into `artifact.md`.

## Dump Contract

A dump is a user-led knowledge transfer with less structure than a quiz.

- Let the user establish the flow and central topic before steering.
- Preserve intent, useful nuance, ownership, and uncertainty while correcting
  obvious language errors.
- Maintain raw capture when the dump is long, spans multiple messages, or is
  likely to feed another artifact.
- Keep derived threads distinct from the central topic.
- Do not invent decisions or flatten derived threads into the main topic.
- Use a quiz when the material requires sustained questioning.

The curated dump records its central topic, source capture, summary, key
concepts, decisions or preferences, tensions, assumptions, derived threads,
possible downstream artifacts, and open questions.

For each derived thread, record its name, origin, relation to the central
topic, likely artifact type, and whether the user authorized immediate work.
