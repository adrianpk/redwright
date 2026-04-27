# Cycle Plan: Redwright Structured Action Runtime

## Metadata

- cycle_id: `runtime-cycle-2026-04-27-redwright-structured-action-runtime`
- status: `approved`
- owner: `adrianpk`
- created: `2026-04-27`
- updated: `2026-04-27`
- goal: `deliver structured planning and guarded action execution for Telegram-driven software engineering turns`
- scope: `feature`

## Modularity Constraints (Ruby)

- architecture rule: `separate runtime responsibilities into small focused modules/classes; avoid a single monolithic module for planner + context + execution + ingress`
- required boundaries:
- `ingress`: `telegram update fetch/decode + canonical event emission only`
- `context`: `project/workstream resolution and ambiguity handling only`
- `planner`: `llm contract prompting + parse/validate/retry only`
- `executor`: `primitive dispatch + policy checks + action execution only`
- `persistence`: `sqlite repositories and record mapping only`
- `trace`: `llm/sql/runtime trace formatting + emission toggles only`
- interface rule: `cross-boundary calls go through explicit Ruby contracts (small public APIs); no implicit shared mutable state`
- acceptance gate:
- `each slice must keep or improve boundary isolation`
- `no new feature may be added by expanding one catch-all runtime class`

## Slice List

### Slice 1: Planning Contract and Validation Layer

- status: `pending`
- branch: `feat/slice-1-planning-contract-and-validation`
- objective: `define strict planner JSON schema and runtime validator/retry behavior`
- tasks:
- [ ] `T1.1 define planner output schema and action item schema contracts`
- [ ] `T1.2 implement parser/validator with bounded retries on invalid output`
- [ ] `T1.3 add tests for valid, invalid, and partial planner payloads`
- acceptance:
- `runtime rejects malformed planner output and never executes invalid actions`
- `validator emits explicit reasons for rejection`
- planned_commits:
- `feat(planner): add structured planning schema and validator`
- `test(planner): cover schema validation and retry behavior`
- PR:
- `tbd (to be opened from feat/slice-1-planning-contract-and-validation)`

### Slice 2: Context Resolver for Multi-Project Telegram Turns

- status: `pending`
- branch: `feat/slice-2-context-resolver-multiproject`
- objective: `resolve project/workstream safely from chat context and message references`
- tasks:
- [ ] `T2.1 persist per-chat active project/workstream context state`
- [ ] `T2.2 implement explicit reference matching and active-context fallback`
- [ ] `T2.3 emit clarify mode when ambiguity remains`
- acceptance:
- `unambiguous turns resolve without extra prompt`
- `ambiguous turns produce clarification and no execution`
- planned_commits:
- `feat(context): add multi-project context resolver for telegram turns`
- `test(context): validate explicit match, fallback, and ambiguity paths`
- PR:
- `tbd (to be opened from feat/slice-2-context-resolver-multiproject)`

### Slice 3: Primitive Executor Core (Filesystem + Command)

- status: `pending`
- branch: `feat/slice-3-primitive-executor-core`
- objective: `execute v1 primitives safely with policy checks and evidence capture`
- tasks:
- [ ] `T3.1 implement primitive dispatcher for list/read/search/run/write/apply_patch`
- [ ] `T3.2 enforce worktree boundaries and timeout policy`
- [ ] `T3.3 persist per-action result artifacts (status/stdout/stderr/error)`
- acceptance:
- `at least one non-trivial primitive action mutates expected target files`
- `failed actions persist diagnostics without crashing daemon`
- planned_commits:
- `feat(executor): add primitive action dispatcher and result persistence`
- `test(executor): cover success/failure and boundary enforcement`
- PR:
- `tbd (to be opened from feat/slice-3-primitive-executor-core)`

### Slice 4: Git Primitive Layer

- status: `pending`
- branch: `feat/slice-4-git-primitives`
- objective: `add constrained git primitives for status/branch/commit/push in active worktree`
- tasks:
- [ ] `T4.1 implement git_status and git_branch primitives`
- [ ] `T4.2 implement git_commit and git_push primitives with confirmation policy`
- [ ] `T4.3 add tests for branch scope and error mapping`
- acceptance:
- `git primitives operate only in resolved worktree`
- `unsafe operations require explicit confirmation policy`
- planned_commits:
- `feat(git): add guarded git primitives to executor`
- `test(git): validate worktree scoping and command outcomes`
- PR:
- `tbd (to be opened from feat/slice-4-git-primitives)`

### Slice 5: Planner-Executor Integration in Daemon Turn Loop

- status: `pending`
- branch: `feat/slice-5-turn-orchestration`
- objective: `connect context resolver, planner, validator, and executor into one turn pipeline`
- tasks:
- [ ] `T5.1 wire end-to-end turn orchestration`
- [ ] `T5.2 ensure clarification path bypasses execution`
- [ ] `T5.3 compose Telegram response from execution summary`
- acceptance:
- `single Telegram turn can result in concrete action execution and concise response`
- `clarify turns return questions and perform no action execution`
- planned_commits:
- `feat(runtime): orchestrate context-plan-execute turn pipeline`
- `test(runtime): add end-to-end orchestration coverage`
- PR:
- `tbd (to be opened from feat/slice-5-turn-orchestration)`

### Slice 6: Observability and Evidence Correlation

- status: `pending`
- branch: `feat/slice-6-execution-observability`
- objective: `persist and expose per-turn and per-action observability artifacts`
- tasks:
- [ ] `T6.1 add turn/action trace correlation ids to persistence`
- [ ] `T6.2 emit planner and executor traces with class-specific toggles`
- [ ] `T6.3 provide query surface for recent turn/action evidence`
- acceptance:
- `operator can inspect one turn and all associated action outcomes`
- `trace classes can be enabled/disabled independently`
- planned_commits:
- `feat(trace): add turn-action correlation and class toggles`
- `test(trace): validate evidence persistence and retrieval`
- PR:
- `tbd (to be opened from feat/slice-6-execution-observability)`

### Slice 7: Skill System Scaffold Interfaces

- status: `pending`
- branch: `feat/slice-7-skill-scaffold`
- objective: `introduce minimal extension seams for future declarative skill loading`
- tasks:
- [ ] `T7.1 define skill manifest interface and loader contract`
- [ ] `T7.2 add planner/executor hook points for skill dispatch`
- [ ] `T7.3 add no-op reference skill fixture and tests`
- acceptance:
- `runtime exposes stable extension seams without changing core flow semantics`
- `skill scaffold remains optional and does not block baseline execution`
- planned_commits:
- `feat(skills): add skill scaffold interfaces and loader seam`
- `test(skills): validate skill registration and no-op dispatch`
- PR:
- `tbd (to be opened from feat/slice-7-skill-scaffold)`

## Global Exit Criteria

- `Telegram turns can trigger structured, validated, and concrete execution actions`
- `execution is safe-by-default for multi-project ambiguity and filesystem boundaries`
- `action evidence is persisted and correlated to each turn`
- `runtime remains extensible for future skill-based behavior`
