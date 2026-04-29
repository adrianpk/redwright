# Cycle Plan: RedWright Persistence Audit and Canonical State

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `audit persistent state usage, remove zombies, and define canonical runtime persistence ownership`
- tracker: `ops/trackers/2026-04-29-redwright-persistence-audit-and-canonical-state-cycle-tracker.md`

## Slice List

### Slice 1: Persistence Inventory Snapshot

- status: `pending`
- branch: `feat/slice-1-persistence-inventory-snapshot`
- [ ] `T1.1 list all sqlite tables/indexes/foreign keys from current bootstrap schema`
- [ ] `T1.2 map every table to read/write callsites in lib/ and test/`
- [ ] `T1.3 classify entities by domain: runtime, context, alignment, feedback, skills, ops`
- [ ] `T1.4 produce machine-readable inventory artifact under ops/`

### Slice 2: Zombie Detection Matrix

- status: `pending`
- branch: `feat/slice-2-persistence-zombie-detection-matrix`
- [ ] `T2.1 detect tables/columns never read by runtime paths`
- [ ] `T2.2 detect write-only flows with no runtime consumer`
- [ ] `T2.3 detect read paths with no writer in active runtime`
- [ ] `T2.4 tag each candidate as remove|migrate|reserve with rationale`

### Slice 3: Canonical State Ownership Contract

- status: `pending`
- branch: `feat/slice-3-canonical-state-ownership-contract`
- [ ] `T3.1 define ownership matrix: component -> table -> operations`
- [ ] `T3.2 define lifecycle states and retention policy per entity`
- [ ] `T3.3 define id contracts (project/workstream/task/session/trace)`
- [ ] `T3.4 define idempotency and deduplication boundaries`

### Slice 4: Runtime Guardrails for Persistence Integrity

- status: `pending`
- branch: `feat/slice-4-persistence-integrity-guardrails`
- [ ] `T4.1 add runtime checks for unresolved references on write paths`
- [ ] `T4.2 add startup hygiene pass for stale/invalid links`
- [ ] `T4.3 add deterministic error classes for persistence contract violations`
- [ ] `T4.4 add tests covering guardrail failures and recoveries`

### Slice 5: Zombie Removal and Migration Pack

- status: `pending`
- branch: `feat/slice-5-zombie-removal-and-migrations`
- [ ] `T5.1 remove approved zombie entities or mark reserved ones explicitly`
- [ ] `T5.2 add migration scripts for renames/splits/normalizations`
- [ ] `T5.3 validate bootstrap compatibility on clean and existing dev db`
- [ ] `T5.4 add rollback-safe migration tests`

### Slice 6: Persistence Reference Documentation

- status: `pending`
- branch: `feat/slice-6-persistence-reference-docs`
- [ ] `T6.1 add docs/reference/persistence-model.md`
- [ ] `T6.2 document table purpose, owner, lifecycle, and invariants`
- [ ] `T6.3 document startup hygiene and migration guarantees`
- [ ] `T6.4 link docs to cycle tracker artifacts`

## Exit Criteria

- Persistent entities are fully mapped to active runtime ownership.
- Zombie entities are removed or explicitly reserved with reason.
- Runtime enforces persistence integrity through explicit guards.
- Persistence reference docs match implemented behavior.
