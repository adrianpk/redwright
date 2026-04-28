# Cycle Plan: RedWright Adaptive Alignment Loop (AAL)

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-adaptive-alignment-loop`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-28`
- updated: `2026-04-28`
- goal: `replace fixed alignment battery with an LLM-governed project-scoped loop that supports controlled convergence, user pause/stop, and clean persistent semantics`
- scope: `feature`

## Operating Principles

- `greenfield rule`: no legacy contract is preserved just because it already exists.
- `one question per turn`: alignment asks exactly one high-leverage question each turn.
- `bounded but configurable`: maximum attempts/turns are config-driven and hard-enforced.
- `user agency`: user can pause or stop alignment explicitly at any point.
- `no unusable residue`: persistence must not accumulate orphan/incoherent alignment records.

## Slice List

### Slice 1: Runtime Contract for Adaptive Alignment Loop

- status: `pending`
- branch: `feat/slice-1-aal-runtime-contract`
- objective: `formalize AAL turn contract and state transitions as first-class runtime primitives`
- tasks:
- [ ] `T1.1 define alignment turn payload schema (question, recommendation, rationale, decision node, dependencies, completion status)`
- [ ] `T1.2 define terminal states (`continue|ready|user_stop|blocked`) and transition rules`
- [ ] `T1.3 define config keys for bounded loop control (max_turns, timeout, stop policy)`
- acceptance:
- `AAL contract is explicit and testable`
- `state transitions are deterministic and documented`
- planned_commits:
- `docs(spec): define adaptive alignment loop runtime contract`
- `test(contract): validate alignment terminal-state transitions`
- PR:
- `tbd (to be opened from feat/slice-1-aal-runtime-contract)`

### Slice 2: Project-Scoped Semantic Alignment Memory (PSAM) Schema

- status: `pending`
- branch: `feat/slice-2-psam-schema`
- objective: `introduce normalized alignment persistence for question-turn semantics and retrieval`
- tasks:
- [ ] `T2.1 add sqlite tables for alignment_questions, alignment_answers, semantic tags, dependencies, artifact links`
- [ ] `T2.2 add migration/bootstrap compatibility for fresh and existing dev databases`
- [ ] `T2.3 add integrity tests to prevent orphan rows and inconsistent turn indexing`
- acceptance:
- `alignment data is project/workstream-scoped and queryable by semantics`
- `schema is SQLite-friendly and normalized`
- planned_commits:
- `feat(db): add project-scoped semantic alignment memory tables`
- `test(db): validate psam integrity and relational constraints`
- PR:
- `tbd (to be opened from feat/slice-2-psam-schema)`

### Slice 3: LLM-Driven One-Question Alignment Engine

- status: `pending`
- branch: `feat/slice-3-llm-alignment-engine`
- objective: `replace fixed question list with LLM-generated next question based on context and prior turns`
- tasks:
- [ ] `T3.1 add alignment planner prompt for next-question generation with recommendation+rationale`
- [ ] `T3.2 enforce one-question-per-turn invariant in runtime`
- [ ] `T3.3 persist generated turn semantics into PSAM tables`
- acceptance:
- `alignment question sequence is dynamic and context-driven`
- `runtime never asks multiple alignment questions in one turn`
- planned_commits:
- `feat(alignment): add llm-driven next-question alignment engine`
- `test(alignment): enforce one-question-per-turn invariant`
- PR:
- `tbd (to be opened from feat/slice-3-llm-alignment-engine)`

### Slice 4: User Pause/Stop and Risk Acknowledgement Flow

- status: `pending`
- branch: `feat/slice-4-user-pause-stop-contract`
- objective: `support explicit user pause/stop actions with auditable unresolved-risk metadata`
- tasks:
- [ ] `T4.1 define pause/stop commands in natural-language handling path`
- [ ] `T4.2 persist stop_reason, risk_acknowledged, open_question_count, open_branch_snapshot`
- [ ] `T4.3 expose deterministic resume behavior from paused state`
- acceptance:
- `user can stop alignment without runtime corruption`
- `partial alignment carries explicit risk metadata`
- planned_commits:
- `feat(alignment): add user pause-stop controls with risk metadata`
- `test(alignment): validate pause-stop-resume lifecycle`
- PR:
- `tbd (to be opened from feat/slice-4-user-pause-stop-contract)`

### Slice 5: Bounded Governance and Adaptive Depth Policy

- status: `pending`
- branch: `feat/slice-5-aal-governance-bounds`
- objective: `govern loop depth by configurable limits while avoiding pointless over-questioning`
- tasks:
- [ ] `T5.1 enforce hard configurable top limit for alignment turns`
- [ ] `T5.2 add adaptive sufficiency heuristic so trivial scopes converge early`
- [ ] `T5.3 emit clear terminal reason (`ready|user_stop|max_turns|blocked`)`
- acceptance:
- `loop respects configured upper bound strictly`
- `runtime can finish early when alignment is sufficient`
- planned_commits:
- `feat(runtime): add configurable alignment governance bounds`
- `test(runtime): validate bounded convergence and terminal reasons`
- PR:
- `tbd (to be opened from feat/slice-5-aal-governance-bounds)`

### Slice 6: Clean Persistence and Dev Reset Safety

- status: `pending`
- branch: `feat/slice-6-alignment-persistence-hygiene`
- objective: `guarantee no unusable persistent leftovers and deterministic reset/rebuild behavior in dev`
- tasks:
- [ ] `T6.1 add cleanup/consistency checks for abandoned or partial alignment sessions`
- [ ] `T6.2 ensure fresh DB rebuild path restores valid baseline without manual surgery`
- [ ] `T6.3 add invariant tests for no-residue guarantees after stop/restart/reset`
- acceptance:
- `dev database can be deleted/rebuilt without broken alignment state`
- `no orphan/invalid alignment rows remain after interrupted flows`
- planned_commits:
- `fix(db): add alignment persistence hygiene and reset safety checks`
- `test(invariants): enforce no-residue alignment persistence guarantees`
- PR:
- `tbd (to be opened from feat/slice-6-alignment-persistence-hygiene)`

## Global Exit Criteria

- `fixed hardcoded alignment question battery is no longer runtime-default`
- `AAL is LLM-governed, one-question-per-turn, and bounded by config`
- `user pause/stop decisions are explicit, persistent, and auditable`
- `PSAM schema enables semantic retrieval for downstream planning/execution`
- `persistence remains coherent across interruption, resume, and dev reset`
