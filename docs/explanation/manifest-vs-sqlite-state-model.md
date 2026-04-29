# Manifest vs SQLite State Model

RedWright persists runtime state in two complementary layers:

- project-local manifest (`.redwright/manifest.yml`),
- runtime SQLite (`runtime.db`).

They solve different problems and are intentionally not interchangeable.

## Why Two Layers

A coding runtime needs both:

- local, project-bound metadata that travels with project directories,
- process/runtime state optimized for active orchestration and session continuity.

Using only one layer either loses portability (SQLite-only) or loses runtime execution structure (manifest-only).

## Manifest Responsibilities

Manifest is a project-local contract for identity/provenance and bootstrap hints.

It is best for:

- stable project metadata (`name`, `slug`, `stack`, `created_via`),
- source provenance for cloned repositories,
- rehydration seed data after runtime DB reset in dev mode.

It is not used for task/workstream lifecycle storage.

## SQLite Responsibilities

SQLite is the active runtime execution model.

It stores:

- projects/aliases as runtime registry,
- workstreams, tasks, action executions,
- chat/session context,
- alignment/clarification progression.

This is the mutable graph that evolves every turn.

## Precedence Semantics

At startup:

1. Runtime schema and hygiene routines run first.
2. If SQLite project registry is non-empty, SQLite remains authoritative.
3. If SQLite project registry is empty, runtime scans workspace projects and uses:
   - valid manifest -> manifest-driven registration,
   - missing/invalid manifest -> fallback path-based registration.

This means manifest precedence is only used for empty-registry reconstruction.

## Determinism Boundary

Manifest+SQLite separation narrows non-determinism:

- file-level identity/provenance is deterministic from manifest/path,
- runtime orchestration state is deterministic from SQLite transitions,
- LLM variability stays in decision generation, not persistence contract shape.

## Practical Outcome

- deleting dev runtime DB does not destroy project discoverability,
- invalid manifests do not block runtime bootstrap,
- manifest writes are idempotent and non-destructive,
- session/task behavior remains runtime-driven in SQLite.
