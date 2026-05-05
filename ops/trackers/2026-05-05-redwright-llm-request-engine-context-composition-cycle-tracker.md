# Cycle Tracker: RedWright LLM Request Engine Context Composition

## Metadata

- cycle_id: `cycle-2026-05-05-redwright-llm-request-engine-context-composition`
- status: `planned`
- state: `planning_complete`
- updated: `2026-05-05`
- active_slice: `none`
- active_task: `none`
- source_plan: `ops/plans/2026-05-05-redwright-llm-request-engine-context-composition-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
- source_conversation:
  - `ops/specs/conv/2026-05-05-redwright-llm-request-engine-context-composition-conv.md`
  - `ops/specs/conv/2026-05-05-redwright-llm-request-engine-context-composition-conv-raw.md`
- source_drafts:
  - `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`
- related_spec:
  - `ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md`

## Slice Progress

### Slice 1: LLM Call-Site Audit and First Caller Selection

- status: `planned`
- branch: `fix/slice-1-llm-request-callsite-audit`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 locate current provider invocation and LLM request construction call sites`
- [ ] `T1.2 classify each call site by request mode, work kind, available explicit inputs, expected output shape, and failure behavior`
- [ ] `T1.3 select the first caller using low migration risk, real value, explicit inputs, and testability as criteria`
- [ ] `T1.4 document the selected first caller and rejected alternatives in the tracker`
- [ ] `T1.5 define the first semantic engine method name and keyword argument set`
- [ ] `T1.6 identify the existing provider adapter behavior the engine must reuse`

Commits:

- [ ] `docs(ops): select llm request engine first caller`

Validation:

- [ ] `docs-only consistency pass` (pending)

### Slice 2: Engine Namespace, Response Shape, and Provider Invocation

- status: `planned`
- branch: `fix/slice-2-llm-request-engine-foundation`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 add the Redwright::LLM namespace in the repository's existing Ruby loading structure`
- [ ] `T2.2 add the minimal LLMRequestEngine semantic method selected in Slice 1`
- [ ] `T2.3 add the normalized response object or struct needed by the first caller`
- [ ] `T2.4 wire provider invocation through existing provider adapter behavior without introducing a parallel provider framework`
- [ ] `T2.5 normalize successful provider output into rendered text and semantic payload fields required by the caller`
- [ ] `T2.6 normalize provider errors, timeouts, empty responses, and parse failures for the caller`
- [ ] `T2.7 add focused tests for successful response and normalized failure paths`

Commits:

- [ ] `feat(web): add llm request engine foundation`
- [ ] `test(web): cover llm request engine responses`

Validation:

- [ ] `targeted engine tests` (pending)
- [ ] `targeted first caller tests` (pending)

### Slice 3: First Caller Migration

- status: `planned`
- branch: `fix/slice-3-llm-request-first-caller`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 gather the selected caller's existing business inputs before invoking the engine`
- [ ] `T3.2 pass explicit keyword inputs into the engine instead of allowing the engine to fetch business state`
- [ ] `T3.3 preserve the caller's expected semantic output behavior`
- [ ] `T3.4 replace crude provider errors with normalized user-facing failure handling`
- [ ] `T3.5 keep hidden rationale and raw diagnostics out of rendered user-facing output`
- [ ] `T3.6 add or update caller-level tests for success, invalid response, and provider failure cases`

Commits:

- [ ] `feat(web): migrate first llm caller to request engine`
- [ ] `test(web): cover migrated llm caller`

Validation:

- [ ] `targeted migrated caller tests` (pending)
- [ ] `targeted provider failure tests` (pending)

### Slice 4: Trace Recorder Boundary

- status: `planned`
- branch: `fix/slice-4-llm-trace-recorder-boundary`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 add the minimal LLMTraceRecorder boundary under Redwright::LLM or the repository's trace-oriented location`
- [ ] `T4.2 define the recorder input shape for logical request metadata, selected context section names, provider/model metadata, normalized status, warnings, and raw diagnostic references`
- [ ] `T4.3 connect recorder output to the existing rolling LLM trace behavior where compatible`
- [ ] `T4.4 invoke the recorder from the business service that owns the migrated caller, or controller fallback if no service exists`
- [ ] `T4.5 verify that trace recording remains outside LLMRequestEngine`
- [ ] `T4.6 add tests for recorder invocation and trace-writer failure isolation`

Commits:

- [ ] `feat(web): add llm trace recorder boundary`
- [ ] `test(web): cover llm trace recorder coordination`

Validation:

- [ ] `targeted recorder tests` (pending)
- [ ] `targeted migrated caller trace tests` (pending)

### Slice 5: Context Sections, Safety Filtering, and Diagnostics

- status: `planned`
- branch: `fix/slice-5-llm-context-section-safety`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 introduce the smallest context section representation needed by the migrated caller`
- [ ] `T5.2 attach section names and authority labels to selected context`
- [ ] `T5.3 include an explicit output contract in the rendered request`
- [ ] `T5.4 add practical redaction or rejection for obvious secrets, credentials, tokens, passwords, and PII-sensitive prompts in the selected path`
- [ ] `T5.5 expose section names and approximate payload/context size metadata to trace diagnostics when available`
- [ ] `T5.6 add tests for section ordering, authority labeling, output contract rendering, and sensitive-content handling`

Commits:

- [ ] `feat(web): add llm context section safety`
- [ ] `test(web): cover llm context safety`

Validation:

- [ ] `targeted context section tests` (pending)
- [ ] `targeted redaction tests` (pending)

### Slice 6: Cycle Hardening and Next Caller Readiness

- status: `planned`
- branch: `fix/slice-6-llm-request-engine-hardening`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 review new classes and helpers against the no-abstraction-by-habit constraint`
- [ ] `T6.2 run targeted tests for the engine, recorder, and migrated caller`
- [ ] `T6.3 run the broader relevant test suite from canonical command locations`
- [ ] `T6.4 update tracker with migrated caller, commits, validation, and residual risks`
- [ ] `T6.5 document next-caller readiness criteria without starting a second migration`
- [ ] `T6.6 capture open questions for session identity, previous interactions, preflight, and conflict handling`

Commits:

- [ ] `docs(ops): close llm request engine cycle`

Validation:

- [ ] `targeted engine, recorder, and migrated caller tests` (pending)
- [ ] `broader relevant test suite` (pending)

## First Caller Selection Record

- selected_caller: `tbd`
- rejected_alternatives: `tbd`
- selected_reason: `tbd`
- first_semantic_method: `tbd`
- explicit_inputs_required: `tbd`
- provider_adapter_path: `tbd`
- user_facing_failure_policy: `tbd`

## Cross-Cutting Constraints

- [ ] `LLMRequestEngine receives explicit inputs and does not fetch business state`
- [ ] `LLMRequestEngine invokes existing provider behavior`
- [ ] `LLMRequestEngine returns normalized RedWright responses`
- [ ] `LLMTraceRecorder remains outside the engine`
- [ ] `business service or controller fallback coordinates recorder invocation`
- [ ] `the first implementation migrates only one caller`
- [ ] `no generic orchestration service is introduced`
- [ ] `no broad task taxonomy is introduced upfront`
- [ ] `raw provider diagnostics are not user-facing by default`
- [ ] `obvious sensitive content is filtered or rejected in the selected path`

## Event Log

- `2026-05-05` state=`planning_complete` note=`created implementation cycle plan and tracker from the expanded LLM request engine context composition spec`
