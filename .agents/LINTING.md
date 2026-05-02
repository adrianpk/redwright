# Linting and Quality Gates

This repository uses a minimal quality gate suitable for a Ruby prototype.

## Baseline checks

- Syntax check:
  - `ruby -wc <file>` for changed Ruby files
- Test suite:
  - `ruby -Itest test/**/*_test.rb` or project test command

## Optional stricter checks

If enabled by project setup:
- `rubocop` for style/static checks
- `standardrb` as an alternative style baseline

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- changed-file syntax checks
- targeted tests where possible

Full suite should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.

## Coverage Command Scope

- The coverage task must be run from repository root (`~/Projects/redwright/redwright`).
- Canonical command:
  - `bundle exec rake test:coverage`
