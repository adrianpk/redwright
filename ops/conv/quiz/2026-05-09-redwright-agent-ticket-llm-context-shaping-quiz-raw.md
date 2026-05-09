# RedWright Agent Ticket LLM Context Shaping Quiz Raw

## Status

- type: `quiz-raw`
- date: `2026-05-09`
- state: `closed`
- source_dump: `../dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md`
- related_draft: `../../specs/drafts/2026-05-09-redwright-agent-ticket-llm-context-shaping-draft.md`
- hard_cap: `50`

## Session 2026-05-09

### Context

The quiz is being run from the closed dump on agent ticket LLM context shaping.

The session must ask one question at a time, capture answers incrementally, and later curate the result into `ops/conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz.md`.

### Raw Q&A

#### Q1. Component naming

Question: For the first operational cut, should the component be called and treated as `ExecutionProfileResolver`, meaning something that returns an actionable profile for the harness/context composer, or should another concept/name be preferred to avoid making it sound too execution-specific?

Answer: The name does not sound bad, and neither do other names already chosen for existing entities. At the same time, three-word names in this kind of association have a "Java vibes" feel. This is not a criticism of the expression; it may be the closest phrase to what the system needs to do, and the user accepts it for now. The important priority is correct architecture. Renaming later through search and replace is not expensive if needed.

#### Q2. Minimum execution profile fields

Question: For the actionable profile, what is the indispensable minimum for the first version: only `work_family`, `confidence`, and `context_policy`, or should it also include flags such as `requires_code_changes`, `requires_commands`, `requires_validation`, and `should_ask_clarification` from the start?

Answer: It should include everything already discussed. The goal is to close this cycle with a spec, plan, tracker, and complete implementation. The profile should not be a symbolic minimum; it should be actionable enough to drive the downstream context policy and implementation behavior.

#### Q3. Mixed or uncertain resolver output

Question: When the resolver detects a `mixed` request or several candidate families, should RedWright automatically choose a composite policy, or should it use a broad conservative policy and trace that there was uncertainty?

Answer: If RedWright adds a resolver to improve the heuristic, then applying another manual heuristic on top of that response creates a nested matryoshka of pre-evaluations. The user prefers that the system always return the strongest candidate. RedWright should apply the context injection logic associated with that selected candidate. If that context is insufficient to resolve the request satisfactorily, robustness should come from the complete event loop: compiler errors, lint errors, runtime errors, validation failures, and other feedback should be detected and cause reassessment in later cycles.

#### Q4. Primary family versus mixed operational output

Question: For the first implementation cut, should the profile avoid `mixed` as an operational output and always return a `primary_work_family`, leaving uncertainty only as metadata or trace data such as `confidence`, `runner_up_families`, and `reasoning_summary`? Or should runner-up families also be omitted to avoid contaminating the decision?

Answer: Yes. The operating decision should be the strongest primary candidate. Uncertainty can remain as metadata or trace data rather than becoming a second operational heuristic.

#### Q5. Low confidence fallback

Question: If the resolver has low confidence but still must choose a primary candidate, what should happen: execute with that policy and trust the event loop, or ask for clarification only when the resolver explicitly marks `should_ask_clarification: true`?

Answer: In that case, the system should probably send the complete, loaded context currently used today. Low confidence should fall back to the broad robust context bundle rather than blocking or relying on an overly narrow context policy.

#### Q6. Confidence representation

Question: What should count as low confidence operationally: a textual value from the resolver such as `low`, `medium`, and `high`, a numeric score, or both, where the resolver returns a score but the system acts only on simple bands?

Answer: Use simple bands. Start with `low` as the operational fallback trigger, observe how it behaves, and later modify the setting if the resulting responses are not usually appropriate.

#### Q7. Initial policy families

Question: Should RedWright initially keep the eight candidate families, `exploration`, `implementation`, `modification`, `diagnosis`, `evaluation`, `operation`, `planning`, and `documentation`, as operational categories, or should they be reduced before writing the spec?

Answer: There are several possible ways to dissect the original much larger set. This will probably require trial and error; there is no obvious way to perfectly tune the criterion upfront. At the same time, the important question is not only where the cut is made, but also what context bundle or sum of context layers is associated with each family.

#### Q8. Family configurability

Question: For trial and error, is it acceptable for the spec to define the eight families as initial defaults while requiring them to be configured or isolated so they can later be merged, renamed, or split without rewriting the whole pipeline?

Answer: Yes.

#### Q36. Preclassifier test strategy

Question: For the LLM preclassifier in tests, should RedWright use table-driven fake responses by family/policy to cover all paths without depending on real provider calls?

Answer: Yes.

#### Session close

The user asked whether the quiz really needed to continue to 50 questions. The answer is no: the hard cap is a maximum, not a target. The session has enough clarity to curate the result and stop.

#### Q28. Preclassifier placement

Question: Given that ownership, should the preclassifier live inside `LLMRequestEngine` as an optional first stage, such as `classify -> resolve policy -> build request`, or should it be a prior explicit call that still uses the same engine?

Answer: If it simplifies the architecture, yes, it can live inside `LLMRequestEngine` as an optional first stage.

#### Q29. Backward compatibility and opt-in behavior

Question: To avoid breaking existing consumers such as `QuizLoops`, `ProjectSetupPromptRenderer`, and agent ticket execution, should classification/policy resolution be opt-in per request, so calls without `context_policy_resolution: true` keep working as they do today?

Answer: Yes, although the user does not see why customized context for a specific action would break previous contracts, and the named consumers should also fall into one of the groups. Opt-in is acceptable for compatibility, but action-specific context shaping should be compatible with existing contracts.

#### Q30. Existing action mapping

Question: Should existing engine actions such as `agent_ticket_execution`, quiz generation, and project setup prompt rendering be explicitly mapped to a default policy/family, even if only `agent_ticket_execution` uses dynamic preclassification at first?

Answer: Everything must map to one of the selected families or policies.

#### Q31. Dynamic preclassification scope

Question: For the first complete cycle, which action should use dynamic preclassification first: only `agent_ticket_execution`, or also quiz, documentation, and project setup from the start?

Answer: Everything. The complete cycle must cover the complete solution, as already stated, including making sure that every context type and its construction are fully operational.

#### Q32. Slice count and full solution coverage

Question: Given that everything enters the cycle, is it acceptable for the plan to split into more slices, such as audit/mapping, capability enablement, policy engine, dynamic preclassification, action integration, tracing, and tests?

Answer: This was already answered: yes. More slices are acceptable when needed to cover the complete solution.

#### Q33. Authority order

Question: For authority order, if sources conflict, should RedWright start with this base order: `system_prompt/execution_contract` > `Protocols` > `ticket/prompt` > `current source files/validation output` > `project docs/quizzes/dumps/conversation` > `LLM-derived summaries`, then tune later?

Answer: Try that first, then fine-tune.

#### Q34. Policy tracing

Question: Should each request trace the selected policy, confidence, primary family, included layers, omitted layers, and omission reasons so RedWright can tune behavior later?

Answer: Yes. This is important for debugging and later fine-tuning. RedWright already has request/response tracing, and it should also trace selected policies. Ideally policy selection should be reflected in the same trace so the team can evaluate context policy decisions alongside LLM requests and responses.

#### Q35. Policy and trace tests

Question: Should each policy have unit tests proving which layers it includes and omits for representative cases, plus integration tests verifying the final request trace?

Answer: Yes.

#### Q9. Agent context layer

Question: Should `agent` be an explicit context section sent to the LLM, or is it enough for agent behavior to live in `system_prompt`, `model_role`, and `action` while the rest of the context is handled as sections?

Answer: Keep stable agent instructions primarily in the `system_prompt`, but add a compact explicit section for variable execution context, likely named `execution_contract` rather than a broad narrative `agent` section. Stable instructions such as role, JSON contract, output restrictions, and blocking behavior belong in the system prompt. Variable and traceable operational details such as work family, execution mode, allowed outputs, allowed actions, validation requirement, retry attempt, max attempts, and workspace boundary belong in a compact structured context section. This keeps high-authority instructions in the prompt while allowing the future context policy and execution profile resolver to inject auditable runtime behavior.

#### Q10. Project context inclusion

Question: Should `project` context always be `required`, with levels such as `compact` by default and `expanded` only when the policy asks for it, or can it be omitted for some very local documentation or operation tasks when the ticket includes explicit paths?

Answer: Keep it simple. Project context should be required by default, preferably compact unless a policy needs expanded project details. Avoid sophisticated omission rules for the first implementation.

#### Q11. Protocol inclusion and compaction assumptions

Question: Should `protocols` be treated as `required compact` by default in all families because they are high authority, expanding full `protocol_files` only when the policy or ticket justifies it?

Answer: Do not casually assume `compact` exists as a capability. The model must specify whether a compactor exists, how it runs, when it runs, and whether it runs once or repeatedly. Protocols are also a set of documents, not one monolithic context block. Depending on task type, RedWright may optimize which protocol documents to include. For example, when the agent is generating code, `CONVENTIONS` may be the most important protocol. When making a design decision, `ARCHITECTURE` may also be important.

#### Q12. Protocol document selection versus condensation

Question: To avoid assuming nonexistent compactors, should the first implementation use explicit selection of full protocol documents by policy and leave compaction or summarization as a later separate capability?

Answer: Individual protocol documents should be specific enough in their own form. RedWright should not force arbitrary condensation of those documents. The user understands that for some classifications, having a compact representation of the complete protocol set may eventually be useful, but only if it does not complicate the system unnecessarily. A minimal protocol context could be the whole protocol set represented as one smaller chunk, but this should not replace the usefulness of selecting specific full protocol documents when they are relevant.

#### Q13. Protocol set per work family

Question: Should the first spec define two protocol modes, `selected_protocol_documents` with complete relevant documents, and optionally `protocols_minimal` as a small representation of the whole set only if it already exists or is trivial?

Answer: The important point is not a fixed selected set. For example, when touching code, `LINTING` and `CONVENTIONS` may matter, while `VERSIONING` may not. For a Git operation, `VERSIONING` may matter, while `LINTING` and `CONVENTIONS` may not. These examples are illustrative. The spec needs a reasonably exhaustive evaluation of which protocol documents apply to each work family or group.

#### Q14. Protocols as RedWright system entity

Question: Should the spec include a matrix of `work_family -> required/relevant protocol docs`, using the real protocol/rule docs in this repository as explicit entries?

Answer: No. There may be almost a one-to-one relationship between those repository documents and the protocols RedWright uses in generated projects, but the spec must not fall into that confusion. `Protocols` is a RedWright system entity. RedWright models protocols, and the system currently avoids duplicating them in context by excluding generated protocol files from normal repository scanning. Those files may also be generated into the target repository, but the context path should treat protocols through the modeled protocol entity, not as arbitrary repo files.

#### Q15. Protocol model attributes and implementation evidence

Question: For the matrix by family, should the spec refer to protocols by model attributes such as `key`, `layer`, `title`, `path`, and possibly `purpose` or `tags` if they exist or are added, instead of concrete generated repository paths?

Answer: Exactly. For faithful capture, inspect the current implementation. Use the existing specs and code for everything related to protocols. The spec should be grounded in the actual RedWright protocol model and implementation rather than assumptions.

#### Q16. Documents layer scope

Question: For documents outside Protocols, should they enter this first implementation as a real selectable layer, or should they be left out unless explicitly linked to the ticket or project, to avoid mixing drafts, specs, plans, and trackers with Protocols?

Answer: Everything should be used. A lot is already used. This exercise is for refinement, not for defining the first version of what gets sent. The goal is to prune and optimize the context, not to define context composition from scratch.

#### Q17. Documents selection and context-layer completeness

Question: Given that framing, should the documents criterion be to treat all documents as an available universe, select by relevance according to family/ticket, and trace which documents were selected or omitted and why?

Answer: Exactly. Additionally, at the end of slicing, all injectable context types must be operational, even if this requires increasing the number of slices. The context types that must be accounted for are: agent, project, prompt, concrete files, file tree, Tree-sitter, LLM-based context, docs, quizzes, dumps, and previous conversation. Dumps are not implemented yet, but they must be explicitly tracked as a missing context type.

#### Q18. Capability enablement slices

Question: For context types that are not operational or only partial, such as Tree-sitter, dumps, and possibly LLM-based context, should the spec/plan require explicit capability enablement slices before the pruning/policy slice, or should pruning start with existing capabilities and create follow-up slices for what is missing?

Answer: Yes, the missing or partial context capabilities should be explicitly accounted for in slicing. The implementation plan should include whatever slices are needed to make all injectable context types operational rather than leaving them as ambiguous follow-up work.

#### Q19. Previous conversation scope

Question: Should `previous conversation` include only agent-LLM conversation from the execution loop, or also relevant human-RedWright conversation from the project or ticket when it exists?

Answer: Both. Human conversation is relevant because a human will be involved through the TUI or Telegram.

#### Q20. Conversation and document scope

Question: For conversation and `docs/quizzes/dumps`, should selection be scoped primarily by `project + ticket/use_case` when those links exist, falling back to search or relevance when there is no explicit link?

Answer: Use-case-only or use-case-plus-project scope should depend on the category. As a first approximation, the selection can vary by category. Later, it may become clear that project-wise context is useful enough to send consistently.

#### Q21. Prompt strategy by family

Question: Should `prompt` be treated as always required and non-selectable but composed differently by family, such as implementation prompt, diagnosis prompt, planning prompt, and documentation prompt, or should RedWright use one base prompt with variables from the execution profile?

Answer: The preclassifier is what RedWright is implementing here. It should not produce changes in the real prompt sent to the later request. Its purpose is to help optimize the context injected into the concrete request that follows it. The real prompt should remain governed by the downstream request flow; the preclassification output should drive context selection, not prompt rewriting.

#### Q22. Preclassifier responsibility boundary

Question: Should the preclassifier output be strictly limited to context and capability decisions, without choosing or modifying the main instruction of the later real request?

Answer: Do not add extra responsibilities. The preclassifier decides the optimal context for the concrete request that performs the real action.

#### Q23. Context policy output and implementation shape

Question: Should the preclassifier return the concrete list of layers to inject, or should it return a `context_policy` that another component resolves into concrete layers?

Answer: The preclassifier should return a policy that `LLMRequestEngine` uses. Of course, the engine or downstream code may decide not to follow it exactly, but that is the intended model. Policies should be implemented explicitly in Ruby, either in one Ruby file or, if they live in an individual module, one file per policy.

#### Q24. Policy implementation style

Question: Should policies be declarative Ruby data, such as constant hashes that are easy to test, or classes/objects with logic such as `ImplementationPolicy` and `DiagnosisPolicy` that can make decisions from ticket, project, and runtime state?

Answer: Use the simplest approach that solves the problem. Start with declarative Ruby data if it is enough, and only introduce policy objects or classes when the required logic justifies them.

#### Q25. Low confidence fallback policy

Question: When the resolver returns `low` confidence and RedWright should use the current broad context, should that fallback be explicit, for example as `full_context_fallback`, and tested like any other policy?

Answer: That sounds reasonable.

#### Q26. Avoiding extra context components

Question: `LLMRequestEngine` currently receives `context_sections` and does not compose context. Should policy and layer resolution happen before it in a separate composer/orchestrator, or should part of that responsibility move into the engine?

Answer: Stop adding components. Either `LLMRequestEngine` resolves it, as previously discussed, or the preclassifier resolves it. Do not introduce another component for this responsibility.

#### Q27. Policy resolution owner

Question: Should the preclassifier return `context_policy`, and should `LLMRequestEngine` translate that policy into the context layers that get injected?

Answer: Yes.
