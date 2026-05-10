# Cycle Plan: RedWright LLM Context Shaping

## Metadata

- cycle_id: `2026-05-09-redwright-llm-context-shaping`
- status: `completed`
- owner: `adrianpk`
- created: `2026-05-09`
- updated: `2026-05-09`
- goal: `Implement task-aware LLM context shaping across RedWright request flows, including execution profile resolution, policy-driven context injection, missing context capabilities, tracing, and tests.`
- scope: `full_project`
- source_spec: `ops/specs/specs/2026-05-09-redwright-agent-ticket-llm-context-shaping-spec.md`

## Delivery Strategy

This plan intentionally uses multiple slices because the specification requires a complete solution, not a narrow first pass. The cycle must leave every injectable context type operational or explicitly implemented inside the cycle.

Execution must follow the slice delivery protocol:

- execute one slice at a time
- use one branch per slice
- target `dev`
- keep one conventional commit per tracker task during implementation
- update the tracker with validation outcomes
- do not merge later slices before earlier dependencies are closed

## Slice List

### Slice 1: Audit Current LLM Actions And Context Sources

- status: `completed`
- branch: `fix/slice-1-llm-context-audit`
- objective: `Inventory every LLM action, current context source, and current request-engine caller before changing behavior.`
- tasks:
- [x] `T1.1 Inventory all RedWright LLM actions and request-engine call sites.`
- [x] `T1.2 Inventory current context layers per action, including names, authorities, bytes, and trace behavior.`
- [x] `T1.3 Document capability status for agent, project, prompt, concrete files, file tree, Tree-sitter, LLM-based context, docs, quizzes, dumps, previous conversation, and protocols.`
- acceptance:
- `An audit artifact exists under ops/artifacts with all known LLM actions mapped to current context inputs.`
- `Each context type is classified as operational, partial, missing, or conceptual.`
- `No runtime behavior changes are introduced.`
- planned_commits:
- `docs(ops): audit LLM context action coverage`
- PR:
- `#390`

### Slice 2: Define Core Context Policy Types

- status: `completed`
- branch: `fix/slice-2-context-policy-types`
- objective: `Add the minimal Ruby contract for context policy names, work families, confidence bands, and profile payloads.`
- tasks:
- [x] `T2.1 Add explicit work family and confidence-band constants.`
- [x] `T2.2 Add a normalized execution profile value object or equivalent simple Ruby structure.`
- [x] `T2.3 Add validation for required profile fields and low-confidence fallback behavior.`
- acceptance:
- `The eight initial families are represented in code.`
- `The profile always has one primary family and one context policy.`
- `Low confidence maps to full_context_fallback.`
- planned_commits:
- `feat(llm): add context policy profile types`
- PR:
- `#391`

### Slice 3: Add Declarative Policy Registry

- status: `completed`
- branch: `fix/slice-3-context-policy-registry`
- objective: `Represent explicit context policies in Ruby without adding a new orchestration component.`
- tasks:
- [x] `T3.1 Add a simple Ruby policy registry used by LLMRequestEngine.`
- [x] `T3.2 Define default policies for all initial work families.`
- [x] `T3.3 Define full_context_fallback as an explicit policy.`
- acceptance:
- `Every initial family maps to a policy.`
- `full_context_fallback is testable like any other policy.`
- `Policy definitions remain simple and inspectable.`
- planned_commits:
- `feat(llm): add context policy registry`
- PR:
- `#392`

### Slice 4: Map Existing LLM Actions To Policies

- status: `completed`
- branch: `fix/slice-4-llm-action-policy-map`
- objective: `Ensure every existing LLM action has a default work family and policy before dynamic preclassification is enabled.`
- tasks:
- [x] `T4.1 Map agent ticket execution actions to implementation or diagnosis policies as appropriate.`
- [x] `T4.2 Map quiz generation actions to planning, exploration, or documentation policies as appropriate.`
- [x] `T4.3 Map project setup prompt rendering to an appropriate policy.`
- [x] `T4.4 Map legacy Telegram/runtime interpretation traces where still active.`
- acceptance:
- `Every known action from Slice 1 has a default policy mapping.`
- `Mappings are covered by unit tests.`
- `Unmapped action behavior is explicit and fails safely.`
- planned_commits:
- `feat(llm): map actions to context policies`
- PR:
- `#393`

### Slice 5: Add Execution Contract Context Section

- status: `completed`
- branch: `fix/slice-5-execution-contract-context`
- objective: `Introduce a compact structured execution_contract section for variable runtime behavior.`
- tasks:
- [x] `T5.1 Add execution_contract context section generation.`
- [x] `T5.2 Include work family, policy, allowed outputs, allowed actions, validation requirement, retry state, and workspace boundary where applicable.`
- [x] `T5.3 Keep stable agent instructions in system_prompt.`
- acceptance:
- `execution_contract is available as a high-authority context section.`
- `No broad narrative agent context section is added.`
- `Existing system prompts continue to own stable agent instructions.`
- planned_commits:
- `feat(llm): add execution contract context`
- PR:
- `#394`

### Slice 6: Integrate Policy Resolution In LLMRequestEngine

- status: `completed`
- branch: `fix/slice-6-request-engine-policy-resolution`
- objective: `Let LLMRequestEngine consume context_policy and select/shape context layers without another orchestration component.`
- tasks:
- [x] `T6.1 Add optional context policy arguments to request-engine calls.`
- [x] `T6.2 Apply policy selection to supplied context sections.`
- [x] `T6.3 Preserve existing behavior for calls that do not opt in yet.`
- acceptance:
- `LLMRequestEngine can apply a policy to context sections.`
- `Existing request-engine tests still pass.`
- `No extra policy orchestration service is introduced.`
- planned_commits:
- `feat(llm): apply context policies in request engine`
- PR:
- `#395`

### Slice 7: Add Policy Trace Metadata

- status: `completed`
- branch: `fix/slice-7-context-policy-tracing`
- objective: `Trace selected policy, family, confidence, included layers, omitted layers, and omission reasons.`
- tasks:
- [x] `T7.1 Extend request diagnostics with policy fields.`
- [x] `T7.2 Extend trace recorder payloads to include policy decision metadata.`
- [x] `T7.3 Add tests for policy trace output.`
- acceptance:
- `Policy metadata appears alongside LLM request/response trace data.`
- `Included and omitted layers are traceable.`
- `Fallback use is traceable.`
- planned_commits:
- `feat(llm): trace context policy decisions`
- PR:
- `#396`

### Slice 8: Implement Static Policy Application Across Existing Actions

- status: `completed`
- branch: `fix/slice-8-static-policy-integration`
- objective: `Apply static default policies to all existing LLM actions before dynamic preclassification.`
- tasks:
- [x] `T8.1 Integrate static policies into agent ticket execution.`
- [x] `T8.2 Integrate static policies into quiz generation.`
- [x] `T8.3 Integrate static policies into project setup prompt rendering.`
- [x] `T8.4 Integrate static policies into active legacy runtime interpretation paths where applicable.`
- acceptance:
- `All existing actions use a mapped default policy or explicitly documented fallback.`
- `Action output contracts remain unchanged.`
- `Policy traces exist for integrated actions.`
- planned_commits:
- `feat(llm): apply static policies to LLM actions`
- PR:
- `#397`

### Slice 9: Add LLM Preclassifier Stage

- status: `completed`
- branch: `fix/slice-9-llm-preclassifier`
- objective: `Add optional semantic preclassification for context policy selection using fakeable LLM responses.`
- tasks:
- [x] `T9.1 Add preclassifier request contract and output validation.`
- [x] `T9.2 Add table-driven fake response tests for all families.`
- [x] `T9.3 Ensure low confidence selects full_context_fallback.`
- [x] `T9.4 Ensure preclassifier does not alter the downstream prompt.`
- acceptance:
- `The preclassifier returns one primary family and context_policy.`
- `No provider-backed tests are required.`
- `Invalid classifier output fails safely to fallback.`
- planned_commits:
- `feat(llm): add context preclassifier`
- PR:
- `#398`

### Slice 10: Enable Dynamic Policy Selection Across Actions

- status: `completed`
- branch: `fix/slice-10-dynamic-policy-selection`
- objective: `Use the preclassifier to select policies for all relevant LLM actions while preserving existing output contracts.`
- tasks:
- [x] `T10.1 Enable dynamic policy selection for agent ticket execution.`
- [x] `T10.2 Enable dynamic policy selection for quiz generation where useful.`
- [x] `T10.3 Enable dynamic policy selection for project setup prompt rendering where useful.`
- [x] `T10.4 Keep static action mapping as fallback.`
- acceptance:
- `All relevant actions can use dynamic context policy selection.`
- `Static mappings remain fallback behavior.`
- `Prompt text is not rewritten by the preclassifier.`
- planned_commits:
- `feat(llm): enable dynamic context policy selection`
- PR:
- `#399`

### Slice 11: Protocol Context Selection From Modeled State

- status: `completed`
- branch: `fix/slice-11-modeled-protocol-selection`
- objective: `Select protocol context from RedWright modeled Protocols, not generated repository files.`
- tasks:
- [x] `T11.1 Add protocol-document selection by modeled attributes such as key, layer, title, path, position, and provenance.`
- [x] `T11.2 Add policy-specific protocol selection tests.`
- [x] `T11.3 Preserve generated protocol file exclusion from normal repository scanning.`
- acceptance:
- `Protocol context is selected from ProjectProtocol/ProjectProtocolDocument state.`
- `Generated protocol files are not treated as canonical source-file context.`
- `Policy traces show selected protocol documents.`
- planned_commits:
- `feat(protocols): select modeled protocol context by policy`
- PR:
- `#400`

### Slice 12: General Documents Context Capability

- status: `completed`
- branch: `fix/slice-12-documents-context`
- objective: `Make docs/specs/plans/trackers available as selectable context without confusing them with Protocols.`
- tasks:
- [x] `T12.1 Define document source inventory for persisted app documents and repository ops artifacts.`
- [x] `T12.2 Add selection by project, use case, ticket linkage, and policy family where available.`
- [x] `T12.3 Trace selected and omitted documents.`
- acceptance:
- `Documents are available as a selectable context universe.`
- `Protocols remain distinct from documents.`
- `Selection and omission are traceable.`
- planned_commits:
- `feat(llm): add selectable documents context`
- PR:
- `#401`

### Slice 13: Quiz Context Capability For General Requests

- status: `completed`
- branch: `fix/slice-13-quiz-context`
- objective: `Expose curated quiz artifacts and quiz entries as selectable context outside quiz generation itself.`
- tasks:
- [x] `T13.1 Add quiz context provider for project/use-case scoped quiz material.`
- [x] `T13.2 Integrate quiz context with context policies.`
- [x] `T13.3 Add tests for quiz inclusion and omission.`
- acceptance:
- `Quiz context can be injected into non-quiz LLM requests.`
- `Use-case and project scoping are supported.`
- `Policy traces identify selected quiz context.`
- planned_commits:
- `feat(llm): add selectable quiz context`
- PR:
- `#402`

### Slice 14: Dump Context Capability

- status: `completed`
- branch: `fix/slice-14-dump-context`
- objective: `Implement dumps as an injectable context source.`
- tasks:
- [x] `T14.1 Add dump artifact discovery for curated dumps.`
- [x] `T14.2 Add project/use-case/topic relevance selection for dumps.`
- [x] `T14.3 Add trace metadata for selected and omitted dumps.`
- acceptance:
- `Curated dumps can be selected as LLM context.`
- `Dump context is policy-controlled.`
- `Missing dump capability is resolved.`
- planned_commits:
- `feat(llm): add selectable dump context`
- PR:
- `#403`

### Slice 15: Previous Human And Agent Conversation Context

- status: `completed`
- branch: `fix/slice-15-conversation-context`
- objective: `Expand previous conversation beyond agent-LLM loop records to include relevant human-RedWright conversation.`
- tasks:
- [x] `T15.1 Inventory existing human conversation storage for Telegram and TUI/runtime paths.`
- [x] `T15.2 Add conversation context selection by project, use case, ticket, and policy.`
- [x] `T15.3 Keep existing agent-LLM interaction replay compatible.`
- acceptance:
- `Previous conversation can include human and agent-LLM records.`
- `Conversation selection is scoped and traceable.`
- `Existing previous_interactions behavior is preserved.`
- planned_commits:
- `feat(llm): add human conversation context`
- PR:
- `#404`

### Slice 16: Tree-Sitter Semantic Context Capability

- status: `completed`
- branch: `fix/slice-16-treesitter-context`
- objective: `Add Tree-sitter or equivalent semantic code structure as a policy-selectable context layer.`
- tasks:
- [x] `T16.1 Select the first supported language set based on current projects and tests.`
- [x] `T16.2 Add semantic code structure extraction for selected files.`
- [x] `T16.3 Integrate semantic context with policies that need code structure.`
- acceptance:
- `Tree-sitter context is operational for the selected first language set.`
- `Policies can include or omit semantic context.`
- `Semantic context is traceable.`
- planned_commits:
- `feat(llm): add semantic code context`
- PR:
- `#405`

### Slice 17: LLM-Based Derived Context Capability

- status: `completed`
- branch: `fix/slice-17-derived-llm-context`
- objective: `Define and expose LLM-derived summaries, rankings, and prior-attempt summaries as lower-authority selectable context.`
- tasks:
- [x] `T17.1 Define LLM-derived context sources and storage boundaries.`
- [x] `T17.2 Add prior-attempt summary generation or retrieval where already available.`
- [x] `T17.3 Add authority and freshness metadata for LLM-derived context.`
- acceptance:
- `LLM-derived context is distinct from primary artifacts.`
- `Policies can include it conditionally.`
- `Authority and freshness metadata are present.`
- planned_commits:
- `feat(llm): add derived context layer`
- PR:
- `#406`

### Slice 18: Policy Matrix Completion And Tuning Baseline

- status: `completed`
- branch: `fix/slice-18-policy-matrix`
- objective: `Complete the work-family by context-layer matrix after all context capabilities exist.`
- tasks:
- [x] `T18.1 Define the policy matrix across all eight families and all injectable context types.`
- [x] `T18.2 Add representative tests for each family.`
- [x] `T18.3 Add fallback and omission-reason tests.`
- acceptance:
- `Each family has explicit context behavior.`
- `Each context type is included, omitted, or conditionally selected by at least one tested policy.`
- `The policy matrix is ready for tuning from traces.`
- planned_commits:
- `feat(llm): complete context policy matrix`
- PR:
- `#407`

### Slice 19: End-To-End Context Shaping Validation

- status: `completed`
- branch: `fix/slice-19-context-shaping-e2e`
- objective: `Validate the full request pipeline from preclassification to final trace across representative actions.`
- tasks:
- [x] `T19.1 Add end-to-end tests for agent ticket execution context shaping.`
- [x] `T19.2 Add end-to-end tests for quiz/project setup context shaping.`
- [x] `T19.3 Add trace assertions for selected policies, layers, and fallback behavior.`
- acceptance:
- `Representative LLM actions pass through the complete policy pipeline.`
- `Final traces contain policy and context evidence.`
- `No live provider calls are required.`
- planned_commits:
- `test(llm): validate context shaping end to end`
- PR:
- `#408`

### Slice 20: Documentation And Operator Review

- status: `completed`
- branch: `fix/slice-20-context-shaping-docs`
- objective: `Document the completed context-shaping model and provide operator-facing review guidance.`
- tasks:
- [x] `T20.1 Update durable reference documentation for context policy, execution profiles, and trace fields.`
- [x] `T20.2 Update relevant ops artifacts with completed decisions and validation evidence.`
- [x] `T20.3 Produce a cycle report summarizing implementation, remaining risks, and tuning guidance.`
- acceptance:
- `Docs explain the final model without depending on chat history.`
- `Trace/policy debugging guidance exists.`
- `Cycle report identifies tuning follow-ups.`
- planned_commits:
- `docs(llm): document context shaping model`
- PR:
- `#409`

## Global Exit Criteria

- Every existing LLM action maps to a work family and context policy.
- `LLMRequestEngine` can use context policies without adding another orchestration component.
- Low-confidence preclassification selects `full_context_fallback`.
- All injectable context types are operational: execution contract, project, prompt, concrete files, file tree, Tree-sitter, LLM-based context, docs, quizzes, dumps, previous conversation, and protocols.
- Protocol context is selected from modeled RedWright Protocols, not generated repository files.
- Policy decisions are represented in traces alongside request/response data.
- Unit tests cover policy inclusion and omission.
- Integration tests verify final context sections and trace metadata.
- Preclassifier tests use table-driven fake responses and no live provider calls.
- Documentation explains the final model and debugging workflow.

## Explicit Follow-Up Boundaries

The following may be tuned after the cycle, but the cycle must leave a complete operational baseline:

- family names and count
- policy matrix refinements
- protocol document selection refinements
- project-wise versus use-case-wise conversation defaults
- Tree-sitter language expansion
- LLM-derived context summarization quality
- trace report ergonomics
