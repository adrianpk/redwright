# Cycle Plan: RedWright Factory Runtime Foundation

## Metadata

- cycle_id: `rw-2026-04-29-factory-runtime-foundation`
- status: `planned`
- owner: `adrianpk`
- created: `2026-04-29`
- updated: `2026-04-29`
- goal: `establish a test-first architectural foundation for factory-mode execution with a shared command-query core and strong runtime reliability guarantees`
- scope: `feature`

## Slice List

### Slice 1: Repository Structure and Layer Boundaries

- status: `completed`
- branch: `feat/slice-1-factory-repo-structure-boundaries`
- objective: `introduce a clear monorepo layout for core/domain/adapters/runtimes without breaking current runtime paths`
- tasks:
- [ ] `T1.1 define target directory map and ownership rules for core, adapters, apps/web, and runtime modules`
- [ ] `T1.2 add boundary rules in docs/reference and enforce import/dependency direction`
- [ ] `T1.3 add compatibility shims so existing telegram/tui entrypoints keep working`
- acceptance:
- `existing interactive runtime commands still execute with unchanged behavior`
- `boundary contracts are documented and mapped to concrete paths`
- planned_commits:
- `refactor(runtime): introduce factory-ready repository structure boundaries`
- `docs(reference): define layer ownership and dependency direction contract`
- PR:
- `tbd`

### Slice 2: Command-Query Application Core Skeleton

- status: `completed`
- branch: `feat/slice-2-command-query-core-skeleton`
- objective: `create the executable command-query application skeleton used by all ingress adapters`
- tasks:
- [ ] `T2.1 implement command/query envelope validation primitives`
- [ ] `T2.2 implement handler registry with typed execution context`
- [ ] `T2.3 wire telegram/tui ingress through compatibility adapter to semantic core`
- acceptance:
- `no execution path runs from raw text to mutating operations without envelope validation`
- `interactive mode preserves existing behavior through adapter bridge`
- planned_commits:
- `feat(runtime): add command-query core skeleton and envelope validator`
- `refactor(runtime): route ingress adapters through semantic dispatcher`
- PR:
- `tbd`

### Slice 3: Factory Reliability Guardrails

- status: `completed`
- branch: `feat/slice-3-factory-reliability-guardrails`
- objective: `implement runtime guardrails required for safe autonomous execution`
- tasks:
- [ ] `T3.1 add step-scoped timeout policy with step-specific errors`
- [ ] `T3.2 add worktree locking with stale lock recovery`
- [ ] `T3.3 add abort/cancel contract and preserved recovery state`
- [ ] `T3.4 enforce inline-prompt literal mode and template-only expansion`
- acceptance:
- `parallel branch collisions fail deterministically with clear error`
- `stuck lifecycle phases fail by timeout instead of hanging indefinitely`
- planned_commits:
- `feat(runtime): add lifecycle timeout and cancellation guardrails`
- `feat(runtime): add worktree lock manager with stale lock recovery`
- PR:
- `tbd`

### Slice 4: Session Continuity and Runtime Partitioning

- status: `completed`
- branch: `feat/slice-4-session-continuity-and-runtime-partitioning`
- objective: `separate interactive and factory runtime state while preserving optional continuity where explicit`
- tasks:
- [ ] `T4.1 add runtime-scoped state roots for interactive and factory`
- [ ] `T4.2 add session transfer contract for host/sandbox continuity`
- [ ] `T4.3 define and enforce runtime-specific observability envelope`
- acceptance:
- `interactive and factory runtimes do not leak state implicitly`
- `session resume paths are explicit, testable, and auditable`
- planned_commits:
- `feat(runtime): partition interactive and factory state roots`
- `feat(runtime): add session continuity transfer contract`
- PR:
- `tbd`

### Slice 5: Kanban Application Integration Contract

- status: `pending`
- branch: `feat/slice-5-kanban-integration-contract`
- objective: `formalize rails-backed board/ticket integration while preserving harness execution ownership`
- tasks:
- [ ] `T5.1 define ticket/board command-query endpoints and error contract`
- [ ] `T5.2 define assignment-plus-label authorization evaluation order`
- [ ] `T5.3 define dual-bot and dual-runtime ingress policy contract`
- acceptance:
- `ticket state source-of-truth is explicit and singular`
- `role constraints coder/reviewer/merger are enforced outside prompts`
- planned_commits:
- `docs(reference): define kanban integration contract v1`
- `feat(runtime): enforce role and visibility policy checks in handlers`
- PR:
- `tbd`

## Global Exit Criteria

- `all slices have passing test coverage for new behavior before merge`
- `interactive mode remains backward-compatible while factory primitives become executable`
- `runtime reliability guardrails are implemented and covered by deterministic tests`
