# Cycle Tracker: RedWright Autonomous Turn Loop

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-autonomous-turn-loop`
- status: `in_progress`
- state: `planning`
- updated: `2026-04-28`
- active_slice: `none`
- active_task: `none`

## Slice Progress

### Slice 1: First-Run Context Bootstrap

- status: `pending`
- branch: `feat/slice-1-first-run-context-bootstrap`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T1.1 detect empty-context state (no projects + no chat context) during turn resolution`
- [ ] `T1.2 auto-register/select initial project under mode-specific projects root when unambiguous`
- [ ] `T1.3 keep clarify path only for real ambiguity (multiple candidate projects)`

Validation:

- [ ] `fresh dev DB plus first Telegram message resolves context without manual setup`
- [ ] `clarify appears only on real multi-project ambiguity`

### Slice 2: Dev Target-Root Safety Hardening

- status: `pending`
- branch: `feat/slice-2-dev-target-root-safety`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 enforce execution target under ./_workspace/Projects in dev mode`
- [ ] `T2.2 reject harness-root write/run unless explicit override policy exists`
- [ ] `T2.3 emit clear rejection diagnostics for unsafe target roots`

Validation:

- [ ] `dev mutations are blocked outside ./_workspace/Projects/*`
- [ ] `blocked operations return actionable diagnostics`

### Slice 3: Bounded Micro-Loop Execution Engine

- status: `pending`
- branch: `feat/slice-3-bounded-micro-loop-engine`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 add bounded change-turn attempt loop (max_attempts + timeout)`
- [ ] `T3.2 feed validation errors into next planning attempt`
- [ ] `T3.3 persist terminal outcomes: success|max_attempts|blocked`

Validation:

- [ ] `change turns can self-repair without extra user roundtrip`
- [ ] `loop termination is deterministic and bounded`

### Slice 4: Iteration Context Budgeting and Stable Inputs

- status: `pending`
- branch: `feat/slice-4-iteration-context-budgeting`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 enforce top-K significant file budget per iteration`
- [ ] `T4.2 provide concise task goal + snippets + errors + optional previous diff`
- [ ] `T4.3 persist context packet summaries for auditability`

Validation:

- [ ] `planner packets remain bounded and deterministic`
- [ ] `full-repo payloads are avoided by default`

### Slice 5: Human-First Response Envelope and Confirmation UX

- status: `pending`
- branch: `feat/slice-5-human-envelope-and-confirmation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 default Telegram response is concise human-readable summary`
- [ ] `T5.2 optional fenced-json debug envelope via config flag`
- [ ] `T5.3 explicit next-step messaging for confirmation-blocked commit/push`

Validation:

- [ ] `default user output is human-first`
- [ ] `blocked commit/push responses are actionable`

### Slice 6: Unified Turn Trace Correlation

- status: `pending`
- branch: `feat/slice-6-unified-turn-trace-correlation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 propagate one top-level trace id across ingress/planner/execution/response`
- [ ] `T6.2 link per-attempt events under the same turn trace id`
- [ ] `T6.3 keep trace toggles while preserving single-trace query path`

Validation:

- [ ] `one trace id explains the full turn lifecycle`
- [ ] `llm trace and execution trace are correlated by design`

## Event Log

- `2026-04-28 09:00` state=`planning` note=`initialized autonomous-turn-loop cycle from external context notes; slices integrated into one execution flow`
