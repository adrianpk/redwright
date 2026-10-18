# Rails Linting and Quality Gates

This repository uses focused quality gates for Rails application code.

## Baseline checks

- Syntax check:
  - `ruby -wc <file>` for changed Ruby files
- Test suite:
  - `bin/rails test` when binstubs are available
  - `bundle exec rails test` as the portable fallback
  - `bundle exec rails test <test path>` for focused Rails validation

## Optional stricter checks

If enabled by project setup:
- `bundle exec rubocop` or `bundle exec standardrb` for style/static checks.
- `bundle exec brakeman` for Rails security checks.
- `bundle exec bundler-audit` for dependency advisories.
- `bundle exec rails test:system` for system tests when configured.
- the project's configured coverage command.

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- changed-file syntax checks
- focused tests where practical
- lightweight lint checks for changed code

Full lint and test gates should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.
- For docs-only changes, validate the diff and whitespace instead of running unrelated application tests.
- Keep linter strictness high enough to catch defects, but avoid rules that encourage mechanical churn without improving maintainability.

## Root-level gates

- Repository-level quality tasks should run from the repository root unless the project documents a different working directory.
- Prefer project-owned commands such as `bin/rails test`, `bundle exec rails test`, `make test`, `make lint`, `make verify`, or CI-equivalent scripts when present.
- Report the exact command and outcome when closing work.
