# Cycle Plan: Redwright Planner-Executor Hardening

## Metadata

- cycle_id: `runtime-cycle-2026-04-27-redwright-planner-executor-hardening`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-27`
- updated: `2026-04-27`
- goal: `eliminate planner/executor action mismatch and harden prompt construction against injection and policy drift`
- scope: `feature`

## Slice List

### Slice 1: Action Catalog Contract Alignment

- status: `pending`
- branch: `feat/slice-1-action-catalog-alignment`
- objective: `make planner contract, validator, runtime action catalog explicit and consistent, and define product identity in README`
- tasks:
- [ ] `T1.1 define single source of truth for allowed action types`
- [ ] `T1.2 enforce allowed action catalog in payload validator`
- [ ] `T1.3 update planner system prompt to expose exact catalog`
- [ ] `T1.4 create/update README to explain what RedWright is and what it does`
- [ ] `T1.5 keep README scope limited to product identity and behavior (no install/license sections in this slice)`
- acceptance:
- `planner cannot emit undeclared action types without validation failure`
- `runtime errors reference contract violations clearly`
- `README communicates what RedWright is in end-user terms without install/license content`
- planned_commits:
- `feat(planner): align action catalog across prompt and validator`
- `test(planner): reject unsupported action types`
- `docs(readme): define RedWright product identity and behavior scope`
- PR:
- `tbd`

### Slice 2: Macro Normalization Layer

- status: `pending`
- branch: `feat/slice-2-macro-normalization-layer`
- objective: `support ergonomic macro actions while preserving primitive-only execution core`
- tasks:
- [ ] `T2.1 implement normalizer for write_files -> write_file[]`
- [ ] `T2.2 implement normalizer for run_command/run_commands -> run[]`
- [ ] `T2.3 add deterministic ordering and failure behavior for expanded actions`
- acceptance:
- `macro actions are expanded before executor dispatch`
- `executor receives canonical primitive actions only`
- planned_commits:
- `feat(executor): add macro-to-primitive normalization layer`
- `test(executor): cover macro expansion and ordered execution`
- PR:
- `tbd`

### Slice 3: Prompt Context Layering and Injection Guardrails

- status: `pending`
- branch: `feat/slice-3-prompt-layering-guardrails`
- objective: `formalize context layering and precedence to resist prompt-injection attempts`
- tasks:
- [ ] `T3.1 implement prompt builder with Agent/Project/Architecture/Task sections`
- [ ] `T3.2 enforce precedence semantics and forbid lower-layer overrides`
- [ ] `T3.3 add injection-resistance tests with known hostile patterns`
- acceptance:
- `prompt includes all required context sections deterministically`
- `injection attempts do not expand capabilities or bypass policies`
- planned_commits:
- `feat(prompt): add layered prompt builder with precedence rules`
- `test(prompt): add prompt-injection guardrail cases`
- PR:
- `tbd`

### Slice 4: Turn-Path Validation and Traceability

- status: `pending`
- branch: `feat/slice-4-turn-path-validation-traceability`
- objective: `strengthen turn-level diagnostics for planner output, normalization, and execution outcomes`
- tasks:
- [ ] `T4.1 emit normalization trace fields (expanded_count, macro_types)`
- [ ] `T4.2 persist reject reasons for invalid planner payloads`
- [ ] `T4.3 expose clearer operator-facing error path in Telegram response`
- acceptance:
- `operator can explain why a turn was rejected or transformed`
- `trace evidence links planner output -> normalized actions -> execution results`
- planned_commits:
- `feat(trace): add normalization and validation failure evidence`
- `test(trace): verify turn-path diagnostics`
- PR:
- `tbd`

## Global Exit Criteria

- `planner-executor mismatch errors are eliminated for documented action catalog`
- `macro actions are safely normalized into primitive execution`
- `prompt construction follows strict layered context with precedence`
- `runtime rejects policy-override injection attempts`
- `turn traces provide actionable diagnostics for planner and execution phases`
