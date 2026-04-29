# Zombie Removal and Migration Pack

## Scope

This pack closes the remove-or-reserve decision for current persistence zombie candidates and records migration behavior.

## Decision Matrix

- `alignment_question_dependencies`
  - decision: `reserve`
  - reason: canonical PSAM dependency graph contract; low-frequency runtime reads are accepted.
  - migration action: `none (explicit reserve marker migration)`

- `alignment_artifact_links`
  - decision: `reserve`
  - reason: canonical PSAM artifact linkage contract for context recovery and traceability.
  - migration action: `none (explicit reserve marker migration)`

## Migration Behavior

- Added explicit schema migrator pass at bootstrap:
  - idempotent marker migration id: `2026_04_29_reserve_psam_dependency_and_artifact_tables`
  - marker key: `migration.2026_04_29_reserve_psam_dependency_and_artifact_tables`
  - detail key: `migration_detail.2026_04_29_reserve_psam_dependency_and_artifact_tables`

## Safety Properties

- migration execution is transactional per migration
- failed migration rolls back and does not write `applied` marker
- repeated bootstrap runs do not duplicate markers

## Validation

- `bundle exec ruby -Itest test/redwright/schema_migrator_test.rb`
- `bundle exec ruby -Itest test/redwright/bootstrap_test.rb`
