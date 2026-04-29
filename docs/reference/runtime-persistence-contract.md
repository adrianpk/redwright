# Runtime Persistence Contract

## Storage Layers

RedWright runtime persistence uses two layers:

- Project-local manifest: `<project_root>/.redwright/manifest.yml`
- Runtime SQLite database: `<state_dir>/runtime.db`

## SQLite Role

SQLite is the active runtime state store for:

- projects and aliases,
- workstreams and tasks,
- action executions,
- chat/session context,
- alignment/clarification lifecycle metadata.

## Manifest Role

Manifest is project-local canonical metadata for identity/provenance and startup rehydration support.

## Startup Rehydration Precedence

On bootstrap:

1. Ensure schema and hygiene routines run.
2. If project registry in SQLite is non-empty: keep SQLite state as source of truth.
3. If project registry is empty:
   - scan workspace project directories,
   - attempt manifest-driven registration,
   - fallback to path/name registration when manifest is missing/invalid.

This gives precedence `manifest -> sqlite fallback` only when rebuilding from empty runtime project state.

## Contract Invariants

- No destructive overwrite of existing manifest during `new` or `clone` flows.
- Project registration is idempotent by absolute path.
- Alias registration converges to latest canonical project binding.
- Foreign-key integrity is enforced in SQLite (`PRAGMA foreign_keys=ON`).

## Failure/Recovery Semantics

- Invalid manifest never blocks bootstrap.
- Invalid manifest degrades to fallback registration (`local_new` source metadata).
- Missing manifest degrades to fallback registration.
- Database reset in dev mode can reconstruct runtime project registry from workspace + manifests.

## Operational Notes

- Runtime DB path depends on mode (`dev` workspace vs real mode paths).
- In dev mode, workspace project root is fixed under `_workspace/Projects`.
