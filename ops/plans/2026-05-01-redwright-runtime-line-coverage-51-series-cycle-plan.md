# Cycle Plan: RedWright Runtime Line Coverage 51 Series

## Metadata

- cycle_id: `cycle-2026-05-01-redwright-runtime-line-coverage-51-series`
- status: `in_progress`
- owner: `adrianpk`
- created: `2026-05-01`
- updated: `2026-05-01`
- goal: `raise runtime line coverage from 25.12% to at least 51.00% with honest line-based metric`
- scope: `quality`
- source_spec: `n/a (agent-managed quality execution series)`

## Baseline

- metric: `runtime_line_coverage_percent`
- measurement_scope: `lib/redwright/**/*.rb`
- baseline_lines_total: `5208`
- baseline_lines_covered: `1308`
- baseline_percent: `25.12`
- target_percent: `51.00`
- target_lines_covered_min: `2657`
- required_additional_lines_covered: `1349`

## Slice Strategy

- Each slice targets one or two heavy modules plus adjacent collaborators.
- Each slice must deliver at least `+5.00` absolute coverage points versus previous merged baseline.
- If a slice exceeds `+5.00`, that delta counts fully toward the global target.

## Slice List

### Slice 1: Handler and Dispatcher Branch Expansion

- status: `pending`
- branch: `fix/slice-1-coverage-handler-dispatcher`
- objective: `expand line coverage for runtime handler/dispatcher control, error, and operational branches`
- tasks:
- [ ] `T1.1 add branch matrix tests for telegram_runtime_handler including error and control edge paths`
- [ ] `T1.2 add deep branch tests for server_runtime_dispatcher operational/read-only paths`
- [ ] `T1.3 validate net coverage increase >= +5.00 points`
- planned_commits:
- `test(runtime): expand telegram handler branch coverage`
- `test(runtime): expand server dispatcher branch coverage`
- `chore(quality): refresh coverage artifacts after slice 1`

### Slice 2: Runtime Flow and Executor Deep Paths

- status: `pending`
- branch: `fix/slice-2-coverage-flow-executor`
- objective: `cover runtime flow transitions, retries, and primitive executor failure branches`
- tasks:
- [ ] `T2.1 add runtime_flow transition and retry-path tests`
- [ ] `T2.2 add primitive_executor error-path and boundary tests`
- [ ] `T2.3 validate net coverage increase >= +5.00 points`
- planned_commits:
- `test(runtime): increase runtime flow transition coverage`
- `test(runtime): increase primitive executor error-path coverage`
- `chore(quality): refresh coverage artifacts after slice 2`

### Slice 3: Core CLI Runtime and Integration Paths

- status: `pending`
- branch: `fix/slice-3-coverage-cli-runtime-core`
- objective: `cover core CLI runtime command routing and exit/error branches`
- tasks:
- [ ] `T3.1 add tests for redwright CLI routing branches and failure exits`
- [ ] `T3.2 add tests for command orchestration boundaries touching runtime stores`
- [ ] `T3.3 validate net coverage increase >= +5.00 points`
- planned_commits:
- `test(cli): expand runtime routing branch coverage`
- `test(runtime): cover command orchestration boundary paths`
- `chore(quality): refresh coverage artifacts after slice 3`

### Slice 4: Context, Planner, and Control Contracts

- status: `pending`
- branch: `fix/slice-4-coverage-context-planner-control`
- objective: `cover low-coverage context/planner/control modules with branch-driven tests`
- tasks:
- [ ] `T4.1 add tests for telegram_context_resolver and control_router edge branches`
- [ ] `T4.2 add tests for planner_payload_validator and prompt context branch paths`
- [ ] `T4.3 validate net coverage increase >= +5.00 points`
- planned_commits:
- `test(runtime): expand context resolver and control router branch coverage`
- `test(planner): expand payload validator and prompt context branch coverage`
- `chore(quality): refresh coverage artifacts after slice 4`

### Slice 5: Persistence and Store Behavior Matrix

- status: `pending`
- branch: `fix/slice-5-coverage-persistence-stores`
- objective: `cover persistence/store edge branches and query failure handling`
- tasks:
- [ ] `T5.1 add tests for store-layer edge cases and error branches`
- [ ] `T5.2 add tests for cross-store consistency paths used by runtime loops`
- [ ] `T5.3 validate net coverage increase >= +5.00 points`
- planned_commits:
- `test(stores): add edge-case branch coverage for runtime stores`
- `test(runtime): add cross-store consistency coverage`
- `chore(quality): refresh coverage artifacts after slice 5`

### Slice 6: Final Push to 51 and Closure

- status: `pending`
- branch: `fix/slice-6-coverage-final-51-closure`
- objective: `close remaining gap to >=51.00 with targeted branch additions and final evidence`
- tasks:
- [ ] `T6.1 target top uncovered modules by line count until threshold is reached`
- [ ] `T6.2 run final quality gate and capture evidence`
- [ ] `T6.3 update tracker with closure metrics and merge evidence`
- planned_commits:
- `test(runtime): close remaining uncovered high-impact branches`
- `chore(quality): capture final 51-plus coverage evidence`
- `docs(ops): close runtime line coverage 51 series tracker`

## Global Exit Criteria

- `runtime_line_coverage_percent >= 51.00`
- `all slices merged to dev through branch+PR flow`
- `each slice reports >= +5.00 absolute point increase`
- `coverage metric definition remains explicit and honest`
