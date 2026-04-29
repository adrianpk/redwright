# Operations Ledger

This area stores mutable execution artifacts used to run engineering cycles.

Structure:

- `ops/specs/`: draft and formal specification artifacts
- `ops/templates/`: canonical formats
- `ops/plans/`: approved versioned cycle plans
- `ops/trackers/`: live execution status ledgers
- `ops/artifacts/`: generated inventories, matrices, and audit outputs

Language:

- English only

Reference conventions:

- specs lifecycle is `ops/specs/drafts/*-proto-spec-draft.md` -> `ops/specs/specs/*-proto-spec.md` -> `ops/specs/specs/*-spec.md`
- plan and tracker files are linked bi-directionally in each cycle metadata
