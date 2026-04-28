# Cycle Plan: Redwright Ingress Port and Simulated End-to-End

## Metadata

- cycle_id: `runtime-cycle-2026-04-28-redwright-ingress-port-and-simulated-e2e`
- status: `draft`
- owner: `adrianpk`
- created: `2026-04-28`
- updated: `2026-04-28`
- goal: `decouple runtime ingress via canonical port and add deterministic simulated e2e coverage`
- scope: `feature`

## Slice List

### Slice 1: Ingress Port and Simulated E2E Harness

- status: `pending`
- branch: `feat/slice-1-ingress-port-and-simulated-e2e`
- objective: `introduce canonical ingress port and validate runtime parity through simulated end-to-end execution`
- tasks:
- [ ] `T1.1 define ingress port interface and canonical event model`
- [ ] `T1.2 adapt telegram ingress into ingress port implementation`
- [ ] `T1.3 add simulated ingress adapter for deterministic in-memory event feeds`
- [ ] `T1.4 add e2e test that validates sqlite + filesystem side effects under /tmp`
- [ ] `T1.5 preserve runtime behavior parity for existing telegram invariant tests`
- acceptance:
- `runtime ingress is transport-agnostic at boundary`
- `simulated e2e runs without network calls`
- `sqlite and filesystem assertions pass in isolated tmp roots`
- planned_commits:
- `feat(ingress): add canonical ingress port and adapters`
- `test(e2e): add simulated ingress end-to-end persistence and filesystem coverage`
- PR:
- `tbd (to be opened from feat/slice-1-ingress-port-and-simulated-e2e)`

## Global Exit Criteria

- ingress abstraction is integrated without telegram regression
- simulated e2e test verifies persistence and filesystem side effects
- tests remain deterministic and repository-safe
