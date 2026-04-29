# Cycle Plan: RedWright Planner Prompt Contract Hardening

## Metadata

- cycle_id: `rw-2026-04-30-planner-prompt-contract-hardening`
- status: `completed`
- owner: `adrianpk`
- created: `2026-04-30`
- updated: `2026-04-30`
- goal: `make planner output contract semantically explicit and deterministic by embedding canonical JSON examples and per-field semantics in the planner prompt`
- scope: `feature`

## Slice List

### Slice 1: Planner Prompt Contract Hardening

- status: `completed`
- branch: `fix/slice-1-planner-prompt-contract-hardening`
- objective: `upgrade planner contract instructions so strict JSON structure and semantics are unambiguous without adding ad-hoc runtime routing rules`
- tasks:
- [x] `T1.1 update planner contract prompt with one canonical full JSON example including all required keys`
- [x] `T1.2 add explicit field-level semantics and decision rules for intent/control/operational/gaps behavior`
- [x] `T1.3 add strict output constraints block (no extra keys, no markdown fences, no prose)`
- [x] `T1.4 extend prompt builder and interpreter tests to lock contract presence and ambiguity handling regressions`
- acceptance:
- `planner prompt includes canonical JSON example and semantics block`
- `existing planner payload validator contract remains green with added regression coverage`
- planned_commits:
- `fix(planner): harden output contract with canonical json and field semantics`
- `test(planner): lock prompt contract and ambiguity regression coverage`
- PR:
- `tbd`

## Global Exit Criteria

- `single slice is delivered through one PR only`
- `target test suite for planner contract/prompt/validator/interpreter passes before merge`
