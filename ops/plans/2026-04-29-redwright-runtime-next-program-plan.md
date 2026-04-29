# Program Plan: RedWright Runtime Next Program

## Metadata

- owner: `adrianpk`
- status: `completed`
- scope: `runtime`
- objective: `stabilize runtime control semantics, normalize persistent state, and make per-project context rehydratable through a canonical project manifest`
- tracker: `ops/trackers/2026-04-29-redwright-runtime-next-program-tracker.md`

## Program Order

1. `Cycle A`: persistence audit and canonical state contract
2. `Cycle B`: operational command model (slash + natural language parity)
3. `Cycle C`: project manifest lifecycle, rehydration, and documentation rollout

## Cycle References

- `ops/plans/2026-04-29-redwright-persistence-audit-and-canonical-state-cycle-plan.md`
- `ops/plans/2026-04-29-redwright-operational-command-model-cycle-plan.md`
- `ops/plans/2026-04-29-redwright-project-manifest-rehydration-and-docs-cycle-plan.md`

## Program Invariants

- No stack-specific hardcoded runtime branches for required clarifications.
- Operational commands remain deterministic at runtime boundaries.
- Natural-language routing stays available and semantically aligned with slash commands.
- State/docs changes must reflect actual runtime behavior (no speculative contracts).
- Each cycle executes with one slice branch and one PR per slice.

## Program Exit Criteria

- Persistent store is audited, zombie entities are explicitly removed or justified.
- Command model is deterministic for operational actions and robust under natural phrasing.
- `.redwright/manifest.yml` is canonical, versioned, and used for project-level rehydration.
- Diataxis docs cover runtime reference/how-to/explanation without filler.
