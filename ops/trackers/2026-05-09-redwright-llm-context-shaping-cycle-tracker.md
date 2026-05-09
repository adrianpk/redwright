# Cycle Tracker: RedWright LLM Context Shaping

## Metadata

- cycle_id: `2026-05-09-redwright-llm-context-shaping`
- status: `in_progress`
- state: `slice_ready_for_review`
- updated: `2026-05-09`
- active_slice: `none`
- active_task: `none`
- plan: `ops/plans/2026-05-09-redwright-llm-context-shaping-cycle-plan.md`
- spec: `ops/specs/specs/2026-05-09-redwright-agent-ticket-llm-context-shaping-spec.md`

## Slice Progress

### Slice 1: Audit Current LLM Actions And Context Sources

- status: `completed`
- branch: `fix/slice-1-llm-context-audit`
- PR: `#390`
- merge_target: `dev`
- last_sync_commit: `99b2b16`

Tasks:

- [x] `T1.1 Inventory all RedWright LLM actions and request-engine call sites.`
- [x] `T1.2 Inventory current context layers per action, including names, authorities, bytes, and trace behavior.`
- [x] `T1.3 Document capability status for agent, project, prompt, concrete files, file tree, Tree-sitter, LLM-based context, docs, quizzes, dumps, previous conversation, and protocols.`

Commits:

- [x] `1644ef1 docs(ops): audit LLM context action coverage`
- [x] `6f0a4c6 docs(ops): audit LLM context layer coverage`
- [x] `99b2b16 docs(ops): audit LLM context capability status`

Validation:

- [x] `Audit artifact exists under ops/artifacts.`
- [x] `No runtime behavior changes are introduced.`

### Slice 2: Define Core Context Policy Types

- status: `completed`
- branch: `fix/slice-2-context-policy-types`
- PR: `#391`
- merge_target: `dev`
- last_sync_commit: `f8d1dbc`

Tasks:

- [x] `T2.1 Add explicit work family and confidence-band constants.`
- [x] `T2.2 Add a normalized execution profile value object or equivalent simple Ruby structure.`
- [x] `T2.3 Add validation for required profile fields and low-confidence fallback behavior.`

Commits:

- [x] `e72dd53 feat(llm): add context policy constants`
- [x] `7af6c86 feat(llm): add execution profile type`
- [x] `311d4cf feat(llm): validate execution profile fallback`

Validation:

- [x] `Unit tests cover family and confidence constants.`
- [x] `Low confidence maps to full_context_fallback.`

### Slice 3: Add Declarative Policy Registry

- status: `completed`
- branch: `fix/slice-3-context-policy-registry`
- PR: `#392`
- merge_target: `dev`
- last_sync_commit: `fef6519`

Tasks:

- [x] `T3.1 Add a simple Ruby policy registry used by LLMRequestEngine.`
- [x] `T3.2 Define default policies for all initial work families.`
- [x] `T3.3 Define full_context_fallback as an explicit policy.`

Commits:

- [x] `e1a9dba feat(llm): add context policy registry`
- [x] `b2c40d7 feat(llm): define default context policies`
- [x] `c693c10 feat(llm): define full context fallback policy`

Validation:

- [x] `Every initial family maps to a policy.`
- [x] `full_context_fallback is tested like any other policy.`

### Slice 4: Map Existing LLM Actions To Policies

- status: `completed`
- branch: `fix/slice-4-llm-action-policy-map`
- PR: `#393`
- merge_target: `dev`
- last_sync_commit: `04b1096`

Tasks:

- [x] `T4.1 Map agent ticket execution actions to implementation or diagnosis policies as appropriate.`
- [x] `T4.2 Map quiz generation actions to planning, exploration, or documentation policies as appropriate.`
- [x] `T4.3 Map project setup prompt rendering to an appropriate policy.`
- [x] `T4.4 Map legacy Telegram/runtime interpretation traces where still active.`

Commits:

- [x] `3de3ff2 feat(llm): map ticket execution action policy`
- [x] `9bb17ea feat(llm): map quiz action policies`
- [x] `0c0f6b feat(llm): map project setup action policy`
- [x] `6181ff3 feat(llm): map legacy action policies`

Validation:

- [x] `Every known action from Slice 1 has a default policy mapping.`
- [x] `Unmapped action behavior is explicit and fails safely.`

### Slice 5: Add Execution Contract Context Section

- status: `completed`
- branch: `fix/slice-5-execution-contract-context`
- PR: `#394`
- merge_target: `dev`
- last_sync_commit: `1d40bd1`

Tasks:

- [x] `T5.1 Add execution_contract context section generation.`
- [x] `T5.2 Include work family, policy, allowed outputs, allowed actions, validation requirement, retry state, and workspace boundary where applicable.`
- [x] `T5.3 Keep stable agent instructions in system_prompt.`

Commits:

- [x] `8256fa2 feat(llm): add execution contract section`
- [x] `069e8b5 feat(llm): add execution contract fields`
- [x] `f28582c feat(llm): keep stable instructions out of execution context`

Validation:

- [x] `execution_contract is available as a high-authority context section.`
- [x] `No broad narrative agent context section is added.`

### Slice 6: Integrate Policy Resolution In LLMRequestEngine

- status: `ready_for_review`
- branch: `fix/slice-6-request-engine-policy-resolution`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `5d67b0f`

Tasks:

- [x] `T6.1 Add optional context policy arguments to request-engine calls.`
- [x] `T6.2 Apply policy selection to supplied context sections.`
- [x] `T6.3 Preserve existing behavior for calls that do not opt in yet.`

Commits:

- [x] `9f16966 feat(llm): add request engine policy arguments`
- [x] `545c195 feat(llm): filter request context by policy`
- [x] `b132bb4 feat(llm): preserve unscoped request context`

Validation:

- [x] `LLMRequestEngine can apply a policy to context sections.`
- [x] `Existing request-engine tests still pass.`

### Slice 7: Add Policy Trace Metadata

- status: `pending`
- branch: `fix/slice-7-context-policy-tracing`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 Extend request diagnostics with policy fields.`
- [ ] `T7.2 Extend trace recorder payloads to include policy decision metadata.`
- [ ] `T7.3 Add tests for policy trace output.`

Commits:

- [ ] `tbd feat(llm): trace context policy decisions`

Validation:

- [ ] `Policy metadata appears alongside LLM request/response trace data.`
- [ ] `Included and omitted layers are traceable.`

### Slice 8: Implement Static Policy Application Across Existing Actions

- status: `pending`
- branch: `fix/slice-8-static-policy-integration`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T8.1 Integrate static policies into agent ticket execution.`
- [ ] `T8.2 Integrate static policies into quiz generation.`
- [ ] `T8.3 Integrate static policies into project setup prompt rendering.`
- [ ] `T8.4 Integrate static policies into active legacy runtime interpretation paths where applicable.`

Commits:

- [ ] `tbd feat(llm): apply static policies to LLM actions`

Validation:

- [ ] `All existing actions use a mapped default policy or documented fallback.`
- [ ] `Action output contracts remain unchanged.`

### Slice 9: Add LLM Preclassifier Stage

- status: `pending`
- branch: `fix/slice-9-llm-preclassifier`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T9.1 Add preclassifier request contract and output validation.`
- [ ] `T9.2 Add table-driven fake response tests for all families.`
- [ ] `T9.3 Ensure low confidence selects full_context_fallback.`
- [ ] `T9.4 Ensure preclassifier does not alter the downstream prompt.`

Commits:

- [ ] `tbd feat(llm): add context preclassifier`

Validation:

- [ ] `The preclassifier returns one primary family and context_policy.`
- [ ] `Invalid classifier output fails safely to fallback.`

### Slice 10: Enable Dynamic Policy Selection Across Actions

- status: `pending`
- branch: `fix/slice-10-dynamic-policy-selection`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T10.1 Enable dynamic policy selection for agent ticket execution.`
- [ ] `T10.2 Enable dynamic policy selection for quiz generation where useful.`
- [ ] `T10.3 Enable dynamic policy selection for project setup prompt rendering where useful.`
- [ ] `T10.4 Keep static action mapping as fallback.`

Commits:

- [ ] `tbd feat(llm): enable dynamic context policy selection`

Validation:

- [ ] `All relevant actions can use dynamic context policy selection.`
- [ ] `Prompt text is not rewritten by the preclassifier.`

### Slice 11: Protocol Context Selection From Modeled State

- status: `pending`
- branch: `fix/slice-11-modeled-protocol-selection`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T11.1 Add protocol-document selection by modeled attributes such as key, layer, title, path, position, and provenance.`
- [ ] `T11.2 Add policy-specific protocol selection tests.`
- [ ] `T11.3 Preserve generated protocol file exclusion from normal repository scanning.`

Commits:

- [ ] `tbd feat(protocols): select modeled protocol context by policy`

Validation:

- [ ] `Protocol context is selected from ProjectProtocol/ProjectProtocolDocument state.`
- [ ] `Policy traces show selected protocol documents.`

### Slice 12: General Documents Context Capability

- status: `pending`
- branch: `fix/slice-12-documents-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T12.1 Define document source inventory for persisted app documents and repository ops artifacts.`
- [ ] `T12.2 Add selection by project, use case, ticket linkage, and policy family where available.`
- [ ] `T12.3 Trace selected and omitted documents.`

Commits:

- [ ] `tbd feat(llm): add selectable documents context`

Validation:

- [ ] `Documents are available as a selectable context universe.`
- [ ] `Protocols remain distinct from documents.`

### Slice 13: Quiz Context Capability For General Requests

- status: `pending`
- branch: `fix/slice-13-quiz-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T13.1 Add quiz context provider for project/use-case scoped quiz material.`
- [ ] `T13.2 Integrate quiz context with context policies.`
- [ ] `T13.3 Add tests for quiz inclusion and omission.`

Commits:

- [ ] `tbd feat(llm): add selectable quiz context`

Validation:

- [ ] `Quiz context can be injected into non-quiz LLM requests.`
- [ ] `Policy traces identify selected quiz context.`

### Slice 14: Dump Context Capability

- status: `pending`
- branch: `fix/slice-14-dump-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T14.1 Add dump artifact discovery for curated dumps.`
- [ ] `T14.2 Add project/use-case/topic relevance selection for dumps.`
- [ ] `T14.3 Add trace metadata for selected and omitted dumps.`

Commits:

- [ ] `tbd feat(llm): add selectable dump context`

Validation:

- [ ] `Curated dumps can be selected as LLM context.`
- [ ] `Dump context is policy-controlled.`

### Slice 15: Previous Human And Agent Conversation Context

- status: `pending`
- branch: `fix/slice-15-conversation-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T15.1 Inventory existing human conversation storage for Telegram and TUI/runtime paths.`
- [ ] `T15.2 Add conversation context selection by project, use case, ticket, and policy.`
- [ ] `T15.3 Keep existing agent-LLM interaction replay compatible.`

Commits:

- [ ] `tbd feat(llm): add human conversation context`

Validation:

- [ ] `Previous conversation can include human and agent-LLM records.`
- [ ] `Existing previous_interactions behavior is preserved.`

### Slice 16: Tree-Sitter Semantic Context Capability

- status: `pending`
- branch: `fix/slice-16-treesitter-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T16.1 Select the first supported language set based on current projects and tests.`
- [ ] `T16.2 Add semantic code structure extraction for selected files.`
- [ ] `T16.3 Integrate semantic context with policies that need code structure.`

Commits:

- [ ] `tbd feat(llm): add semantic code context`

Validation:

- [ ] `Tree-Sitter context is operational for the selected first language set.`
- [ ] `Semantic context is traceable.`

### Slice 17: LLM-Based Derived Context Capability

- status: `pending`
- branch: `fix/slice-17-derived-llm-context`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T17.1 Define LLM-derived context sources and storage boundaries.`
- [ ] `T17.2 Add prior-attempt summary generation or retrieval where already available.`
- [ ] `T17.3 Add authority and freshness metadata for LLM-derived context.`

Commits:

- [ ] `tbd feat(llm): add derived context layer`

Validation:

- [ ] `LLM-derived context is distinct from primary artifacts.`
- [ ] `Authority and freshness metadata are present.`

### Slice 18: Policy Matrix Completion And Tuning Baseline

- status: `pending`
- branch: `fix/slice-18-policy-matrix`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T18.1 Define the policy matrix across all eight families and all injectable context types.`
- [ ] `T18.2 Add representative tests for each family.`
- [ ] `T18.3 Add fallback and omission-reason tests.`

Commits:

- [ ] `tbd feat(llm): complete context policy matrix`

Validation:

- [ ] `Each family has explicit context behavior.`
- [ ] `Each context type is included, omitted, or conditionally selected by at least one tested policy.`

### Slice 19: End-To-End Context Shaping Validation

- status: `pending`
- branch: `fix/slice-19-context-shaping-e2e`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T19.1 Add end-to-end tests for agent ticket execution context shaping.`
- [ ] `T19.2 Add end-to-end tests for quiz/project setup context shaping.`
- [ ] `T19.3 Add trace assertions for selected policies, layers, and fallback behavior.`

Commits:

- [ ] `tbd test(llm): validate context shaping end to end`

Validation:

- [ ] `Representative LLM actions pass through the complete policy pipeline.`
- [ ] `No live provider calls are required.`

### Slice 20: Documentation And Operator Review

- status: `pending`
- branch: `fix/slice-20-context-shaping-docs`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T20.1 Update durable reference documentation for context policy, execution profiles, and trace fields.`
- [ ] `T20.2 Update relevant ops artifacts with completed decisions and validation evidence.`
- [ ] `T20.3 Produce a cycle report summarizing implementation, remaining risks, and tuning guidance.`

Commits:

- [ ] `tbd docs(llm): document context shaping model`

Validation:

- [ ] `Docs explain the final model without depending on chat history.`
- [ ] `Cycle report identifies tuning follow-ups.`

## Event Log

- `2026-05-09` state=`planning` note=`Tracker created from approved 20-slice LLM context shaping cycle plan.`
- `2026-05-09` state=`executing_slice` note=`Slice 1 started; T1.1 action and call-site inventory captured in ops/artifacts/2026-05-09-llm-context-action-audit.md.`
- `2026-05-09` state=`executing_slice` note=`T1.2 context layers per action captured in ops/artifacts/2026-05-09-llm-context-action-audit.md.`
- `2026-05-09` state=`awaiting_review` note=`Slice 1 completed; context capability status documented and branch ready for review.`
- `2026-05-09` state=`next_slice` note=`Slice 1 merged through PR #390 and dev synced to 99b2b16.`
