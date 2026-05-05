# Cycle Plan: RedWright LLM Request Engine Context Composition

## Metadata

- cycle_id: `cycle-2026-05-05-redwright-llm-request-engine-context-composition`
- status: `in_progress`
- owner: `adrianpk`
- created: `2026-05-05`
- updated: `2026-05-05`
- goal: `introduce a practical Redwright::LLM request engine and external trace recorder that can replace existing LLM calls one caller at a time while preserving explicit inputs, normalized responses, and clean tracing boundaries`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-05-redwright-llm-request-engine-context-composition-spec.md`
- source_conversation:
  - `ops/specs/conv/2026-05-05-redwright-llm-request-engine-context-composition-conv.md`
  - `ops/specs/conv/2026-05-05-redwright-llm-request-engine-context-composition-conv-raw.md`
- source_drafts:
  - `ops/specs/drafts/2026-05-05-redwright-prompt-engine-context-composition-draft.md`
  - `ops/specs/drafts/2026-05-03-redwright-llm-rolling-trace-file-draft.md`
- related_spec:
  - `ops/specs/specs/2026-05-03-redwright-llm-rolling-trace-file-spec.md`

## Delivery Strategy

This cycle should deliver the shared LLM request boundary incrementally.

The plan intentionally starts with call-site inspection and a first real migration rather than a complete abstract LLM framework. Each slice should preserve the spec's core constraints:

- the engine receives explicit inputs from outer layers
- the engine performs provider invocation through existing provider behavior
- the engine returns a normalized RedWright response
- trace recording remains outside the engine
- coordination belongs to the business service or controller fallback
- helpers are added only when implementation pressure justifies them

## Slice List

### Slice 1: LLM Call-Site Audit and First Caller Selection

- status: `completed`
- branch: `fix/slice-1-llm-request-callsite-audit`
- pr_title: `feat(slice-1): select llm request engine first caller`
- objective: `inspect existing productive LLM call sites, document the first migration target, and define the minimal semantic engine method required by that caller`
- tasks:
- [ ] `T1.1 locate current provider invocation and LLM request construction call sites`
- [ ] `T1.2 classify each call site by request mode, work kind, available explicit inputs, expected output shape, and failure behavior`
- [ ] `T1.3 select the first caller using low migration risk, real value, explicit inputs, and testability as criteria`
- [ ] `T1.4 document the selected first caller and rejected alternatives in the tracker`
- [ ] `T1.5 define the first semantic engine method name and keyword argument set`
- [ ] `T1.6 identify the existing provider adapter behavior the engine must reuse`
- acceptance:
- `the first migrated caller is explicitly named`
- `the selected caller has a documented rationale and rejected alternatives`
- `the first semantic method and argument set are concrete enough for Slice 2`
- `no runtime behavior changes are introduced beyond inspection or supporting documentation`
- planned_commits:
- `docs(ops): select llm request engine first caller`

### Slice 2: Engine Namespace, Response Shape, and Provider Invocation

- status: `planned`
- branch: `fix/slice-2-llm-request-engine-foundation`
- pr_title: `feat(slice-2): add llm request engine foundation`
- objective: `introduce the Redwright::LLM namespace, minimal LLMRequestEngine boundary, normalized response object, and provider invocation path for the selected caller`
- tasks:
- [ ] `T2.1 add the Redwright::LLM namespace in the repository's existing Ruby loading structure`
- [ ] `T2.2 add the minimal LLMRequestEngine semantic method selected in Slice 1`
- [ ] `T2.3 add the normalized response object or struct needed by the first caller`
- [ ] `T2.4 wire provider invocation through existing provider adapter behavior without introducing a parallel provider framework`
- [ ] `T2.5 normalize successful provider output into rendered text and semantic payload fields required by the caller`
- [ ] `T2.6 normalize provider errors, timeouts, empty responses, and parse failures for the caller`
- [ ] `T2.7 add focused tests for successful response and normalized failure paths`
- acceptance:
- `LLMRequestEngine can execute the selected caller's LLM operation`
- `the caller does not need provider-specific exception handling`
- `raw provider diagnostics are not part of the primary response contract`
- `the implementation does not fetch business state from inside the engine`
- planned_commits:
- `feat(web): add llm request engine foundation`
- `test(web): cover llm request engine responses`

### Slice 3: First Caller Migration

- status: `planned`
- branch: `fix/slice-3-llm-request-first-caller`
- pr_title: `feat(slice-3): migrate first llm caller to request engine`
- objective: `replace the selected direct LLM call with LLMRequestEngine while preserving or improving caller behavior and user-facing failure output`
- tasks:
- [ ] `T3.1 gather the selected caller's existing business inputs before invoking the engine`
- [ ] `T3.2 pass explicit keyword inputs into the engine instead of allowing the engine to fetch business state`
- [ ] `T3.3 preserve the caller's expected semantic output behavior`
- [ ] `T3.4 replace crude provider errors with normalized user-facing failure handling`
- [ ] `T3.5 keep hidden rationale and raw diagnostics out of rendered user-facing output`
- [ ] `T3.6 add or update caller-level tests for success, invalid response, and provider failure cases`
- acceptance:
- `one existing LLM call site is migrated to LLMRequestEngine`
- `the migrated caller remains behaviorally compatible or has documented intentional cleanup`
- `user-facing channels do not expose raw provider failure details by default`
- `tests cover the migrated caller's success and failure behavior`
- planned_commits:
- `feat(web): migrate first llm caller to request engine`
- `test(web): cover migrated llm caller`

### Slice 4: Trace Recorder Boundary

- status: `planned`
- branch: `fix/slice-4-llm-trace-recorder-boundary`
- pr_title: `feat(slice-4): add llm trace recorder boundary`
- objective: `introduce LLMTraceRecorder outside the engine and coordinate trace recording from the selected caller's business service or controller fallback`
- tasks:
- [ ] `T4.1 add the minimal LLMTraceRecorder boundary under Redwright::LLM or the repository's trace-oriented location`
- [ ] `T4.2 define the recorder input shape for logical request metadata, selected context section names, provider/model metadata, normalized status, warnings, and raw diagnostic references`
- [ ] `T4.3 connect recorder output to the existing rolling LLM trace behavior where compatible`
- [ ] `T4.4 invoke the recorder from the business service that owns the migrated caller, or controller fallback if no service exists`
- [ ] `T4.5 verify that trace recording remains outside LLMRequestEngine`
- [ ] `T4.6 add tests for recorder invocation and trace-writer failure isolation`
- acceptance:
- `LLMTraceRecorder exists as a separate boundary from LLMRequestEngine`
- `the migrated caller coordinates recording after the engine returns`
- `trace writer failures do not break LLM execution`
- `trace metadata includes operation name, provider/model role, normalized status, and selected section names when available`
- planned_commits:
- `feat(web): add llm trace recorder boundary`
- `test(web): cover llm trace recorder coordination`

### Slice 5: Context Sections, Safety Filtering, and Diagnostics

- status: `planned`
- branch: `fix/slice-5-llm-context-section-safety`
- pr_title: `feat(slice-5): add llm context section safety`
- objective: `make the first engine path context-section aware, authority-labeled, and guarded against obvious sensitive content without introducing a full context allocation framework`
- tasks:
- [ ] `T5.1 introduce the smallest context section representation needed by the migrated caller`
- [ ] `T5.2 attach section names and authority labels to selected context`
- [ ] `T5.3 include an explicit output contract in the rendered request`
- [ ] `T5.4 add practical redaction or rejection for obvious secrets, credentials, tokens, passwords, and PII-sensitive prompts in the selected path`
- [ ] `T5.5 expose section names and approximate payload/context size metadata to trace diagnostics when available`
- [ ] `T5.6 add tests for section ordering, authority labeling, output contract rendering, and sensitive-content handling`
- acceptance:
- `the migrated request includes named context sections`
- `the output contract is explicit`
- `obvious sensitive material is filtered or rejected in the selected path`
- `trace diagnostics can explain which section names were included`
- planned_commits:
- `feat(web): add llm context section safety`
- `test(web): cover llm context safety`

### Slice 6: Cycle Hardening and Next Caller Readiness

- status: `planned`
- branch: `fix/slice-6-llm-request-engine-hardening`
- pr_title: `feat(slice-6): harden llm request engine cycle`
- objective: `complete validation, remove accidental over-abstraction, update operational records, and prepare explicit criteria for the next caller migration`
- tasks:
- [ ] `T6.1 review new classes and helpers against the no-abstraction-by-habit constraint`
- [ ] `T6.2 run targeted tests for the engine, recorder, and migrated caller`
- [ ] `T6.3 run the broader relevant test suite from canonical command locations`
- [ ] `T6.4 update tracker with migrated caller, commits, validation, and residual risks`
- [ ] `T6.5 document next-caller readiness criteria without starting a second migration`
- [ ] `T6.6 capture open questions for session identity, previous interactions, preflight, and conflict handling`
- acceptance:
- `all relevant tests pass or blockers are documented precisely`
- `the tracker contains final validation evidence`
- `the implementation remains scoped to one migrated caller`
- `next caller criteria are documented without expanding scope`
- planned_commits:
- `docs(ops): close llm request engine cycle`

## Global Exit Criteria

- one existing LLM caller is migrated through `LLMRequestEngine`
- the engine lives conceptually under `Redwright::LLM`
- callers pass explicit inputs into the engine
- the engine does not fetch business state internally
- provider invocation reuses existing provider behavior
- the response returned to callers is normalized and RedWright-native
- raw provider diagnostics are not user-facing by default
- `LLMTraceRecorder` remains outside the engine
- trace recording is coordinated by the business service or controller fallback
- selected context is represented through named sections for the migrated path
- an explicit output contract is present in the migrated path
- obvious sensitive data is filtered or rejected in the selected path
- tests cover success, provider failure, invalid response, and trace recorder coordination
- the cycle ends with one migrated caller and documented criteria for future expansion

## Validation Command Context

- Rails targeted tests must be run from `apps/web` with `bundle exec bin/rails test <paths>` when Rails code is touched.
- Repository-level checks must be run from repository root when runtime or shared tooling outside `apps/web` is touched.
- Validation entries must be reported as command plus `(pass)` or `(fail)`.
- Docs-only updates can use the documented docs-only gate exception.

## Non-Goals

- Do not migrate every LLM call in this cycle.
- Do not introduce a generic LLM orchestration service.
- Do not add a database-backed previous-interaction store.
- Do not expose context policy as user-editable YAML in this cycle.
- Do not implement preflight unless the selected first caller proves it is required.
- Do not implement full autonomous ticket conflict handling in this cycle.
