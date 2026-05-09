# RedWright Agent Ticket LLM Context Shaping Quiz Notes

## Status

- type: `questionnaire`
- date: `2026-05-09`
- source: `ops/conv/quiz/2026-05-09-redwright-agent-ticket-llm-context-shaping-quiz-raw.md`
- dump: `ops/conv/dump/2026-05-09-redwright-agent-ticket-llm-context-shaping-dump.md`
- related_draft: `ops/specs/drafts/2026-05-09-redwright-agent-ticket-llm-context-shaping-draft.md`
- state: `closed`

## Purpose

Curated quiz notes refining the execution-profile preclassification and context-policy model for RedWright LLM requests.

The quiz clarifies that the goal is not to define initial context composition from scratch. RedWright already sends substantial context in several flows. The goal is to make context injection more deliberate, policy-driven, traceable, and complete across all injectable context types.

## Sessions

### Session 2026-05-09

#### Context

- The quiz follows the closed dump on agent ticket LLM context shaping.
- The user wants the cycle to lead to a complete spec, plan, tracker, and implementation.
- The scope is broader than agent ticket execution alone: every existing LLM action should map to a selected family/policy, and all injectable context types must become operational.
- The quiz stopped early because sufficient clarity was reached; the 50-question limit is a hard cap, not a target.

#### Current Convergences

- The component name `ExecutionProfileResolver` is acceptable for now, but naming is less important than architectural correctness.
- The resolver should return a complete actionable profile, not a symbolic minimum.
- The resolver should always select the strongest primary family/policy.
- Uncertainty should remain metadata or trace data; it should not trigger nested manual heuristics.
- Low confidence should use an explicit broad fallback policy equivalent to the current loaded context.
- Confidence should use simple bands, starting with `low` as the fallback trigger.
- The initial family set can remain experimental and configurable:
  - exploration
  - implementation
  - modification
  - diagnosis
  - evaluation
  - operation
  - planning
  - documentation
- The family set must be isolated enough to merge, rename, or split later.
- The preclassifier must optimize context injection for the concrete request that performs the real action.
- The preclassifier should not rewrite the prompt or take on unrelated responsibilities.

#### Policy Ownership

- The preclassifier should return a `context_policy`.
- `LLMRequestEngine` should use that policy to decide or influence which context layers are injected.
- Do not add another orchestration component for policy resolution.
- The preclassifier may live inside `LLMRequestEngine` as an optional first stage if that simplifies the architecture.
- Existing actions should map to one of the selected families or policies.
- The complete cycle should cover all relevant existing LLM actions, not only `agent_ticket_execution`.
- Compatibility can remain opt-in where needed, but action-specific context shaping should not break existing contracts.

#### Policy Implementation

- Policies should be explicit Ruby code.
- Use the simplest implementation that solves the problem.
- Declarative Ruby data is acceptable if sufficient.
- Policy classes or objects should be introduced only when required by real logic.
- A low-confidence fallback such as `full_context_fallback` should be explicit and tested like any other policy.

#### Context Layers

All injectable context types must be accounted for and operational by the end of the slicing plan, even if this requires more slices:

- agent
- project
- prompt
- concrete files
- file tree
- Tree-sitter
- LLM-based context
- docs
- quizzes
- dumps
- previous conversation

Dumps are not implemented yet and must be tracked explicitly as a missing context type.

#### Agent And Execution Contract

- Stable agent behavior belongs primarily in `system_prompt`.
- Do not create a broad narrative `agent` context section.
- Add a compact structured context section for variable execution behavior, likely `execution_contract`.
- `execution_contract` should carry data such as work family, execution mode, allowed outputs, allowed actions, validation requirement, retry attempt, max attempts, and workspace boundary.

#### Project Context

- Keep project context simple.
- Project context should be required by default.
- It may be compact by default and expanded by policy when needed.
- Avoid sophisticated omission rules for the first implementation.

#### Protocols

- Do not confuse RedWright Protocols with this repository's `.agents` files.
- `Protocols` is a RedWright system entity.
- The context path should use modeled protocol state, not generated repository files.
- RedWright already avoids duplicate protocol context by excluding generated protocol files from normal repository scanning.
- Protocol selection must be grounded in current protocol specs and implementation.
- Protocols are a set of modeled documents, not one monolithic context block.
- Each work family should be evaluated for which protocol documents matter.
- Example only: code work may need conventions and linting; Git operations may need versioning.
- Individual protocol documents should be specific enough without forced arbitrary condensation.
- A minimal compact representation of the full protocol set may be useful later only if it does not add unnecessary complexity.

#### Documents, Quizzes, Dumps, And Conversation

- Everything should be available for use; this is a refinement/pruning exercise, not first-time context definition.
- Documents should be treated as an available universe and selected by relevance according to family/ticket.
- Selection and omission should be traceable.
- Previous conversation should include both agent-LLM execution-loop conversation and relevant human-RedWright conversation, because TUI/Telegram involve humans.
- Conversation and document scope may vary by category:
  - use-case-only
  - use-case-plus-project
  - possibly project-wise by default later if evidence shows it is consistently useful

#### Prompt Boundary

- The preclassifier does not alter the real prompt sent to the later request.
- The real prompt remains governed by the downstream request flow.
- The preclassifier output drives context selection, not prompt rewriting.

#### Authority Order

Use this initial authority order and tune later:

1. `system_prompt` / `execution_contract`
2. Protocols
3. ticket / prompt
4. current source files / validation output
5. project docs / quizzes / dumps / conversation
6. LLM-derived summaries

#### Tracing And Debugging

- Policy selection must be traced for debugging and tuning.
- Trace data should include selected policy, confidence, primary family, included layers, omitted layers, and omission reasons.
- Policy information should ideally live in the same trace as request/response data so outcomes can be evaluated together.

#### Testing

- Each policy should have unit tests proving included and omitted layers for representative cases.
- Integration tests should verify the final request trace and context injection.
- The LLM preclassifier should use table-driven fake responses by family/policy.
- Tests must not depend on real provider calls.

#### Slicing

- The plan may and should use additional slices when required.
- Missing or partial context capabilities should be explicit enablement slices, not ambiguous follow-up work.
- The cycle must include enough slices to make all context types operational and then apply pruning/policy behavior.

## Provisional Decisions

- Use `ExecutionProfileResolver` as a provisional name.
- Return an actionable execution profile with full fields needed for downstream behavior.
- Always choose a primary policy/family.
- Use `low` confidence to trigger `full_context_fallback`.
- Keep the eight families as initial configurable defaults.
- Preclassifier returns `context_policy`.
- `LLMRequestEngine` uses/resolves the policy.
- Do not add another component for policy resolution.
- All existing LLM actions must map to a policy/family.
- The preclassifier optimizes context only; it does not rewrite prompts.
- Policy tracing is required.
- Unit and integration tests are required.

## Open Tensions

- Exact profile schema still needs final naming and field constraints.
- Exact policy data shape is unresolved.
- Exact mapping from all existing LLM actions to families/policies requires implementation audit.
- Exact protocol model attributes and selector inputs must be verified from code/specs.
- Exact documents/quizzes/dumps selection mechanism remains to be designed.
- Tree-sitter context construction remains missing and needs a capability slice.
- Dumps context is not implemented and needs a capability slice.
- LLM-based context requires clearer definition and operational status.

## Deferred / Out Of Scope

- Naming bikeshedding beyond provisional `ExecutionProfileResolver`.
- Rewriting downstream prompts as part of the preclassifier.
- Adding another context orchestration component beyond the preclassifier and `LLMRequestEngine`.
- Relying on regex or keyword classification as the primary mechanism.

## Open Questions

- What is the exact execution profile schema?
- What is the exact Ruby policy representation?
- What are the complete mappings for all existing LLM actions?
- Which context capabilities are already operational, partial, or missing after code audit?
- What slices are required to make Tree-sitter, dumps, LLM-based context, and human conversation context operational?
- How should selected/omitted context reasons be represented in traces?

## Edit Notes

- This file is intentionally curated and non-final.
- It should feed the next spec refinement, plan, and tracker.
