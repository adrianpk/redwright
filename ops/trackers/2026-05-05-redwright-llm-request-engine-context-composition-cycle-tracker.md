# Cycle Tracker: RedWright LLM Request Engine Context Composition

## Metadata

- cycle_id: `cycle-2026-05-05-redwright-llm-request-engine-context-composition`
- status: `in_progress`
- state: `awaiting_review`
- updated: `2026-05-05`
- active_slice: `Slice 3`
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

- status: `pr_merged`
- branch: `fix/slice-1-llm-request-callsite-audit`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/311`
- merge_target: `dev`
- last_sync_commit: `ee24fbf`

Tasks:

- [x] `T1.1 locate current provider invocation and LLM request construction call sites`
- [x] `T1.2 classify each call site by request mode, work kind, available explicit inputs, expected output shape, and failure behavior`
- [x] `T1.3 select the first caller using low migration risk, real value, explicit inputs, and testability as criteria`
- [x] `T1.4 document the selected first caller and rejected alternatives in the tracker`
- [x] `T1.5 define the first semantic engine method name and keyword argument set`
- [x] `T1.6 identify the existing provider adapter behavior the engine must reuse`

Commits:

- [x] `docs(ops): select llm request engine first caller`

Validation:

- [x] `docs-only consistency pass` (pass)

### Slice 2: Engine Namespace, Response Shape, and Provider Invocation

- status: `pr_merged`
- branch: `fix/slice-2-llm-request-engine-foundation`
- PR: `https://codeberg.org/adrianpk/redwright/pulls/312`
- merge_target: `dev`
- last_sync_commit: `813c8e1`

Tasks:

- [x] `T2.1 add the Redwright::LLM namespace in the repository's existing Ruby loading structure`
- [x] `T2.2 add the minimal LLMRequestEngine semantic method selected in Slice 1`
- [x] `T2.3 add the normalized response object or struct needed by the first caller`
- [x] `T2.4 wire provider invocation through existing provider adapter behavior without introducing a parallel provider framework`
- [x] `T2.5 normalize successful provider output into rendered text and semantic payload fields required by the caller`
- [x] `T2.6 normalize provider errors, timeouts, empty responses, and parse failures for the caller`
- [x] `T2.7 add focused tests for successful response and normalized failure paths`

Commits:

- [x] `5050acf feat(web): add llm request engine foundation`
- [x] `106c165 test(web): cover llm request engine responses`

Validation:

- [x] `ruby -Itest -Ilib test/redwright/llm_request_engine_test.rb` (pass)
- [x] `ruby -Itest -Ilib test/redwright/project_setup_prompt_renderer_test.rb` (pass)

### Slice 3: First Caller Migration

- status: `completed`
- branch: `fix/slice-3-llm-request-first-caller`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending_pr`

Tasks:

- [x] `T3.1 gather the selected caller's existing business inputs before invoking the engine`
- [x] `T3.2 pass explicit keyword inputs into the engine instead of allowing the engine to fetch business state`
- [x] `T3.3 preserve the caller's expected semantic output behavior`
- [x] `T3.4 replace crude provider errors with normalized user-facing failure handling`
- [x] `T3.5 keep hidden rationale and raw diagnostics out of rendered user-facing output`
- [x] `T3.6 add or update caller-level tests for success, invalid response, and provider failure cases`

Commits:

- [x] `bbc1fea feat(web): migrate first llm caller to request engine`
- [x] `329e89f test(web): cover migrated llm caller`

Validation:

- [x] `ruby -Itest -Ilib test/redwright/project_setup_prompt_renderer_test.rb` (pass)
- [x] `ruby -Itest -Ilib test/redwright/llm_request_engine_test.rb` (pass)

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

- selected_caller: `Redwright::ProjectSetupPromptRenderer#render_prompt_via_llm`
- rejected_alternatives: `Redwright::LlmIntentInterpreter#interpret`, `Redwright::TelegramRuntimeHandler#interpret_with_trace`, `QuizLoops::QuestionProvider#generate`, `RuntimeContainers::LlmSuggestionProvider#generate`, `Redwright::AlignmentQuestionEngine#next_turn`
- selected_reason: `project setup prompt rendering is a productive existing LLM path with explicit available inputs, established trace metadata, focused tests, and a bounded JSON response contract; it matches the questionnaire's suggested initial caller while avoiding the broader runtime-planner blast radius`
- first_semantic_method: `generate_structured_message`
- explicit_inputs_required: `model, model_role, provider, action, system_prompt, user_text, output_contract, context_sections, trace_metadata`
- provider_adapter_path: `existing llm client complete_json(model:, system_prompt:, user_text:) behavior, currently supplied to ProjectSetupPromptRenderer from Redwright::CLI#telegram_project_setup_adapter_from_env`
- user_facing_failure_policy: `return the existing deterministic project setup fallback prompt when provider invocation, JSON parsing, or message extraction fails; raw provider errors remain diagnostics-only`

## Call-Site Audit

### Selected Caller

`Redwright::ProjectSetupPromptRenderer#render_prompt_via_llm`

- request_mode: `project_setup`
- work_kind: `prompt_rendering`
- model_role: `non_coding`
- current provider call: `@llm_client.complete_json(model:, system_prompt:, user_text:)`
- current trace calls: `Trace.llm_request` and `Trace.llm_response` inside the renderer
- expected output: strict JSON object with one `message` key
- available explicit inputs: setup summary, next prompt intent, setup context, latest user text, trace id, project id, session id, model, provider inferred from model
- failure behavior: deterministic fallback prompt
- migration fit: high

This is the first migration target because it is real, bounded, tested, and already carries the request/response trace shape the new engine and recorder need to preserve.

### Rejected Alternatives

`Redwright::LlmIntentInterpreter#interpret`

- request_mode: `telegram_runtime_planning`
- work_kind: `intent_interpretation`
- rejection reason: broader runtime planner path with validation retries, skill dispatching, and dynamic context providers; useful later but larger first migration blast radius.

`Redwright::TelegramRuntimeHandler#interpret_with_trace`

- request_mode: `telegram_runtime`
- work_kind: `planning_trace_coordination`
- rejection reason: it already coordinates trace around the interpreter and is coupled to Telegram runtime flow; migrating it first would blur engine and business orchestration boundaries.

`QuizLoops::QuestionProvider#generate`

- request_mode: `quiz_loop`
- work_kind: `question_generation`
- rejection reason: good future caller, but current provider boundary is a generic injected client with `generate_quiz_question` or `call`; it does not yet exercise the existing provider adapter and trace path as directly as project setup rendering.

`RuntimeContainers::LlmSuggestionProvider#generate`

- request_mode: `runtime_container_generation`
- work_kind: `structured_generation`
- rejection reason: fallback-heavy generator path and persistence side effects through `GenerationService`; better after the engine's normalized response shape exists.

`Redwright::AlignmentQuestionEngine#next_turn`

- request_mode: `alignment_loop`
- work_kind: `question_generation`
- rejection reason: older lib-side loop without current trace coordination; not the best first point for validating engine plus recorder boundaries.

## Cross-Cutting Constraints

- [x] `LLMRequestEngine receives explicit inputs and does not fetch business state`
- [x] `LLMRequestEngine invokes existing provider behavior`
- [x] `LLMRequestEngine returns normalized RedWright responses`
- [ ] `LLMTraceRecorder remains outside the engine`
- [ ] `business service or controller fallback coordinates recorder invocation`
- [x] `the first implementation migrates only one caller`
- [x] `no generic orchestration service is introduced`
- [x] `no broad task taxonomy is introduced upfront`
- [x] `raw provider diagnostics are not user-facing by default`
- [ ] `obvious sensitive content is filtered or rejected in the selected path`

## Event Log

- `2026-05-05` state=`planning_complete` note=`created implementation cycle plan and tracker from the expanded LLM request engine context composition spec`
- `2026-05-05` state=`executing_slice` note=`started Slice 1 call-site audit on branch fix/slice-1-llm-request-callsite-audit`
- `2026-05-05` state=`next_slice` note=`completed Slice 1 docs-only audit; selected ProjectSetupPromptRenderer as first LLMRequestEngine migration caller`
- `2026-05-05` state=`awaiting_review` note=`completed Slice 2 foundation; added Redwright::LLM::RequestEngine, normalized response handling, provider invocation, and focused tests`
- `2026-05-05` state=`awaiting_review` note=`completed Slice 3 first caller migration; ProjectSetupPromptRenderer now invokes LLMRequestEngine and keeps deterministic fallback behavior`
