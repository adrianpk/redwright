# Cycle Tracker: RedWright Project Setup Runnable Saga

## Metadata

- cycle_id: `cycle-2026-05-03-redwright-project-setup-runnable-saga`
- status: `planned`
- state: `planned`
- updated: `2026-05-03`
- active_slice: `none`
- active_task: `awaiting slice 1 start after plan approval`
- source_plan: `ops/plans/2026-05-03-redwright-project-setup-runnable-saga-cycle-plan.md`
- source_spec: `ops/specs/specs/2026-05-03-redwright-project-setup-runnable-saga-spec.md`
- source_draft: `ops/specs/drafts/2026-05-03-redwright-project-setup-runnable-saga-draft.md`

## Slice Progress

### Slice 1: Setup LLM Traces and Semantic Slot Normalization

- status: `planned`
- branch: `fix/slice-1-setup-llm-traces-and-slot-normalization`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T1.1 characterize missing setup LLM traces and raw slot persistence with focused tests`
- [ ] `T1.2 instrument ProjectSetupPromptRenderer with Trace.llm_request and Trace.llm_response`
- [ ] `T1.3 add semantic answer normalization contract with strict JSON output, deterministic fallback, and malformed-output handling`
- [ ] `T1.4 integrate normalized slot updates into project setup advancement without losing raw answer audit data`
- [ ] `T1.5 prevent prompt-confusion/meta answers from filling framework, language_runtime, libraries, or stack`
- [ ] `T1.6 synthesize stack from normalized context instead of blindly deriving it from framework`
- [ ] `T1.7 add tests for Go CLI answers, framework confusion, fallback normalization, and trace output`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 2: Explicit Setup Saga State and Query Surface

- status: `planned`
- branch: `fix/slice-2-project-setup-saga-state`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T2.1 define persisted saga stage metadata compatible with existing ProjectSetupSession states`
- [ ] `T2.2 add materialization and initial implementation result structures to setup session metadata`
- [ ] `T2.3 expose structured saga state through Rails command/query responses`
- [ ] `T2.4 update /project where to report setup stage, workspace, and runnable/planned status when available`
- [ ] `T2.5 add tests for stage transitions, repeated completion, and API/query shape`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 3: Materialization Outcome and Planned Fallback

- status: `planned`
- branch: `fix/slice-3-project-setup-materialization-outcome`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T3.1 extend workspace manifest with materialization status, initial implementation status, validation status, and linked ticket ids`
- [ ] `T3.2 create or update README/setup notes during local workspace materialization`
- [ ] `T3.3 create starter implementation ticket when the project is not yet runnable`
- [ ] `T3.4 ensure unsupported stack/archetype combinations become materialized_planned with reason`
- [ ] `T3.5 add idempotency tests for manifest, README, document, board, and starter ticket reconciliation`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 4: Go CLI Initial Implementation Scaffold

- status: `planned`
- branch: `fix/slice-4-go-cli-initial-scaffold`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T4.1 add deterministic scaffold profile selection for Go CLI projects`
- [ ] `T4.2 generate go.mod, main entrypoint, README, and basic test when Go CLI context is detected`
- [ ] `T4.3 support optional urfave/cli dependency when libraries include it`
- [ ] `T4.4 run or record go test ./... validation depending on local toolchain availability`
- [ ] `T4.5 update Rails materialization data and manifest with runnable scaffold results`
- [ ] `T4.6 add filesystem and API tests for the Go CLI setup scenario`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

### Slice 5: Telegram and Rails End-to-End Closure

- status: `planned`
- branch: `fix/slice-5-runnable-setup-e2e-closure`
- PR: `pending`
- merge_target: `dev`
- last_sync_commit: `pending`

Tasks:

- [ ] `T5.1 add Telegram E2E for project new through Go CLI runnable or validation-skipped setup`
- [ ] `T5.2 add Telegram E2E for unsupported setup planned fallback`
- [ ] `T5.3 verify completion messages distinguish runnable, planned, and failed outcomes`
- [ ] `T5.4 run full Rails tests and repository coverage from canonical locations`
- [ ] `T5.5 publish cycle closure report with residual risks and tuning decision`

Commits:

- [ ] `pending`

Validation:

- [ ] `pending`

## Coverage Guard

- baseline_coverage: `91.39`
- target_rule: `post-slice coverage >= pre-slice coverage for new code paths`
- final_coverage: `pending`
- tuning_needed: `pending`
- tuning_evidence: `manual Telegram verification showed complete setup manifests but no runnable local project files, no visible setup LLM traces, and raw prompt-confusion text persisted as framework/stack context`

## Event Log

- `2026-05-03` state=`planned` note=`created runnable setup saga draft, conversation notes, promoted spec, cycle plan, and tracker after manual Telegram verification showed setup completion still ended at metadata/materialization instead of runnable or explicitly planned project state`
