# Cycle Plan: RedWright Autonomous Turn Loop

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-autonomous-turn-loop`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-28`
- updated: `2026-04-28`
- goal: `make Telegram turns converge autonomously with safe execution roots, first-run usability, and deterministic diagnostics`
- scope: `feature`

## Slice List

### Slice 1: First-Run Context Bootstrap

- status: `pending`
- branch: `feat/slice-1-first-run-context-bootstrap`
- objective: `remove manual DB/project setup from first-run and auto-establish project context when unambiguous`
- tasks:
- [ ] `T1.1 detect empty-context state (no projects + no chat context) during turn resolution`
- [ ] `T1.2 auto-register/select initial project under mode-specific projects root when unambiguous`
- [ ] `T1.3 keep clarify path only for real ambiguity (multiple candidate projects)`
- acceptance:
- `fresh dev DB plus first Telegram message does not return 'No active project context found'`
- `runtime sets active project context automatically when exactly one candidate is valid`
- `manual sqlite manipulation is never required for onboarding`
- planned_commits:
- `feat(context): add first-run context bootstrap for unambiguous turns`
- `test(context): cover empty-db onboarding and ambiguity guardrails`
- PR:
- `tbd (to be opened from feat/slice-1-first-run-context-bootstrap)`

### Slice 2: Dev Target-Root Safety Hardening

- status: `pending`
- branch: `feat/slice-2-dev-target-root-safety`
- objective: `enforce deterministic execution target under _workspace projects and prevent accidental harness mutation`
- tasks:
- [ ] `T2.1 enforce resolved execution project path under ./_workspace/Projects in dev mode`
- [ ] `T2.2 reject write/run primitives against harness repo root unless explicit override policy is set`
- [ ] `T2.3 surface clear operator-facing rejection reason when target root is unsafe`
- acceptance:
- `dev mode actions cannot mutate /lab/redwright unless explicitly authorized`
- `all project mutations resolve to ./_workspace/Projects/* in dev mode`
- `rejection diagnostics identify blocked path and policy rule`
- planned_commits:
- `fix(paths): enforce dev project target-root safety boundaries`
- `test(executor): reject harness-root mutations in dev mode`
- PR:
- `tbd (to be opened from feat/slice-2-dev-target-root-safety)`

### Slice 3: Bounded Micro-Loop Execution Engine

- status: `pending`
- branch: `feat/slice-3-bounded-micro-loop-engine`
- objective: `add bounded iterative repair loop per change-turn using validation feedback`
- tasks:
- [ ] `T3.1 introduce per-turn attempt loop for intent=change with configurable max_attempts and timeout`
- [ ] `T3.2 propagate failure artifacts (errors, prior patch/result summary) into next planning attempt`
- [ ] `T3.3 terminate deterministically with success|max_attempts|blocked reasons`
- acceptance:
- `runtime can execute repair iterations without user roundtrip when validation fails`
- `loop is bounded by attempts and timeout`
- `analysis/meta turns bypass the micro-loop`
- planned_commits:
- `feat(runtime): add bounded change-turn micro-loop with retry-on-validation-failure`
- `test(runtime): validate bounded convergence and terminal outcomes`
- PR:
- `tbd (to be opened from feat/slice-3-bounded-micro-loop-engine)`

### Slice 4: Iteration Context Budgeting and Stable Inputs

- status: `pending`
- branch: `feat/slice-4-iteration-context-budgeting`
- objective: `feed the loop with stable, minimal context packets instead of unbounded repository payload`
- tasks:
- [ ] `T4.1 enforce per-iteration top-K significant files budget (default <= 5)`
- [ ] `T4.2 include concise task goal, relevant snippets, current errors, and optional previous diff`
- [ ] `T4.3 expose context packet summary in trace for auditability`
- acceptance:
- `planner input remains bounded and deterministic across attempts`
- `context packet excludes full-repo dumps by default`
- `trace shows what context budget was used per attempt`
- planned_commits:
- `feat(prompt): add bounded iteration context packet builder`
- `test(prompt): cover context budgeting and deterministic packet composition`
- PR:
- `tbd (to be opened from feat/slice-4-iteration-context-budgeting)`

### Slice 5: Human-First Response Envelope and Confirmation UX

- status: `pending`
- branch: `feat/slice-5-human-envelope-and-confirmation`
- objective: `return concise human summaries by default while preserving optional debug JSON and clear commit-block guidance`
- tasks:
- [ ] `T5.1 make Telegram default response human-readable summary of actions/outcomes`
- [ ] `T5.2 keep optional fenced-json envelope controlled by config flag`
- [ ] `T5.3 when commit/push is blocked by confirmation policy, return explicit actionable next-step text`
- acceptance:
- `default turn output is human-first, not raw status json`
- `debug json can still be emitted in fenced block when enabled`
- `blocked commit/push response explains exactly what user must confirm/do next`
- planned_commits:
- `feat(telegram): add human-first execution summaries with optional debug envelope`
- `test(telegram): cover confirmation-block messaging and debug flag behavior`
- PR:
- `tbd (to be opened from feat/slice-5-human-envelope-and-confirmation)`

### Slice 6: Unified Turn Trace Correlation

- status: `pending`
- branch: `feat/slice-6-unified-turn-trace-correlation`
- objective: `correlate ingress, planner, normalization, execution, and response under one top-level trace id`
- tasks:
- [ ] `T6.1 define one turn trace id propagated end-to-end across runtime stages`
- [ ] `T6.2 persist per-attempt sub-events linked to the same turn trace id`
- [ ] `T6.3 keep trace toggles but make correlation queryable from one trace handle`
- acceptance:
- `operator can follow one turn from ingress to final response with a single trace id`
- `llm and execution traces no longer diverge into unrelated top-level ids`
- `trace query output remains readable in console and persistence`
- planned_commits:
- `feat(trace): unify end-to-end turn correlation id across planner and execution`
- `test(trace): validate single-trace turn linkage across stages`
- PR:
- `tbd (to be opened from feat/slice-6-unified-turn-trace-correlation)`

## Global Exit Criteria

- `first-run telegram usage works without manual project/db preparation`
- `dev mode execution is constrained to ./_workspace/Projects and protects harness source`
- `change turns iterate through bounded repair loop and terminate deterministically`
- `planner receives stable, bounded iteration context`
- `default telegram responses are human-oriented with optional debug envelope`
- `single top-level trace id links ingress -> llm -> execution -> response`
