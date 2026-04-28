# Cycle Plan: Redwright Semantic Deterministic Runtime V2

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-semantic-deterministic-runtime-v2`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-28`
- updated: `2026-04-28`
- goal: `implement deterministic state runtime with semantic packeting, dynamic gap clarification, and bounded internal convergence loop`
- scope: `feature`

## Slice List

### Slice 1: State Contract and Terminal Reasons

- status: `pending`
- branch: `feat/slice-1-runtime-v2-state-contract`
- objective: `formalize runtime states, transitions, and explicit terminal reasons`
- tasks:
- [ ] `T1.1 implement static transition matrix for v2 states`
- [ ] `T1.2 enforce transition validation in runtime entrypoints`
- [ ] `T1.3 persist terminal reason in runtime results`
- acceptance:
- `invalid transitions are rejected deterministically`
- `every terminal path emits explicit terminal reason`

### Slice 2: Semantic Packet V2 (Tree + Files + Errors)

- status: `pending`
- branch: `feat/slice-2-semantic-packet-v2`
- objective: `add canonical LLM packet contract including file tree, selected files, and accumulated error context`
- tasks:
- [ ] `T2.1 define strict packet schema and serializer`
- [ ] `T2.2 add tree snapshot capture with configurable limits`
- [ ] `T2.3 add file-selection heuristics and bounded payload sizing`
- [ ] `T2.4 include compile/test/runtime error context on retries`
- acceptance:
- `packet is schema-valid and bounded`
- `retry packets include structured error evidence`

### Slice 3: Dynamic Gap Collection and Clarification Engine

- status: `pending`
- branch: `feat/slice-3-dynamic-gap-clarification`
- objective: `replace mechanical questioning with semantic gap handling`
- tasks:
- [ ] `T3.1 add gap extraction contract in planner response`
- [ ] `T3.2 implement inferred-project-name confirmation flow`
- [ ] `T3.3 consume multi-answer user replies and skip solved gaps`
- [ ] `T3.4 enforce one high-value clarification question when ambiguity remains`
- acceptance:
- `inferred project name confirmation is required when explicit name absent`
- `resolved gaps are not re-asked`

### Slice 4: Internal Convergence Loop V2

- status: `pending`
- branch: `feat/slice-4-internal-convergence-loop-v2`
- objective: `implement bounded mini-loop that iterates until converge/block/clarify`
- tasks:
- [ ] `T4.1 run execute->verify->refine loop inside one user turn`
- [ ] `T4.2 enforce max_attempts and max_turn_seconds bounds`
- [ ] `T4.3 classify loop exits into terminal reasons`
- acceptance:
- `turn loop converges or exits with explicit non-success reason`
- `no premature user response before loop exit unless clarify/block`

### Slice 5: Dual Mode Orchestration (Structured + Direct)

- status: `pending`
- branch: `feat/slice-5-dual-mode-orchestration`
- objective: `support both structured lifecycle and direct request workflow`
- tasks:
- [ ] `T5.1 add mode inference with explicit override support`
- [ ] `T5.2 preserve structured flow (alignment/planning/slicing/pr delivery)`
- [ ] `T5.3 preserve direct flow (targeted bugfix/task execution)`
- acceptance:
- `both modes are reachable and deterministic`
- `mode selection is auditable`

### Slice 6: Multi-Stack Semantics Without Hardcoded Workflow Branches

- status: `pending`
- branch: `feat/slice-6-multistack-semantic-runtime`
- objective: `enable stack-aware execution via semantic evidence without router if-chains`
- tasks:
- [ ] `T6.1 encode stack/toolchain hints in semantic packet`
- [ ] `T6.2 validate workflow core has no language-specific branching for semantics`
- [ ] `T6.3 add tests across at least two stack fixtures`
- acceptance:
- `requests for different stacks run through same workflow core`
- `no hardcoded language-specific state routing`

### Slice 7: End-to-End Tests for Clarification, Convergence, and Persistence

- status: `pending`
- branch: `feat/slice-7-runtime-v2-e2e-and-persistence`
- objective: `prove end-to-end behavior with deterministic auditable outcomes`
- tasks:
- [ ] `T7.1 add e2e scenario: inferred project name confirmation`
- [ ] `T7.2 add e2e scenario: multi-gap response consumption`
- [ ] `T7.3 add e2e scenario: convergence with retry after verification error`
- [ ] `T7.4 assert persistence records for packets/actions/errors/terminal reason`
- acceptance:
- `all e2e invariants pass under isolated testing roots`

## Global Exit Criteria

- deterministic state machine contract enforced
- semantic packet v2 used on all LLM iterations
- clarification engine handles inferred name and dynamic gaps naturally
- bounded internal loop converges or exits with terminal reason
- dual mode orchestration works with auditable mode selection
- multi-stack semantics operate without workflow hardcoding
- e2e coverage validates persistence + behavior contracts
