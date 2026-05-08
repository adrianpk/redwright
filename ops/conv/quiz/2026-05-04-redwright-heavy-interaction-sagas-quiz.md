# RedWright Heavy Interaction Sagas Quiz Notes

## Status

- type: `quiz-notes`
- status: `curated`
- date: `2026-05-04`
- related_spec: `ops/specs/specs/2026-05-04-redwright-heavy-interaction-sagas-spec.md`
- raw_capture: `ops/conv/quiz/2026-05-04-redwright-heavy-interaction-sagas-quiz-raw.md`

## Purpose

These notes preserve the curated reasoning behind the Heavy Interaction Sagas specification. They are not a raw transcript.

The raw capture exists as temporary working memory and keeps the questionnaire flow recoverable. This curated file preserves only the decision-relevant reasoning needed to produce the formal specification.

## Sessions

### Session 2026-05-04

#### Context

- Project Setup is now working close to the envisioned shape, but its implementation shows pressure around modularity.
- The current Project Setup flow includes questionnaire, persistence, materialization, protocol generation, runtime container generation, ticket creation, and workspace materialization.
- The user wants a maintainable architecture for heavy interactions triggered from Telegram, web, or future channels.
- The new quiz playbook was used to conduct a bounded quiz session.
- The user clarified that sagas are broader than questionnaires; a questionnaire is only one possible phase inside a saga.
- The user also clarified that `conv-raw` plus curated `conv` is enough source material for a formal spec, so no separate spec draft is needed.

#### Questions Raised

- Should the target architecture be a general saga pattern or only a Project Setup cleanup?
- Should Rails/application persistence remain the canonical owner of saga state?
- Should all sagas share one generic persistence model, or should each saga keep domain-specific session models under a common contract?
- What fields belong in the common saga contract?
- Should stages be standardized globally or declared per saga?
- Is questionnaire required for every saga?
- Should Project Setup separate questionnaire from materialization more strictly?
- Should materialization be a pipeline of named steps?
- What should materializer step results contain?
- How should partial failure, rollback, preservation, and reconciliation work?
- Should effects have visibility classes such as public, internal, and debug?
- Should prompt text be saga-owned or adapter/renderer-owned?
- How should Telegram handle bounded sub-interactions without creating a nested saga abstraction?
- Should lifecycle operations be exposed through shared application contracts?
- How should Rails RESTful surfaces relate to transport-agnostic verb-noun operations?
- What should the first implementation target be?
- What makes the architecture effort successful?

#### Candidate Answers

- Treat heavy-interaction sagas as a general architectural pattern, not only as Project Setup cleanup.
- Keep Project Setup as the first reference saga because it is the first and only current case, and probably one of the most complex.
- Use domain-specific saga/session models first, but require a common saga contract.
- Preserve a future option for generic saga persistence if repetition later justifies it.
- Use a full common shape with `state`, `stage`, `status`, `turns`, `effects`, `next_prompt_intent`, `terminal_reason`, and `metadata`.
- Let each saga declare its own stage taxonomy.
- Reuse shared stage vocabulary only when it naturally fits.
- Treat questionnaire as optional per saga.
- For sagas that include questions, require bounded questionnaire planning.
- Make Project Setup questionnaire collect and normalize context only.
- Move domain object creation into materialization.
- Make materializers step-based.
- Let step results support status, data, effects, errors, and reconciliation hints, without forcing ceremony on simple steps.
- Preserve saga/questionnaire context by default on partial failure.
- Ask users whether to preserve partial state for later continuation or discard/clean up created artifacts when failure leaves useful partial state.
- Classify effects by visibility.
- Keep `next_prompt_intent` structured and adapter-neutral.
- Let Telegram render concise prompts and web render richer forms/cards from the same structured intent.
- Avoid modeling mini-sagas or nested sagas for Telegram subloops initially.
- Preserve external command/query response shapes and Telegram behavior during refactors unless a spec explicitly changes them.

#### Current Convergences

- RedWright should use a general heavy-interaction saga pattern.
- Rails/application persistence remains canonical for saga state.
- Telegram and web are adapters over shared application behavior.
- Domain-specific saga session models are preferred initially.
- All saga models should follow a common contract.
- A questionnaire is not mandatory for every saga.
- If a saga includes a questionnaire, it must be bounded and planned according to the quiz playbook.
- Project Setup is the first reference saga, not proof that all sagas will share the same shape.
- Project Setup should separate context collection from materialization.
- Materialization should be implemented as a pipeline of named steps.
- Each materializer step should have one responsibility.
- Robust step result structure is preferred, but lightweight results are allowed where appropriate.
- Saga context should survive materialization failure by default.
- Rollback or cleanup should be explicit when it would delete useful state or artifacts.
- Effects should support visibility classes, including debug.
- Prompt intent should be structured; human-facing wording belongs to adapters/renderers.
- Internal bounded interaction segments can be represented through normal state, turns, and prompt intent for now.
- The architecture should improve modularity, observability/debugging, and future saga creation.
- Refactors must be conservative and contract-preserving.
- A formal spec should precede implementation/refactor slices when feasible.

#### Open Tensions

- Future sagas may or may not share enough shape to justify a stronger common stage taxonomy.
- A generic shared saga persistence model may eventually become useful, but it is premature now.
- The exact boundary between Rails RESTful controllers and internal verb-noun application operations should follow existing codebase direction rather than theory.
- The right amount of required structure in step results may vary by saga complexity.
- Some future workflows may be simpler than Project Setup and may fit as one-step sagas.

#### Provisional Decisions

- `keep`: define a general heavy-interaction saga architecture.
- `keep`: use Project Setup as the first reference saga.
- `keep`: keep Rails/application persistence as canonical saga state.
- `keep`: keep Telegram and web as adapters/interfaces.
- `keep`: start with domain-specific session/turn models.
- `keep`: define a common saga contract across those domain models.
- `keep`: make questionnaire optional per saga.
- `keep`: require bounded questionnaire planning when a saga uses questions.
- `keep`: separate questionnaire/context collection from materialization.
- `keep`: define materializers as named step pipelines.
- `keep`: support robust step results with status, data, effects, errors, and reconciliation hints.
- `keep`: preserve saga context by default on failure.
- `keep`: offer preserve-versus-discard reconciliation when partial artifacts exist.
- `keep`: classify effects with visibility such as public, internal, and debug.
- `keep`: expose structured `next_prompt_intent` and let adapters render channel-specific UI/copy.
- `keep`: avoid nested-saga terminology and modeling for now.
- `keep`: preserve existing external contracts during refactor unless explicitly changed by spec.
- `keep`: improve modularity, observability, and future saga creation ergonomics.
- `defer`: generic shared saga persistence.
- `defer`: global fixed stage taxonomy.
- `defer`: exact class names and slice decomposition until planning.

#### Deferred / Out of Scope

- implementing the refactor directly from quiz notes
- generic workflow engine DSL
- shared saga database tables
- exact class/module names for every future saga
- changing Telegram behavior as part of architecture cleanup
- changing command/query response shapes without explicit implementation spec coverage
- final web UI design for saga inspection

## Open Questions

- Which exact Project Setup responsibilities should be extracted first during the implementation plan?
- Should a later generic saga model be introduced after at least two or three sagas exist?
- Which effect visibility values are sufficient beyond `public`, `internal`, and `debug`?
- Should lightweight internal `segment` metadata be added when web progress UI needs it?
- How should preserve-versus-discard reconciliation be represented in each channel?

## Edit Notes

- This file was curated from `2026-05-04-redwright-heavy-interaction-sagas-quiz-raw.md`.
- The raw capture preserves the questionnaire flow; this file preserves the distilled architectural decisions.
- No separate spec draft is required for this topic because the questionnaire raw capture and curated quiz notes provide the pre-spec alignment artifact.
