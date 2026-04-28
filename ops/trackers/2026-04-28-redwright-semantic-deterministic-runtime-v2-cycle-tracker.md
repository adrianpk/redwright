# Cycle Tracker: Redwright Semantic Deterministic Runtime V2

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-semantic-deterministic-runtime-v2`
- status: `in_progress`
- state: `planning`
- updated: `2026-04-28`
- active_slice: `slice-1`
- active_task: `none`

## Slice Progress

### Slice 1: State Contract and Terminal Reasons

- status: `pending`
- branch: `feat/slice-1-runtime-v2-state-contract`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 implement static transition matrix for v2 states`
- [ ] `T1.2 enforce transition validation in runtime entrypoints`
- [ ] `T1.3 persist terminal reason in runtime results`

Validation:

- [ ] `invalid transition rejection and terminal reason coverage pass`

### Slice 2: Semantic Packet V2 (Tree + Files + Errors)

- status: `pending`
- branch: `feat/slice-2-semantic-packet-v2`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 define strict packet schema and serializer`
- [ ] `T2.2 add tree snapshot capture with configurable limits`
- [ ] `T2.3 add file-selection heuristics and bounded payload sizing`
- [ ] `T2.4 include compile/test/runtime error context on retries`

Validation:

- [ ] `packet schema and bounded payload checks pass`

### Slice 3: Dynamic Gap Collection and Clarification Engine

- status: `pending`
- branch: `feat/slice-3-dynamic-gap-clarification`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add gap extraction contract in planner response`
- [ ] `T3.2 implement inferred-project-name confirmation flow`
- [ ] `T3.3 consume multi-answer user replies and skip solved gaps`
- [ ] `T3.4 enforce one high-value clarification question when ambiguity remains`

Validation:

- [ ] `clarification behavior is dynamic and non-mechanical`

### Slice 4: Internal Convergence Loop V2

- status: `pending`
- branch: `feat/slice-4-internal-convergence-loop-v2`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 run execute->verify->refine loop inside one user turn`
- [ ] `T4.2 enforce max_attempts and max_turn_seconds bounds`
- [ ] `T4.3 classify loop exits into terminal reasons`

Validation:

- [ ] `converged/blocked/clarify exits are deterministic and auditable`

### Slice 5: Dual Mode Orchestration (Structured + Direct)

- status: `pending`
- branch: `feat/slice-5-dual-mode-orchestration`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 add mode inference with explicit override support`
- [ ] `T5.2 preserve structured lifecycle path`
- [ ] `T5.3 preserve direct execution path`

Validation:

- [ ] `mode inference and override behavior pass invariants`

### Slice 6: Multi-Stack Semantics Without Hardcoded Workflow Branches

- status: `pending`
- branch: `feat/slice-6-multistack-semantic-runtime`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 encode stack/toolchain hints in semantic packet`
- [ ] `T6.2 validate no hardcoded language-specific workflow routing`
- [ ] `T6.3 add multi-stack fixture tests`

Validation:

- [ ] `workflow-core stack neutrality checks pass`

### Slice 7: End-to-End Tests for Clarification, Convergence, and Persistence

- status: `pending`
- branch: `feat/slice-7-runtime-v2-e2e-and-persistence`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 add e2e inferred-name confirmation scenario`
- [ ] `T7.2 add e2e multi-gap consumption scenario`
- [ ] `T7.3 add e2e convergence-after-error scenario`
- [ ] `T7.4 assert persistence packet/action/error/terminal-reason records`

Validation:

- [ ] `runtime-v2 e2e suite passes with deterministic artifacts`

## Event Log

- `2026-04-28 13:40` state=`planning` note=`created hyper-granular runtime-v2 spec with deterministic state core, semantic packet v2, dynamic gap clarification, bounded convergence loop, dual mode orchestration, and multi-stack neutrality constraints`
