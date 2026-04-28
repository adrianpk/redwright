# Redwright Rake Testing and Local Badges Specification

## Status

- type: `spec`
- date: `2026-04-28`
- derived_from: `ops/specs/drafts/2026-04-28-redwright-rake-testing-and-local-badges-proto-spec-draft.md`
- scope: `local developer workflow`

## 1. Goal

Define a deterministic local quality workflow using `rake` tasks, local quality artifacts, and README badge rendering without any CI/CD dependency.

## 2. Mandatory Task Surface

The repository MUST expose these tasks:

- `rake quality:lint`
- `rake quality:test`
- `rake quality:all`
- `rake badges:build`
- `rake badges:refresh`

Contract:

- all tasks MUST return deterministic non-zero exit codes on failure
- `quality:all` MUST fail if any quality task fails
- `badges:refresh` MUST run quality checks first, then badge rendering
- badge tasks MUST NOT swallow upstream failures

## 3. Local Artifact Contract

Quality tasks MUST write local machine-readable artifacts under `tmp/quality/`.

Required files:

- `tmp/quality/lint-status.json`
- `tmp/quality/test-status.json`
- `tmp/quality/summary.json`

Required schema fields:

- `name`
- `status` (`pass|fail|warn`)
- `timestamp`
- `command`
- `exit_code`
- `duration_ms`

`summary.json` MUST include both lint and test outcomes and an overall status.

## 4. Badge Rendering Contract

README badges MUST be rendered from local artifacts only.

Rules:

- no remote CI badge URL dependency
- deterministic state mapping:
  - `pass => green`
  - `fail => red`
  - `warn => yellow`
- badge content MUST be updated in a dedicated README section

Accepted rendering strategy for this cycle:

- markdown-only badge section generation (no SVG generation in this slice)

## 5. Repository Write Boundaries

Allowed writes:

- `tmp/quality/*`
- `README.md` badge section

Disallowed writes:

- any filesystem path outside repository root

## 6. Runtime and Dependency Constraints

- tasks MUST run locally in the existing Ruby environment
- no network requirement for quality or badge generation
- tasks MUST remain compatible with current `bundle exec rake` workflow

## 7. Acceptance Criteria

This spec is satisfied when all are true:

- all required `rake` tasks exist and execute
- task exit semantics are deterministic and fail-fast where required
- local artifacts are produced with required schema
- README badge section regenerates from local artifacts only
- reruns update artifacts and README deterministically

## 8. Non-Goals

- CI pipeline integration
- external badge services
- production deployment changes
