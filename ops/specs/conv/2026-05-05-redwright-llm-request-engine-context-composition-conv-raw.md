# RedWright LLM Request Engine Context Composition Raw Conversation

## Status

- type: `questionnaire-raw`
- date: `2026-05-05`
- source: bounded questionnaire session for the LLM request/context composition draft
- draft: `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
- cap: `50 questions`
- state: `closed`

## Working Notes

This raw capture preserves the questionnaire answers in polished English while the alignment session progresses. It is working memory for later curation into a canonical `...-conv.md` artifact.

## Answers

### Q1. Module Boundary

Question: Should `LLMRequestEngine` be strictly a context/request composer, without calling the provider or persisting history, or should it be a higher-level facade that composes, calls the provider, and delegates recording/tracing internally?

Answer: The request engine and the recording/tracing mechanism should remain decoupled, even if they deal with related concepts. From the caller's point of view, especially a controller or service, they sit at different ends of the operation: one prepares the LLM request, while the other observes and records what happened after the interaction. A different perspective may later justify a higher-level facade that coordinates both, but the core components should not be collapsed into one object.

### Q2. Caller Input Shape

Question: Should callers pass a rich structured request object with fields such as `project_id`, `ticket_id`, `use_case_id`, `task_type`, tags, source, and raw text, or should the engine receive minimal input and resolve most normalization and context lookup internally?

Answer: If these values are already available in the current cycle, RedWright should not waste them. The engine should accept structured inputs when the caller has them. `project_id` is especially important because without it the agent's ability to produce useful project-scoped behavior is heavily restricted. There may eventually be features that need non-project-scoped LLM requests, but project scope should be the normal and preferred path.

### Q3. Required Scope

Question: Should `project_id` be required for all normal task types in the first version, with an explicit special category such as `global_request` or `system_request` for non-project-scoped cases?

Answer: It is difficult to decide definitively at this stage. Most RedWright operations are expected to be project-scoped, project-plus-use-case-scoped, or project-plus-use-case-plus-tag-scoped. However, future Telegram interactions may include useful general questions, such as asking about a language, library, framework, or provider detail. Those requests should not necessarily be forced into a project. Project scope should be the operational default, but not a universal requirement.

### Q4. Task Taxonomy

Question: Should the first spec define a small closed taxonomy of initial task types, or an extensible taxonomy where the system starts with a few types but can tolerate new values without redesigning the engine?

Answer: The first implementation should have a limited scope and add task types only when there is a real need. RedWright should avoid taxonomy overengineering. At the same time, the model should leave room to grow. A small set of constants, effectively enum-like, is enough for the first version.

### Q5. Initial Task Types

Question: Which task types are essential for the first spec: `ticket_implementation`, `refinement`, `documentation_edit`, `quiz_question_generation`, `status_query`, `planning`, or others?

Answer: The initial answer is uncertain. A ticket does not necessarily mean implementation only; it may represent a feature, hotfix, bug, documentation task, or other work. The same work kinds may also happen outside a ticket. This suggests that RedWright may need more nuance than a single flat `task_type`, possibly two levels of grouping: one for the operational container or source, and another for the kind of work being requested.

### Q6. Two-Level Task Classification

Question: Should the spec model two separate axes, such as `request_mode: ticket` plus `work_kind: documentation`, instead of trying to express everything through one `task_type`?

Answer: Yes. The need for two levels is becoming evident. RedWright should distinguish the operational mode or container from the kind of work being requested.

### Q7. Core Context Sections

Question: Which context sections should be core concepts in the first version, even if some are empty: `agent_context`, `project_context`, `request_context`, `ticket_context`, `protocol_context`, `quiz_context`, `workspace_context`, `execution_context`, `previous_interactions`, and `output_contract`?

Answer: The sections through `quiz_context` appear indispensable as core sections: `agent_context`, `project_context`, `request_context`, `ticket_context`, `protocol_context`, and `quiz_context`. `workspace_context`, `execution_context`, `previous_interactions`, and `output_contract` may also be relevant, but they need clearer definitions before being classified. In particular, previous interactions may be useful, but it is not yet obvious whether it is cheaper to run a preflight request to decide whether they are needed or simply include them under bounded conditions.

### Q8. Workspace Context

Question: Should `workspace_context` in the first version mainly be a cheap structural repository summary, such as a tree and candidate files, leaving snippets, symbols, and Tree-sitter data for a more selective layer?

Answer: For coding tasks, including implementation and bug correction, `workspace_context` is indispensable. The LLM cannot reliably express what the agent should materialize if it cannot refer to new or existing files that need to be created or changed. This context should have nested semantics rather than being a flat tree only. It may include file tree data, selected file excerpts, Tree-sitter data, LSP data, dependency information, generated documentation, language or framework documentation, project docs, symbol maps, relevant configuration files, and similar sources. Iterative loops also need related validation signals, but those signals may belong more naturally to `execution_context` than to `workspace_context`.

### Q9. Execution Context

Question: Should `execution_context` be modeled as a core section for work loops, but left empty or omitted for initial requests until commands, tests, linting, compilation, normalized errors, or validation output exist?

Answer: Yes. This connects to `workspace_context` and invites a cleaner separation. Some details initially described as workspace context may belong under `execution_context`, especially lint errors, compile errors, test failures, command output, normalized failures, and validation state. `execution_context` should be available as a core section for iterative work loops, but it does not need to be populated in initial requests before execution has produced useful signals.

### Q10. Documentation Context

Question: For coding tasks, should external or generated documentation such as `godoc`, `yard`, framework docs, gem or library READMEs, and API docs be a subpart of `workspace_context`, or a separate `documentation_context` section that the engine can include or omit through its own policy?

Answer: Documentation deserves to be promoted to its own context section. It should not be buried under `workspace_context`. A separate `documentation_context` lets the engine select, shrink, omit, or prioritize documentation according to task needs.

### Q11. Output Contract

Question: Should `output_contract` always be explicit in every LLM request, even when minimal, to avoid responses that are difficult for the agent to materialize?

Answer: Yes. A response without a schema or semantic shape is not actionable enough. Even for future needs that are not yet envisioned, such as concrete Telegram questions about a language, library, framework, or provider, every LLM response should include a semantic layer that the agent can interpret and use to return the useful part to the user. The final rendered response may be human-friendly text, but the underlying response should still be structured enough for RedWright to act on it.

### Q12. Previous Interactions

Question: Should `previous_interactions` start as a section included only in loops with clear continuity, such as ticket work, refinement, and previous errors, while being omitted by default for simple or new requests?

Answer: Real MVP usage will reveal the specific need. Existing OSS harness systems appear to commonly include prior context, at least in compact form, because it helps avoid asking again about things that were already resolved. RedWright should stay pragmatic here: previous interactions are probably useful, but their inclusion policy should be validated through actual use rather than overdesigned upfront.

### Q13. Previous Interactions Granularity

Question: When `previous_interactions` is included, should it almost always be a compact rolling summary instead of raw messages or full request-response records?

Answer: This should probably be configurable through an internal constant or policy setting, not necessarily through user-facing YAML or dynamic settings at first. Intelligent compaction may be just as effective as raw history, but that assumption needs concrete testing. RedWright should compare outputs on real cases before deciding whether compact summaries, raw records, or a hybrid shape works best.

### Q14. Recorder Storage

Question: Should the first recorder for previous interactions use transient filesystem storage under `tmp/redwright/context/`, or Rails/SQLite persistence so interactions can be queried by project, use case, tag, and ticket from the beginning?

Answer: Transient filesystem storage is probably better for the first implementation. A relational model is attractive because it could enable intelligent selection and cherry-picking of previous interactions, avoiding unrelated deviations in the next prompt. This is an important future direction. However, SQLite may not be robust or ergonomic for writing and querying large text blocks, and a graph database is also attractive for this kind of relationship-heavy context but does not fit naturally into a Rails-centered implementation. A dedicated database would add too much complexity. The first version should therefore prefer `tmp` storage, but it must include pruning or post-use cleanup so the filesystem does not accumulate garbage.

### Q15. Transient Scope

Question: For transient storage under `tmp`, what should the minimum correct scope be: `run_id`, `ticket_id`, `agent_session`, or a combined structure such as `project/ticket/run`?

Answer: An agent identifier alone may be incomplete because the same agent may eventually perform more than one operation at a time, which would mix conversations. A ticket is also not enough because the agent may operate outside a ticket. `agent_session` is closer, provided RedWright defines the session scope correctly. A good starting point is `agent + session`, where the session is a specific combination of operation type and operation identifier. Operation types may include ticket work, direct queries, or similar request containers.

### Q16. Session Identity Ownership

Question: Should the conversational session identifier be generated by RedWright as a formal runtime entity, or is it enough to derive it deterministically from fields such as source, request mode, project, ticket, use case, query, timestamp, or run ID?

Answer: This is still open. The important boundary is that controllers should not own conversational scope generation. It may also be questionable whether the agent itself should generate its own conversational scopes. A reusable service or runtime boundary used by controllers and agents may be the right owner for generating or resolving these scopes.

### Q17. Scope Resolver Component

Question: Should the spec define a separate component such as `LLMRequestSessionResolver` or `ConversationScopeResolver`, used before `LLMRequestEngine`, to produce `session_id`, `scope_type`, `scope_id`, and isolation metadata?

Answer: The responsibility appears separate, but RedWright should avoid an excessive proliferation of Java-like managers, handlers, and resolvers. The spec can name the responsibility and boundary without forcing a heavy class taxonomy too early.

### Q18. Preflight Use

Question: Should preflight LLM calls exist only for complex coding or ticket tasks, or also for interactive requests when the engine does not know which context to select?

Answer: The answer is partly speculative. Preflight calls make sense as context selectors. They may also be useful as query customizers. In other projects, it has been practical to give the LLM a relational schema, available fields, and possible values, then ask it to produce query criteria for retrieving projects, tickets, and question-answer pairs that match the current need. This may be overkill in RedWright, and deterministic algorithms may cover many cases, but preflight query customization has proven useful elsewhere. Any generated query intent should still be validated and executed by deterministic application code.

### Q19. Preflight Limits

Question: Should the spec impose an initial hard limit on preflights per request, such as a default maximum of one, with more allowed only for explicit multi-step background work?

Answer: This is difficult to decide before the landscape is clearer. Preflight calls may differ depending on which context they help resolve. A preflight for selecting question-answer pairs is not the same as a preflight for another context source. The spec should distinguish preflight categories before imposing a rigid global cap. A simple limit may still be useful later, but it should not assume all preflight calls are equivalent.

### Q20. Policy Source

Question: Should context section inclusion and omission rules live first as Ruby constants or code policies, or as editable YAML/database configuration from the beginning?

Answer: These rules should not be something the user has to configure in the MVP. Exposing them can give curious users flexibility, but it risks turning RedWright into a tool that constantly requires sharpening and customization. The product should avoid that pattern at this stage. Context policy should live in code first.

### Q21. Context Budget

Question: Should the first spec include approximate numeric budgets per section, or is it enough to define priority and trimming order without explicit numbers at the beginning?

Answer: This is important but not yet clear. Trimming context can easily make an LLM response unusable or ineffective if the cut removes the information that made the request actionable. RedWright should analyze this separately rather than pretending token trimming is simple. One possible approach is to resolve large-context needs through successive request loops, possibly with nested or staged information, instead of only cutting sections by size. This remains an open design area.

### Q22. Authority Order

Question: Should the base authority order be current user or ticket request, repository state, protocols and project docs, execution results, ticket metadata, Quiz answers, previous interactions, and then old traces or generated notes?

Answer: The newest and most operationally relevant source should generally win. With that clarification, this authority order is acceptable as a starting point. RedWright should also support an explicit loop outcome for contradictions: instead of blindly choosing one source and continuing, the next phase may request confirmation, ask for clarification, or report the conflict.

### Q23. Conflict Handling

Question: When the engine detects a strong contradiction between sources, should it return a built request with a `conflicts` section, or should it return a `needs_clarification` state without calling the main LLM yet?

Answer: RedWright should handle strong contradictions explicitly. The answer confirms the need for this behavior, but the exact mechanism still needs clarification.

### Q24. Conflict Clarification Path

Question: Which default is better: `needs_clarification`, where RedWright does not call the main LLM and asks for clarification, or a `conflicts` section, where RedWright calls the main LLM but explicitly shows the contradictions?

Answer: This is a difficult tradeoff because most interactions are expected to be ticket-based, autonomous loops where no human is necessarily watching the underlying process. Clarification cannot assume synchronous human presence. The Kanban ticket model needs a comments area, and comments need the ability to reference users. Even if RedWright is single-user at first, the administrator or lead user should be mentionable. A mention should trigger a notification that can eventually escalate, through configuration, to Telegram or another pluggable messaging system such as Slack or email. Conflict handling may therefore need to create a ticket comment, mention the lead user, and put the ticket into a blocked or waiting state when autonomous resolution is not safe.

### Q25. Autonomous Conflict Default

Question: If a ticket loop finds a strong but non-critical conflict, should it continue with a `conflicts` section and reserve `needs_clarification` or a ticket comment for conflicts that block progress or risk violating an explicit constraint?

Answer: This cannot be answered with confidence yet. The default between continuing with explicitly surfaced conflicts and blocking for clarification remains an open design decision.

### Q26. Safety and Redaction

Question: Should the first spec require secret and PII redaction or filtering before any context is injected, or are textual prompt guardrails enough at the beginning?

Answer: Redaction and filtering are vital day-zero policy requirements. RedWright should implement the most effective practical protection possible from the beginning, not rely only on textual guardrails in the prompt.

### Q27. Prompt Injection from Retrieved Context

Question: Should every external or retrieved section be labeled as untrusted evidence, including repository files, docs, Quiz answers, previous interactions, and traces?

Answer: This is a valid concern. Repository content can contain prompt injection-like instructions, whether accidental or malicious. At the same time, RedWright must operate inside the project, and treating the project's own documents and files as too untrusted could make the workflow overly frictional. The spec should recognize the risk and require priority/authority labeling, but it should avoid making normal project operation feel paranoid or unusable.

### Q28. Authority Labels

Question: Is a softer model acceptable: do not label everything as untrusted, but wrap retrieved sections with explicit authority labels such as `repository_evidence`, `project_protocol`, and `historical_interaction`, each with clear priority?

Answer: Yes, if those labels give the LLM useful signals for making authority decisions. This is acceptable as long as it does not make the implementation too convoluted.

### Q29. Context Allocation Report

Question: Should the first future implementation focus only on building the `LLMRequestEngine` and producing both the final request/context packet and an internal context allocation report explaining what was included or omitted, without integrating every caller yet?

Answer: A context allocation report should be mentioned as a potential helper, but not treated as a central requirement. Much of that visibility may be derived from the future official request/trace persistence component. A flag that dumps request composition details to a rolling file may satisfy much of this need. That mechanism may eventually replace or absorb the current request/response tracer in the app, but the recorder/tracer needs an official name and boundary.

### Q30. Recorder Naming

Question: For the separate component that records request, response, and context metadata, which name is preferable: `LLMRequestRecorder`, `LLMInteractionRecorder`, `LLMRequestTrace`, `LLMTraceRecorder`, or another name?

Answer: `LLMTraceRecorder` is the preferred name. `LLMRequestRecorder` focuses too much on requests only. `LLMInteractionRecorder` correctly suggests request and response, but is longer. `LLMRequestTrace` names the trace artifact more than the responsibility of recording it. `LLMTraceRecorder` is short and communicates the recording responsibility well.

### Q31. First Integration Point

Question: Which real caller should use `LLMRequestEngine` first: Quiz question generation, Telegram general planner, ticket loop, or project setup saga?

Answer: Eventually all LLM request callers should use it. RedWright should avoid replicating incomplete request-building logic across multiple places. The engine exists to centralize this responsibility for every feature that needs LLM requests.

### Q32. Incremental Migration

Question: Even if all callers should eventually use the engine, should the implementation plan migrate callers one by one, starting with the smallest and most controllable caller, to avoid a large refactor in one slice?

Answer: Yes. That is a different concern from the final architecture. There are not many places where RedWright currently makes LLM requests, so incremental migration is practical. Project initialization is one possible early caller, though it may not exercise complex context aggregation scenarios.

### Q33. Provider Adapter Boundary

Question: Should `LLMRequestEngine` be a request builder only, returning a neutral object for callers to send later, or should it perform the LLM request itself?

Answer: `LLMRequestEngine` should not be just a builder that returns a request object and makes the caller responsible for sending it. The caller should ask the engine to perform the LLM request. The engine may compose the request and coordinate provider invocation, while recording/tracing remains a separate responsibility.

### Q34. Provider Adapters

Question: If `LLMRequestEngine` performs the LLM request, should it delegate sending internally to the existing provider adapters while keeping a single public API such as `call(...)` or `perform(...)` for callers?

Answer: The engine should use the operational parameters RedWright already uses. The system currently distinguishes between at least two configurable LLM roles: one for coding-oriented tasks and another for non-coding tasks such as writing. A user may configure the same model for both roles. The current provider focus is OpenAI, Kimi, DeepSeek, and OpenRouter, with OpenRouter also serving as a route to providers that are not directly supported.

### Q35. Model Role Selection

Question: Should `coding` versus `non_coding` model role selection derive mainly from `work_kind` and `request_mode`, or should the caller be allowed to force a model or role when it already knows what it needs?

Answer: RedWright should not delegate this responsibility to the user, at least in the first iteration and probably not later either. The system should decide the appropriate model role. The exact mechanism is not yet clear. It may depend on policy, request classification, or preflight behavior, but this needs further design.

### Q36. Internal Caller Override

Question: Even if the user does not choose the model, should an internal caller be allowed to pass an explicit intent such as `model_role: coding` when the case is obvious, such as ticket implementation or code review?

Answer: Yes. Internal callers may pass explicit model role intent when the case is clear. This should remain an internal system decision rather than a user-facing responsibility.

### Q37. Response Shape

Question: Since `LLMRequestEngine` executes the request, what should it return to the caller: the raw provider response plus parsed semantic response, or only a normalized RedWright response with raw data available for tracing and debugging?

Answer: The response shape is an important open concern. Since this component is not meant to be reusable across unrelated projects, RedWright can simplify by returning one normalized response shape designed for its own internal callers. The goal should be a single schematized response form that works across RedWright's expected caller types, rather than exposing provider-specific raw responses as the primary interface.

### Q38. Normalized Response Fields

Question: What minimum fields are needed for the normalized response? A possible base is `status`, `semantic_payload`, `rendered_text`, `provider_metadata`, `usage`, `warnings`, and `raw_response_ref`.

Answer: The proposed direction is acceptable, but the final implementation should determine the exact required fields. The spec should express the need for a normalized RedWright response and identify likely fields, without pretending the complete shape is known before implementation pressure reveals it. Raw provider response access is useful for debugging, but should probably be controlled by a YAML-configurable flag or equivalent internal setting. Raw response details should not leak into user-facing Telegram or web messages as ugly flash-style errors.

### Q39. Failure Modes

Question: Should the engine normalize provider errors, schema parse failures, safety redaction failures, timeouts, empty responses, invalid semantic payloads, and similar failures into its own response statuses?

Answer: Yes, this would be cleaner. Even though RedWright is a single-user app and raw details may be useful during debugging, user-facing channels should not display crude provider errors by default. A normalized failure surface is preferable for caller logic, debugging, and overall implementation discipline, with raw details available only through configured diagnostics or trace output.

### Q40. Trace Recorder Coupling

Question: After `LLMRequestEngine` returns a normalized response, who should invoke `LLMTraceRecorder`: the engine internally, the caller, or a higher-level wrapper/service that coordinates both?

Answer: A coordinating service should invoke `LLMTraceRecorder`. If there is no such service in a given path, the responsible controller may do it as a fallback. The trace recorder should remain outside the engine.

### Q41. Orchestration Service

Question: Should the coordinating service have its own generic name in the spec, such as `LLMInteractionService`, to coordinate the engine, provider result, and trace recorder, or should the spec avoid naming it for now?

Answer: The spec should not introduce a generic coordinating service name for this. The coordination belongs to whichever business service is using the LLM. It is outside the scope of the new entities to know where or how they will be used.

### Q42. Engine Public API

Question: Should the public API of `LLMRequestEngine` expose one generic entry point such as `call(request:)`, or several semantic entry points such as `ask_for_quiz_question`, `classify_request`, and `plan_ticket`?

Answer: The preferred direction is semantic methods with explicit parameters. Ruby does not have true multiple dispatch, but RedWright can approximate lightweight dispatch through symbols, keyword arguments, and pattern matching where useful. The engine API should not be reduced to one opaque generic request call if named methods can express intent more clearly.

### Q43. Semantic API Scope

Question: If the engine exposes semantic methods with parameters, should those methods be few and high-level by LLM operation type, or many and close to each concrete business use case?

Answer: The engine should remain relatively business-agnostic. It does not need external-project decoupling or reusable abstraction that makes it harder to use inside RedWright, but it also should not encode particulars based on which business caller is using it. Semantic methods should describe general LLM operation shapes rather than caller-specific business workflows.

### Q44. Initial Operation Taxonomy

Question: Which general operations should the first engine API recognize, such as `generate_text`, `generate_structured_response`, `classify`, `summarize`, `plan`, `review`, `ask_with_context`, or a smaller taxonomy?

Answer: This should not be answered upfront because doing so would likely introduce operations that are not actually required. The spec should avoid inventing a fixed taxonomy before implementation pressure or real caller integration proves which operation shapes are needed.

### Q45. First Real Caller

Question: To avoid inventing an abstract taxonomy, should the spec require the first engine version to be designed against one initial real caller, while keeping the resulting API from being coupled to that caller?

Answer: The initial project-creation questions are the most obvious candidate example, but they may not be representative of the heavier context growth that will be needed later. The spec may use that path as an initial concrete reference, but should avoid treating it as proof that the final context-composition problem has been fully exercised.

### Q46. Caller Count For Initial Design

Question: Should the spec say that the first implementation must include at least two contrasting callers to validate the engine shape, such as a lightweight project setup caller and a heavier context caller, or should the initial scope stay on one caller?

Answer: The initial scope should stay on one caller. The engine should expand only when concrete need justifies the additional scope.

### Q47. Input Contract And Dependency Direction

Question: For the first caller, should the engine receive already prepared explicit data through keyword arguments, or should it be allowed to fetch part of the context itself from repositories, configuration, or project state?

Answer: The engine should receive explicit data from the outside rather than fetching context by itself. The design should follow an onion architecture direction: outer layers call inward, not the reverse. Business services or controllers may gather the required repositories, configuration, and project state, then pass the relevant inputs into the engine.

### Q48. Internal Engine Dependencies

Question: Under that onion architecture rule, may `LLMRequestEngine` depend on pure internal components such as builders, normalizers, token budgeters, and provider adapters, as long as they do not depend on external services or repositories?

Answer: This is acceptable if it is needed, but the implementation should not feel compelled to create entities, managers, handlers, or similar abstractions by habit. Internal components are allowed when they remove real complexity or clarify responsibilities, not as default ceremony.

### Q49. Code Location And Namespace

Question: Where should this new piece initially live: inside the existing LLM/provider area if one exists, in an application/services folder, or in its own namespace such as `Redwright::LLM`?

Answer: The preferred direction is a dedicated namespace such as `Redwright::LLM`. The physical file location should still follow the repository's existing Ruby structure and loading conventions, but the conceptual boundary should be represented through that namespace.

### Q50. Minimum Spec Deliverable

Question: What final decision should be explicit to close this questionnaire: what is the minimum deliverable of the future `LLMRequestEngine` and `LLMTraceRecorder` spec?

Answer: The minimum deliverable should be simple and easy to plug into the existing codebase so it can replace current LLM calls. The spec should prioritize a practical integration surface over exhaustive modeling, with the engine and trace recorder shaped around replacing real existing calls cleanly.
