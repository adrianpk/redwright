# Cycle Plan: RedWright Formal Schema and Workflow Convergence

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `enforce a strict machine-validated planner schema and restore deterministic clarification-to-execution workflow behavior across telegram runtime turns`
- tracker: `ops/trackers/2026-04-29-redwright-formal-schema-and-workflow-convergence-cycle-tracker.md`
- spec: `ops/specs/specs/2026-04-29-redwright-minimal-runtime-and-skills-spec.md`

## Principles

- Schema is executable contract, not prose.
- Clarification state gates planner interpretation.
- Control intents must never hijack clarification answers.
- Telegram turn handling must produce one deterministic terminal branch.
- Failures must be observable through typed rejection reasons.

## Slice List

### Slice 1: Planner JSON Schema V1 (Closed Contract)

- status: `pending`
- branch: `feat/slice-1-planner-json-schema-v1`
- [ ] `S1.1 add canonical JSON Schema file for planner output with additionalProperties=false at every object level`
- [ ] `S1.2 include strict required keys and enums for top-level, actions, gaps, and skill_actions`
- [ ] `S1.3 support explicit oneOf shape for write_files args (map or array-of-file-objects)`
- [ ] `S1.4 replace prose-only contract usage in validator path with schema-first validation`
- [ ] `S1.5 add validator tests for unknown keys, wrong enum, wrong type, and missing required fields`

### Slice 2: Clarification-First Routing Determinism

- status: `pending`
- branch: `feat/slice-2-clarification-first-routing`
- [ ] `S2.1 enforce gate: if clarification session is open, route turn to clarification resolver before planner interpretation`
- [ ] `S2.2 enforce deterministic yes/no handling only when an active question exists`
- [ ] `S2.3 add explicit terminal branch for "no active question to confirm" to avoid ambiguous meta loops`
- [ ] `S2.4 persist clarification transition reason codes for traceability`
- [ ] `S2.5 add tests for yes/no with open gap, yes/no without open gap, and continue-with-current-context resolution`

### Slice 3: Control Intent and Clarification Boundary

- status: `pending`
- branch: `feat/slice-3-control-clarification-boundary`
- [ ] `S3.1 enforce precedence table: slash-control > active-clarification-answer > semantic-control > planner`
- [ ] `S3.2 prevent planner-returned control_intent from cancelling unrelated open clarification scopes`
- [ ] `S3.3 add explicit mapping for "no more questions, continue" to proceed_with_current_context when gap is open`
- [ ] `S3.4 add tests for cancel_clarification_only vs cancel_task vs cancel_all scope behavior`

### Slice 4: Workflow Convergence and Retry Policy for Action Macros

- status: `pending`
- branch: `feat/slice-4-workflow-convergence-macro-retry`
- [ ] `S4.1 normalize macro payload variants before execution (write_files/run_commands) with typed errors`
- [ ] `S4.2 add bounded retry path for recoverable planner payload shape errors with feedback-injected re-prompt`
- [ ] `S4.3 persist structured rejection classes (schema_error, macro_shape_error, execution_error)`
- [ ] `S4.4 add tests proving fail->repair->execute convergence within bounded attempts`

### Slice 5: Telegram Runtime E2E Contract and Observability

- status: `pending`
- branch: `feat/slice-5-telegram-runtime-e2e-contract`
- [ ] `S5.1 add simulated telegram E2E scenarios covering /project new, clarification loop, continue, and execution`
- [ ] `S5.2 assert deterministic message envelope semantics for human response + optional JSON envelope`
- [ ] `S5.3 add trace assertions for LLM request/response and terminal branch reason per turn`
- [ ] `S5.4 define acceptance matrix for last-mile behavior consistency with runtime expectations`

## Global Exit Criteria

- Planner output is validated against a strict JSON Schema contract.
- Clarification loop converges deterministically without semantic drift.
- Control intents cannot accidentally hijack clarification answers.
- Macro payload variants no longer break execution path for valid planner intent.
- Telegram end-to-end behavior matches expected deterministic branching and observability.
