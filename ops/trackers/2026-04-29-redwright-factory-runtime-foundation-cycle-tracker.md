# Cycle Tracker: RedWright Factory Runtime Foundation

## Metadata

- cycle_id: `rw-2026-04-29-factory-runtime-foundation`
- status: `in_progress`
- state: `next_slice`
- updated: `2026-04-29`
- active_slice: `slice_2`
- active_task: `T2.3`

## Slice Progress

### Slice 1: Repository Structure and Layer Boundaries

- status: `completed`
- branch: `feat/slice-1-factory-repo-structure-boundaries`
- PR: `#152`
- merge_target: `dev`
- last_sync_commit: `be89dcb`

Tasks:

- [x] `T1.1 define target directory map and ownership rules for core, adapters, apps/web, and runtime modules`
- [x] `T1.2 add boundary rules in docs/reference and enforce import/dependency direction`
- [x] `T1.3 add compatibility shims so existing telegram/tui entrypoints keep working`

Commits:

- [ ] `<sha> refactor(runtime): introduce factory-ready repository structure boundaries`
- [ ] `<sha> docs(reference): define layer ownership and dependency direction contract`

Validation:

- [ ] `bundle exec rake test`
- [ ] `bundle exec ruby -Itest test/redwright/daemon_cli_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/runtime_flow_test.rb`

### Slice 2: Command-Query Application Core Skeleton

- status: `completed`
- branch: `feat/slice-2-command-query-core-skeleton`
- PR: `#155`
- merge_target: `dev`
- last_sync_commit: `3b65c8e`

Tasks:

- [x] `T2.1 implement command/query envelope validation primitives`
- [x] `T2.2 implement handler registry with typed execution context`
- [x] `T2.3 wire telegram/tui ingress through compatibility adapter to semantic core`

Commits:

- [ ] `<sha> feat(runtime): add command-query core skeleton and envelope validator`
- [ ] `<sha> refactor(runtime): route ingress adapters through semantic dispatcher`

Validation:

- [ ] `bundle exec ruby -Itest test/redwright/planner_response_validator_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/cross_channel_parity_matrix_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 3: Factory Reliability Guardrails

- status: `completed`
- branch: `feat/slice-3-factory-reliability-guardrails`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [x] `T3.1 add step-scoped timeout policy with step-specific errors`
- [x] `T3.2 add worktree locking with stale lock recovery`
- [x] `T3.3 add abort/cancel contract and preserved recovery state`
- [x] `T3.4 enforce inline-prompt literal mode and template-only expansion`

Commits:

- [ ] `<sha> feat(runtime): add lifecycle timeout and cancellation guardrails`
- [ ] `<sha> feat(runtime): add worktree lock manager with stale lock recovery`

Validation:

- [ ] `bundle exec ruby -Itest test/redwright/worktree_manager_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/daemon_cli_test.rb -n "/tui_ingress|none_ingress/"`
- [ ] `bundle exec ruby -Itest test/redwright/simulated_ingress_e2e_test.rb`

### Slice 4: Session Continuity and Runtime Partitioning

- status: `pending`
- branch: `feat/slice-4-session-continuity-and-runtime-partitioning`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T4.1 add runtime-scoped state roots for interactive and factory`
- [ ] `T4.2 add session transfer contract for host/sandbox continuity`
- [ ] `T4.3 define and enforce runtime-specific observability envelope`

Commits:

- [ ] `<sha> feat(runtime): partition interactive and factory state roots`
- [ ] `<sha> feat(runtime): add session continuity transfer contract`

Validation:

- [ ] `bundle exec ruby -Itest test/redwright/runtime_session_store_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/server_runtime_dispatcher_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/telegram_runtime_handler_test.rb`

### Slice 5: Kanban Application Integration Contract

- status: `pending`
- branch: `feat/slice-5-kanban-integration-contract`
- PR: `tbd`
- merge_target: `dev`
- last_sync_commit: `tbd`

Tasks:

- [ ] `T5.1 define ticket/board command-query endpoints and error contract`
- [ ] `T5.2 define assignment-plus-label authorization evaluation order`
- [ ] `T5.3 define dual-bot and dual-runtime ingress policy contract`

Commits:

- [ ] `<sha> docs(reference): define kanban integration contract v1`
- [ ] `<sha> feat(runtime): enforce role and visibility policy checks in handlers`

Validation:

- [ ] `bundle exec ruby -Itest test/redwright/ticket_visibility_policy_test.rb`
- [ ] `bundle exec ruby -Itest test/redwright/runtime_flow_test.rb`
- [ ] `bundle exec rake test:invariants`

## Event Log

- `2026-04-29 22:05` state=`planning` note=`formalized factory runtime foundation cycle with 5 slices and reliability guardrail ADR linkage`
- `2026-04-29 22:40` state=`executing_slice` note=`started slice 1 task T1.1 and documented target repository structure and ownership map`
- `2026-04-29 22:58` state=`executing_slice` note=`completed T1.1 and started T1.2 with dependency-direction contract and automated boundary check`
- `2026-04-29 23:12` state=`executing_slice` note=`completed T1.2 and T1.3 by adding runtime entrypoint shim preserving CLI behavior for existing ingress entrypaths`
- `2026-04-29 23:28` state=`next_slice` note=`slice 1 merged to dev via PR #152; moved cycle focus to slice 2 task T2.1`
- `2026-04-29 23:39` state=`executing_slice` note=`implemented T2.1 command-query envelope validation primitives with unit coverage`
- `2026-04-29 23:54` state=`executing_slice` note=`implemented T2.2 handler registry with typed execution context and dispatch error contract`
- `2026-04-30 00:06` state=`executing_slice` note=`completed T2.3 by wiring telegram ingress through semantic compatibility adapter with unit and handler integration tests`
- `2026-04-30 00:24` state=`next_slice` note=`slice 2 merged to dev via PR #155; moved cycle focus to slice 3 task T3.1`
- `2026-04-30 00:53` state=`executing_slice` note=`completed T3.1 by adding step-scoped timeout wrappers and step-specific timeout errors in daemon runtime flow`
- `2026-04-30 01:16` state=`executing_slice` note=`completed T3.2 with lock-file based worktree locking, stale lock recovery, and fail-fast contention behavior`
- `2026-04-30 01:27` state=`executing_slice` note=`completed T3.3 by adding daemon cancel contract with explicit stop reasons and preserved pending-event count`
- `2026-04-30 01:43` state=`next_slice` note=`completed T3.4 and closed slice 3 reliability guardrails; next active slice set to slice 4`
