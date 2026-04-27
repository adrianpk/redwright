# Cycle Tracker: Redwright Structured Action Runtime

## Metadata

- cycle_id: `runtime-cycle-2026-04-27-redwright-structured-action-runtime`
- status: `in_progress`
- state: `implementation`
- updated: `2026-04-27`
- active_slice: `slice-1`
- active_task: `none`

## Slice Progress

### Slice 1: Planning Contract and Validation Layer

- status: `completed`
- branch: `feat/slice-1-planning-contract-and-validation`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `01270df`

Tasks:

- [x] `T1.1 define planner output schema and action item schema contracts`
- [x] `T1.2 implement parser/validator with bounded retries on invalid output`
- [x] `T1.3 add tests for valid, invalid, and partial planner payloads`

Commits:

- [x] `bdb8e2a feat(planner): add strict planning contract and validator retries`
- [x] `01270df test(planner): cover contract validation and bounded retry behavior`

Validation:

- [x] `runtime rejects malformed planner output and never executes invalid actions`
- [x] `validator emits explicit reasons for rejection`

### Slice 2: Context Resolver for Multi-Project Telegram Turns

- status: `pending`
- branch: `feat/slice-2-context-resolver-multiproject`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T2.1 persist per-chat active project/workstream context state`
- [ ] `T2.2 implement explicit reference matching and active-context fallback`
- [ ] `T2.3 emit clarify mode when ambiguity remains`

Commits:

- [ ] `<sha> feat(context): add multi-project context resolver for telegram turns`
- [ ] `<sha> test(context): validate explicit match, fallback, and ambiguity paths`

Validation:

- [ ] `unambiguous turns resolve without extra prompt`
- [ ] `ambiguous turns produce clarification and no execution`

### Slice 3: Primitive Executor Core (Filesystem + Command)

- status: `pending`
- branch: `feat/slice-3-primitive-executor-core`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T3.1 implement primitive dispatcher for list/read/search/run/write/apply_patch`
- [ ] `T3.2 enforce worktree boundaries and timeout policy`
- [ ] `T3.3 persist per-action result artifacts (status/stdout/stderr/error)`

Commits:

- [ ] `<sha> feat(executor): add primitive action dispatcher and result persistence`
- [ ] `<sha> test(executor): cover success/failure and boundary enforcement`

Validation:

- [ ] `at least one non-trivial primitive action mutates expected target files`
- [ ] `failed actions persist diagnostics without crashing daemon`

### Slice 4: Git Primitive Layer

- status: `pending`
- branch: `feat/slice-4-git-primitives`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 implement git_status and git_branch primitives`
- [ ] `T4.2 implement git_commit and git_push primitives with confirmation policy`
- [ ] `T4.3 add tests for branch scope and error mapping`

Commits:

- [ ] `<sha> feat(git): add guarded git primitives to executor`
- [ ] `<sha> test(git): validate worktree scoping and command outcomes`

Validation:

- [ ] `git primitives operate only in resolved worktree`
- [ ] `unsafe operations require explicit confirmation policy`

### Slice 5: Planner-Executor Integration in Daemon Turn Loop

- status: `pending`
- branch: `feat/slice-5-turn-orchestration`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 wire end-to-end turn orchestration`
- [ ] `T5.2 ensure clarification path bypasses execution`
- [ ] `T5.3 compose Telegram response from execution summary`

Commits:

- [ ] `<sha> feat(runtime): orchestrate context-plan-execute turn pipeline`
- [ ] `<sha> test(runtime): add end-to-end orchestration coverage`

Validation:

- [ ] `single Telegram turn can result in concrete action execution and concise response`
- [ ] `clarify turns return questions and perform no action execution`

### Slice 6: Observability and Evidence Correlation

- status: `pending`
- branch: `feat/slice-6-execution-observability`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T6.1 add turn/action trace correlation ids to persistence`
- [ ] `T6.2 emit planner and executor traces with class-specific toggles`
- [ ] `T6.3 provide query surface for recent turn/action evidence`

Commits:

- [ ] `<sha> feat(trace): add turn-action correlation and class toggles`
- [ ] `<sha> test(trace): validate evidence persistence and retrieval`

Validation:

- [ ] `operator can inspect one turn and all associated action outcomes`
- [ ] `trace classes can be enabled/disabled independently`

### Slice 7: Skill System Scaffold Interfaces

- status: `pending`
- branch: `feat/slice-7-skill-scaffold`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T7.1 define skill manifest interface and loader contract`
- [ ] `T7.2 add planner/executor hook points for skill dispatch`
- [ ] `T7.3 add no-op reference skill fixture and tests`

Commits:

- [ ] `<sha> feat(skills): add skill scaffold interfaces and loader seam`
- [ ] `<sha> test(skills): validate skill registration and no-op dispatch`

Validation:

- [ ] `runtime exposes stable extension seams without changing core flow semantics`
- [ ] `skill scaffold remains optional and does not block baseline execution`

## Event Log

- `2026-04-27 17:45` state=`planning` note=`initialized structured-action-runtime cycle with approved slice map and tracker baseline`
- `2026-04-27 19:21` state=`implementation` slice=`slice-1` note=`completed strict planner contract + validator + bounded retry behavior with unit validation`
- `2026-04-27 19:21` validation=`bundle exec ruby -Itest test/redwright/planner_payload_validator_test.rb`
- `2026-04-27 19:21` validation=`bundle exec ruby -Itest test/redwright/llm_intent_interpreter_test.rb`
- `2026-04-27 19:21` validation=`bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`
