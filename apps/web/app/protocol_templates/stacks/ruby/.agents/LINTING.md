# Linting and Quality Gates

This repository uses focused quality gates for Ruby application code.

## Baseline checks

- Syntax check:
  - `ruby -wc <file>` for changed Ruby files
- Test suite:
  - `bundle exec ruby -Itest <test path>` for focused Ruby tests
  - project-specific test command when the repository defines one
  - for Rails projects: `bundle exec rails test`

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

- Repository-level quality tasks should run from the repository root unless the project documents a different working directory.
- Use the project's coverage command when one is configured.
- Use the project's release-alignment gate when one is configured.
