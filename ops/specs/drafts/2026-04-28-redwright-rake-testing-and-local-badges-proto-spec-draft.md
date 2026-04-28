# Redwright Rake Testing + Local Badges Proto-Spec Draft

## Status

- type: `proto-spec-draft`
- date: `2026-04-28`
- source: `format reference docs + request to mirror Warden local make-pattern in Ruby/Rake`

## 1. Scope

This draft defines how to replicate, in this Ruby repository, the same local workflow pattern used in `~/Projects/Warden` for:
- task-based local testing orchestration (Make equivalent -> `Rake`)
- README badge generation from local execution evidence
- no CI/CD dependency for badge status generation

This is a specification draft only. No implementation is included.

## 2. Objective

Provide deterministic local developer commands so one operator can:
1. run quality checks through stable `rake` targets
2. generate machine-readable local result artifacts
3. render README badges from those local artifacts
4. keep badge outputs reproducible without remote pipelines

## 3. Rake Contract (Make-Pattern Equivalent)

Define an explicit task surface (names illustrative but stable once approved):
- `rake quality:lint`
- `rake quality:test`
- `rake quality:all`
- `rake badges:build`
- `rake badges:refresh` (runs checks + rebuilds badges)

Rules:
- each task must have deterministic exit code semantics
- `quality:all` must fail if any quality sub-step fails
- `badges:*` tasks must not hide failures from quality tasks
- tasks must run locally without network dependency

## 4. Local Evidence Artifacts

Local execution must persist badge-source artifacts under a deterministic path, for example:
- `tmp/quality/lint-status.json`
- `tmp/quality/test-status.json`
- `tmp/quality/summary.json`

Artifact minimum fields:
- `name`
- `status` (`pass|fail|warn`)
- `timestamp`
- `command`
- `exit_code`
- `duration_ms`

Purpose:
- provide an auditable source for badge rendering
- decouple badge generation from direct command execution

## 5. README Badge Contract (Local-Only)

README badges must be generated from local artifacts, not from CI endpoints.

Expected behavior:
- badge markdown is written in a dedicated README section
- rendering source is local status data
- color/state mapping is deterministic (`pass=green`, `fail=red`, `warn=yellow`)

Badge update paths (to decide during implementation):
- static local SVG files committed in repo
- or deterministic markdown generated against local badge assets

Non-goal:
- no GitHub Actions / external CI badge URLs

## 6. CLI and Developer Experience

Minimal local workflow:
1. `rake quality:all`
2. `rake badges:build`
3. optional one-shot: `rake badges:refresh`

Operational requirements:
- human-readable console summary
- machine-readable artifact output
- clear failure reason when badges cannot be produced

## 7. Repository Boundaries

All outputs must stay inside repository-safe paths.

Expected write locations:
- `tmp/quality/*` for ephemeral artifacts
- `README.md` badge section update
- optional `assets/badges/*` when static SVG strategy is selected

No writes outside repo root are allowed.

## 8. Acceptance Gate (Slice-Level)

This slice is complete only when all are true:
- `rake` quality tasks run and return correct exit status
- local artifacts are produced with expected schema
- README badges can be regenerated from local artifacts only
- no CI/CD endpoint is required for badge freshness
- rerunning tasks updates badge state deterministically

## 9. Open Items

- exact task naming parity required with `~/Projects/Warden`
- badge rendering strategy (`SVG assets` vs `markdown-only`)
- whether badge artifacts are committed or regenerated on demand
- policy for stale artifacts (cleanup/retention)
