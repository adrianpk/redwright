# Cycle Plan: Project New Operational Loop Behavior Implementation

## Metadata

- cycle_id: `cycle-2026-05-01-project-new-operational-loop-behavior`
- status: `draft`
- owner: `adrianpk`
- created: `2026-05-01`
- updated: `2026-05-01`
- goal: `implement predictable /project new conversational loop with DDD-like mediator boundaries and explicit persistence-backed control`
- scope: `feature`
- source_spec: `ops/specs/specs/2026-05-01-project-new-operational-loop-behavior-spec.md`

## Slice List

### Slice 1: Domain Loop Contract and State Machine

- status: `pending`
- branch: `fix/slice-1-project-new-loop-state-machine`
- objective: `materialize explicit loop states, transitions, and terminal outcomes in mediator domain layer`
- tasks:
- [ ] `T1.1 define domain state enum and allowed transitions for /project new loop`
- [ ] `T1.2 implement transition guards for blocking-gaps and explicit proceed-with-defaults`
- [ ] `T1.3 enforce terminal outcomes: cancelled, confirmed_and_executed, proceeded_with_defaults`
- [ ] `T1.4 add invalid-transition handling with deterministic domain errors`
- [ ] `T1.5 add table-driven unit tests for full transition matrix`
- acceptance:
- `all valid transitions pass`
- `all invalid transitions fail with explicit domain errors`
- `terminal outcomes are persisted and visible in response envelope inputs`
- planned_commits:
- `feat(runtime): add project-new loop state machine contract`
- `test(runtime): cover project-new transition matrix`
- PR:
- `tbd`

### Slice 2: Context Slot Model and Sufficiency Engine

- status: `pending`
- branch: `fix/slice-2-project-new-context-sufficiency`
- objective: `implement slot-based context model with blocking/optional classification and execution-readiness evaluation`
- tasks:
- [ ] `T2.1 define canonical slots: project_name, description, stack, framework, architecture_style, test_strategy, packaging_module_convention, constraints`
- [ ] `T2.2 define slot classification policy: blocking vs high-impact-confirmation vs optional`
- [ ] `T2.3 implement merge policy for user-provided + inferred + default-authorized slot values`
- [ ] `T2.4 implement context sufficiency evaluator`
- [ ] `T2.5 add no-reask rule for already-resolved slots`
- [ ] `T2.6 add unit tests for sparse prompt, rich prompt, and mixed-gap prompt variants`
- acceptance:
- `sufficiency evaluator is deterministic for same input snapshot`
- `resolved slots are not re-asked`
- `execution readiness is true only when blocking criteria are satisfied`
- planned_commits:
- `feat(runtime): add project-new slot model and sufficiency evaluator`
- `test(runtime): add project-new context sufficiency coverage`
- PR:
- `tbd`

### Slice 3: Clarification Orchestration and Anti-Loop Guardrails

- status: `pending`
- branch: `fix/slice-3-project-new-clarification-guardrails`
- objective: `wire mediator decisions into clarification sessions with max-turn and stagnation protections`
- tasks:
- [ ] `T3.1 map loop states to clarification session lifecycle operations`
- [ ] `T3.2 implement max_question_turns guardrail for project-new conversational cycle`
- [ ] `T3.3 implement stagnation detector for repeated unresolved blocking slots`
- [ ] `T3.4 implement fallback summary flow requiring explicit cancel or proceed_with_defaults`
- [ ] `T3.5 persist resolved_fields carry-forward for subsequent turns`
- [ ] `T3.6 add tests for max-turn trigger, stagnation trigger, and fallback decisions`
- acceptance:
- `loop cannot continue indefinitely without terminal decision`
- `fallback summary appears when guardrail triggers`
- `resolved field carry-forward is available to next turn`
- planned_commits:
- `feat(runtime): add project-new clarification guardrails`
- `test(runtime): cover project-new anti-loop behaviors`
- PR:
- `tbd`

### Slice 4: Adapter Boundary Enforcement (Telegram and Slash)

- status: `pending`
- branch: `fix/slice-4-project-new-adapter-boundary`
- objective: `enforce adapter-as-wrapper rule and route project-new behavior through mediator API only`
- tasks:
- [ ] `T4.1 introduce explicit mediator command/query entrypoints used by telegram/slash handlers`
- [ ] `T4.2 remove domain branching from adapter paths where project-new decisions are currently inlined`
- [ ] `T4.3 ensure adapter layer performs parse-map-render only`
- [ ] `T4.4 preserve existing command compatibility where behavior is unchanged`
- [ ] `T4.5 add tests asserting adapters delegate decisions to mediator`
- acceptance:
- `adapter-level tests confirm no direct domain decision logic in project-new flow`
- `project-new decisions are fully traceable to mediator outputs`
- planned_commits:
- `refactor(runtime): route project-new decisions through mediator boundary`
- `test(runtime): assert adapter delegation for project-new flow`
- PR:
- `tbd`

### Slice 5: Response Contract and Telemetry Visibility Policy

- status: `pending`
- branch: `fix/slice-5-project-new-response-contract`
- objective: `deliver outcome-first user responses with debug-gated telemetry formatting`
- tasks:
- [ ] `T5.1 implement outcome-first response template for default mode`
- [ ] `T5.2 implement debug/trace flag gate for telemetry visibility`
- [ ] `T5.3 format telemetry identifiers with markdown backticks for messenger surfaces`
- [ ] `T5.4 ensure default mode hides project/workstream/task/trace identifiers`
- [ ] `T5.5 add tests for default vs debug response rendering`
- acceptance:
- `default responses are outcome-first and telemetry-light`
- `debug mode includes telemetry with backtick formatting`
- planned_commits:
- `feat(runtime): add project-new response contract with debug telemetry gate`
- `test(runtime): cover project-new response rendering modes`
- PR:
- `tbd`

### Slice 6: Persistence Correlation and Resume Integrity

- status: `pending`
- branch: `fix/slice-6-project-new-persistence-correlation`
- objective: `harden persistence mapping and resume behavior for cross-turn project-new cycles`
- tasks:
- [ ] `T6.1 enforce chat_context updates aligned with mediator terminal and non-terminal states`
- [ ] `T6.2 validate clarification_sessions/workstreams/tasks coherence per turn`
- [ ] `T6.3 ensure resume behavior restores pending context snapshot deterministically`
- [ ] `T6.4 add persistence integrity checks specific to project-new loop artifacts`
- [ ] `T6.5 add tests for restart/resume and open-session continuity`
- acceptance:
- `cross-turn state survives process restart without context loss`
- `no orphaned project-new clarification records after normal completion`
- planned_commits:
- `feat(runtime): harden project-new persistence correlation and resume integrity`
- `test(runtime): add project-new persistence resume coverage`
- PR:
- `tbd`

### Slice 7: End-to-End Validation and Regression Closure

- status: `pending`
- branch: `fix/slice-7-project-new-e2e-regression-closure`
- objective: `close cycle with scenario matrix validation and regression hardening`
- tasks:
- [ ] `T7.1 build e2e scenario matrix: rich input, sparse input, mixed-gap input, explicit cancel, explicit proceed_with_defaults`
- [ ] `T7.2 add no-reask regression tests for previously supplied fields`
- [ ] `T7.3 validate anti-loop guardrails under repeated ambiguous answers`
- [ ] `T7.4 validate adapter boundary contract remains intact after integration`
- [ ] `T7.5 document final behavior summary and residual risks`
- acceptance:
- `all scenario matrix tests pass`
- `no regressions in existing operational project-new behavior`
- `cycle summary maps outcomes to spec acceptance criteria`
- planned_commits:
- `test(runtime): add project-new end-to-end scenario matrix`
- `docs(spec): publish project-new implementation closure summary`
- PR:
- `tbd`

## Global Exit Criteria

- `all slices are completed and merged to dev in order`
- `spec acceptance criteria are fully satisfied or explicitly waived with rationale`
- `project-new loop no longer exhibits telemetry-first default replies`
- `project-new loop no longer re-asks resolved context`
- `project-new loop always reaches explicit terminal decision`
- `adapter boundary remains wrapper-only for project-new domain behavior`
