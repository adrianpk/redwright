# Linting and Quality Gates

This repository uses focused quality gates for a Rails prototype under `apps/web`.

## Baseline checks

- Syntax check:
  - `ruby -wc <file>` for changed Ruby files
- Test suite:
  - from `apps/web`: `bundle exec rails test`
  - for focused Rails validation: `bundle exec rails test <test path>`

## Optional stricter checks

If enabled by project setup:
- `rubocop` for style/static checks
- `standardrb` as an alternative style baseline
- `bundle exec brakeman` for Rails security checks
- `bundle exec bundler-audit` for dependency advisories

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- changed-file syntax checks
- targeted tests where possible

Full suite should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.
- For docs-only changes, validate the diff and whitespace instead of running unrelated application tests.

## Root-level gates

- Repository-level quality tasks run from the repository root.
- Coverage command: `bundle exec rake test:coverage`.
- Dev-to-main alignment gate: `bundle exec rake pr:dev_to_main:gate`.
