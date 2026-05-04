# RedWright Heavy Interaction Sagas Raw Questionnaire Notes

## Status
Raw capture

## Scope
Architecture alignment for heavy interaction sagas triggered from Telegram or web, starting from the Project Setup saga and considering reuse for future MVP sagas.

## Edit Notes
- Answers are normalized for spelling, grammar, and clarity.
- Preserve user intent even when wording is cleaned up.
- This raw capture remains working memory; the curated counterpart is `2026-05-04-redwright-heavy-interaction-sagas-conv.md`.

## Session State
- question_cap: 50
- questions_asked: 28
- current_topic: completion criteria
- nesting_level: 1
- status: closed

## Question Set Outline
- Architecture scope and generality
- Relationship between Project Setup and future sagas
- Stage model and persistence needs
- Questionnaire boundaries
- Materialization boundaries
- Effects and response contracts
- Transport neutrality across Telegram and web
- Failure/retry/reconciliation model
- Extensibility without premature workflow-engine abstraction

## Raw Turns

### Q1
Question: Should the target architecture start as a general pattern for any heavy saga in the system, or as a concrete Project Setup improvement that leaves generalization prepared but not formally established yet?

Answer: The architecture should be a general pattern. Some future workflows may be resolved with a single interaction and may not strictly need a saga, but it can still be cleaner to wrap them in the general saga model as one-step sagas. Specific exceptions can be considered later during implementation iteration.

Extracted signal:
- Prefer a general heavy-interaction saga architecture, not only a Project Setup refactor.
- One-step sagas are acceptable for consistency.
- Exceptions are possible later, but should be deliberate rather than the default.

### Q2
Question: In the general saga pattern, should Rails/application persistence be the canonical owner of saga state, with Telegram and web acting only as transport adapters?

Answer: Yes. This follows the same direction already started in RedWright. The architecture is not completely new and should not change this principle.

Extracted signal:
- Rails/application persistence remains the canonical owner of saga state.
- Telegram and web stay as transport/interface adapters.
- The saga architecture must extend the existing application-core direction, not introduce a competing state owner.

### Q3
Question: Should the general saga architecture use one shared persistent saga/session model for all heavy interactions, or should each saga keep its own domain-specific session model while following a common contract?

Answer: The initial inclination was toward a shared generic model, but domain-specific session models following a common contract are the pragmatic starting point.

Extracted signal:
- Choose domain-specific saga/session models initially.
- Define a common saga contract across those models.
- Keep a future generic shared model possible if repeated structure justifies it.

### Q4
Question: What should be mandatory in the common saga contract: state/stage/status only, or also turns, effects, next prompt intent, terminal reason, and metadata?

Answer: Use the fuller contract. The common shape should include state, stage, status, turns, effects, next_prompt_intent, terminal_reason, and metadata. Not every saga must use every field heavily, but the shape should exist for transport parity, debugging, and future saga consistency.

Extracted signal:
- Common saga contract should be complete enough for UI, Telegram, debugging, and audit.
- Single-step sagas can still fit the contract with minimal turns/effects.
- `next_prompt_intent` is part of the contract because prompt text must remain adapter/rendering-specific.

### Q5
Question: Should sagas share a small common stage taxonomy, or should every saga define entirely domain-specific stages?

Answer: It is hard to answer precisely. Future sagas may have very different scopes, or they may not, but we do not yet have enough visibility to know which will be true.

Extracted signal:
- Do not overcommit to a rigid shared stage taxonomy now.
- The architecture must leave room for future sagas with different shapes.
- Stage modeling should be explicit, but probably not exhaustively standardized before more saga types exist.

### Q6
Question: Should the spec define a flexible rule where each saga must declare its own stage taxonomy, while recommending a small shared vocabulary only when it naturally fits?

Answer: Yes. Future specs can change this if it proves inappropriate, but the expectation is that this flexible model will likely remain.

Extracted signal:
- Each saga should explicitly declare its stage taxonomy.
- Shared stage vocabulary is optional and should be reused only when natural.
- This is a provisional but preferred architectural direction.

### Q7
Question: In Project Setup specifically, should the questionnaire phase only collect/normalize setup context, leaving all object creation to a separate materialization phase?

Answer: Yes. Prefer a clear separation. If the current code does not fully enforce it, the architecture should mark that as something to fix. The goal is polished architecture, modularization, and clear directories/packages/modules so the project remains maintainable.

Extracted signal:
- Questionnaire should collect and normalize context only.
- Persistent domain object creation belongs in materialization.
- The spec should explicitly call out current coupling as a refactor target if present.
- Maintainability and modular structure are first-class goals.

### Q8
Question: Should each saga materializer be a pipeline of named steps, where each step has one responsibility and returns a structured result?

Answer: Yes. Materializers should be pipelines of named steps with one responsibility each and structured results. Additional clarification from the previous answer: not every saga necessarily needs a questionnaire, or at least not a large one. Some sagas may be resolved with a single interaction or one question-and-answer turn.

Extracted signal:
- Saga materialization should be step-based.
- Each step should have a clear responsibility and structured output.
- Questionnaire is optional per saga; the architecture must support no-questionnaire or one-turn sagas.
- Project Setup has a questionnaire, but that should not be generalized as mandatory for all sagas.

### Q9
Question: What should every materializer step return at minimum: status plus data only, or also effects, errors, and rollback/reconciliation hints?

Answer: Prefer the robust approach, but do not force every field in contexts or sagas where that would be overkill.

Extracted signal:
- Step result shape should support status, data, effects, errors, and reconciliation hints.
- Use the complete shape when useful, especially for complex materialization.
- Allow lightweight results for simple sagas/steps to avoid unnecessary ceremony.

### Q10
Question: When a materializer pipeline fails after some steps succeeded, should the default behavior be rollback when safe, or preserve partial state and mark the saga as needing reconciliation?

Answer: If state includes persisted information such as questions and answers, it would be undesirable to lose it because a later step failed. A confirmation step inviting the user to preserve or discard partial state could be a clean approach.

Extracted signal:
- Do not discard valuable persisted context by default.
- Questionnaire answers and saga context should usually survive materialization failure.
- Cleanup/rollback may be appropriate for some created artifacts, but should be careful and explicit.
- A user-facing confirmation step for preserve/discard may be desirable after partial failure.

### Q11
Question: Should failed materialization default to preserving all saga context and only ask for confirmation before deleting or rolling back created domain artifacts?

Answer: Yes. The interaction should ask whether the user wants to preserve the partial state to continue later or discard it.

Extracted signal:
- Preserve saga/questionnaire context by default.
- On partial materialization failure, ask the user whether to preserve partial state for later continuation or discard created artifacts.
- Reconciliation should be user-visible and explicit when cleanup would destroy useful work.

### Q12
Question: Should saga effects be treated as an audit/output contract returned to clients, or as internal implementation details that adapters may ignore?

Answer: It depends on the case.

Extracted signal:
- Effects should not be assumed to have one universal visibility level.
- Some effects may be public/auditable client output.
- Some effects may be internal implementation details.

### Q13
Question: Should saga effects include an explicit visibility/classification field, such as `public`, `internal`, or `debug`, so each adapter can decide what to render or ignore?

Answer: Yes. That differentiation can be very useful. `debug` is especially useful, similar to functional pipeline debug taps where a step exists only to inspect or debug while returning the same value that entered the step.

Extracted signal:
- Effects should support visibility/classification.
- Useful classes include public, internal, and debug.
- Debug effects can act as explicit observability points without changing saga behavior.

### Q14
Question: Should sagas expose `next_prompt_intent` as structured intent only, leaving each adapter/renderer to decide the exact human-facing wording?

Answer: Yes, but without a clear view yet of how this decision affects the system.

Extracted signal:
- Prefer structured prompt intent over hardcoded transport-specific prompt text inside sagas.
- The spec should explain the practical impact and boundaries of this decision.
- User-facing copy can remain renderer/adapter-owned, but this needs clarity.

### Q15
Question: Is the intended practical effect that web can render forms/cards while Telegram renders one concise message, both from the same structured saga intent?

Answer: Yes. Telegram actions will likely decompose into bounded loops inside the main loop because resolving multiple concerns in one Telegram response is not ergonomic and can become chaotic. This can be understood as a mini-saga inside the main saga, but avoid adding unnecessary terminology.

Extracted signal:
- Same structured saga intent should support different channel renderings.
- Web may render richer grouped UI.
- Telegram should favor concise, bounded sub-interactions.
- The architecture should support internal interaction segments without introducing heavy terminology.

### Q16
Question: Should the saga contract support these bounded internal interaction segments explicitly, while still presenting them externally as normal stage/state progression?

Answer: Yes. Do not model mini-sagas as a new entity for now. Use `stage`, `state`, `turns`, and `next_prompt_intent`. If later needed, a lightweight `segment` concept can be added for internal progress such as step 2 of 4.

Extracted signal:
- Avoid adding a new nested-saga abstraction now.
- Existing saga contract should handle bounded internal interaction through state, turns, and prompt intent.
- Keep room for a lightweight `segment` field later if UI/progress needs justify it.

### Q17
Question: Should each saga define its own bounded questionnaire plan up front, following the new questionnaires playbook, instead of letting questions emerge without a finite candidate set?

Answer: Yes.

Extracted signal:
- Any saga that includes questions should define a bounded questionnaire plan up front.
- Questions should not emerge as an unbounded ad hoc process.
- The questionnaires playbook applies only to the questionnaire portion of a saga.

### Q18
Question: What lifecycle capabilities should every heavy-interaction saga support even when it has no questionnaire phase?

Answer: It should support steps or a series of steps that clearly share one common aggregator/scope. This can be inferred from the existing Project Setup flow: asking about what will later be materialized is not the same as materializing it. It is not logical to put everything into a single function or entity.

Extracted signal:
- A saga is a scoped sequence of related steps.
- Conceptually different phases should remain separated.
- The existing Project Setup flow is the reference example.
- Avoid single-function/single-entity accumulation.

### Q19
Question: Should the minimal lifecycle contract be: start, advance, materialize/execute steps, complete, fail/reconcile, cancel, and inspect current state?

Answer: Yes, as a practical starting point.

Extracted signal:
- Minimal lifecycle likely includes start, advance, execute/materialize steps, complete, fail/reconcile, cancel, and inspect current state.
- Keep this as a practical starting contract rather than a rigid universal law.

### Q20
Question: Should every saga expose its lifecycle through command/query operations, so Telegram and web call the same application contract?

Answer: We are already doing this, so continue in that direction. Rails is naturally RESTful, or close to it, and it is not desirable to force command/query where it is unnatural in Rails controllers/actions. For Rails-agnostic internal modules, prefer verb-noun command/query style.

Extracted signal:
- Continue exposing saga lifecycle through shared application contracts.
- Do not force command/query naming into Rails UI/controller layers where REST is more natural.
- In transport-agnostic/internal application modules, verb-noun operations are appropriate.
- Web and Telegram should still converge on the same application behavior.

### Q21
Question: Should the spec define two boundaries: RESTful Rails controllers for web/resource UI, and verb-noun saga commands/queries for transport-agnostic application operations?

Answer: Look at what exists so far and continue conceptually on that path, while leaving the codebase better than we found it: better architecture and better modularity.

Extracted signal:
- Do not impose a theoretical Rails-vs-command/query boundary detached from current code.
- Preserve the current direction where it works.
- Improve architecture and modularity incrementally.
- Let codebase reality guide exact boundaries.

### Q22
Question: Should the first architectural improvement target Project Setup materialization, because it is the current point where responsibilities are most accumulated?

Answer: The existing behavior is starting to work as envisioned. Refactor for modularity only where it is not well modularized already, and ensure tests preserve existing contracts.

Extracted signal:
- Refactoring should be conservative and contract-preserving.
- Do not disrupt working behavior just to chase abstraction.
- Target clear responsibility accumulation only.
- Tests must protect behavior before/while modularizing.

### Q23
Question: Should a saga architecture refactor preserve current external command/query response shapes and Telegram behavior unless a spec explicitly changes them?

Answer: Yes.

Extracted signal:
- Refactors must preserve current command/query response shapes by default.
- Telegram behavior must remain stable by default.
- Contract changes require explicit spec coverage.

### Q24
Question: Should this alignment produce a formal saga architecture spec before any implementation/refactor slices begin?

Answer: Ideally yes. We can evaluate concretely at the start of the refactor whether that path is possible.

Extracted signal:
- Prefer producing a formal saga architecture spec before implementation.
- Validate feasibility when the refactor begins.
- Do not start implementation directly from conversation without formalization if avoidable.

### Q25
Question: Should the spec focus on architecture and contracts only, leaving exact class names and slice decomposition for the later plan?

Answer: Architecture and modularization matter. Exact class renames can be deferred, but if doing things correctly requires moving entities and that movement creates a better taxonomy and conceptual homogeneity, then it should be done.

Extracted signal:
- The spec should cover architecture, contracts, and modular taxonomy.
- Cosmetic renames are not the main goal.
- Structural moves are acceptable when they improve conceptual homogeneity and maintainability.
- Later planning can decide exact slices, but the spec should not avoid naming architectural boundaries.

### Q26
Question: Should the first implementation pass be limited to Project Setup as the reference saga, while designing boundaries so future sagas can follow the same pattern?

Answer: Yes. Project Setup is the reference case because it is the first and only saga currently available, and probably the most complex one.

Extracted signal:
- Use Project Setup as the reference saga for the first implementation.
- Do not treat Project Setup as proof that all future sagas have the same shape.
- Complexity in Project Setup can validate the architecture, but future sagas may be simpler.

### Q27
Question: What would make this architecture effort successful: cleaner modules only, or also clearer observability/debugging and easier future saga creation?

Answer: All of it: cleaner modules, better observability/debugging, and easier future saga creation. The initial motivation was cleaner modules, and that still matters a lot.

Extracted signal:
- Success criteria include modularity, observability/debugging, and future extensibility.
- Cleaner modules remain a high-priority driver.
- The architecture should improve both code structure and operational understanding.

### Q28
Question: Do we have enough alignment to stop the questionnaire and curate this into a draft/spec direction, or is there one more architectural uncertainty you want to clarify first?

Answer: There is not much more to add. The questionnaire can be considered closed.

Extracted signal:
- Stop the questionnaire at 28 questions.
- Move from raw alignment toward curated conversation/spec direction.
- No additional exploratory questions are needed now.
