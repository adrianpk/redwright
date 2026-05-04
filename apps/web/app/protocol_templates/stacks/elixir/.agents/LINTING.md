# Elixir Linting and Quality Gates

This repository uses focused quality gates for Elixir application code.

## Baseline checks

- Formatting:
  - `mix format --check-formatted`
- Test suite:
  - `mix test`
- Compilation warnings:
  - `mix compile --warnings-as-errors` when supported by the project workflow

## Optional stricter checks

If enabled by project setup:
- `mix credo` for static analysis and style checks.
- `mix dialyzer` for type/spec analysis.
- `mix test --cover` or the project's configured coverage command.
- `mix deps.audit` or another dependency advisory tool when configured.

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- formatting checks
- focused tests where practical
- lightweight static checks for changed code

Full lint, compile, and test gates should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.
- For docs-only changes, validate the diff and whitespace instead of running unrelated application tests.
- Keep stricter checks useful; avoid introducing rules that cause mechanical churn without improving maintainability.

## Root-level gates

- Repository-level quality tasks should run from the repository root unless the project documents a different working directory.
- Prefer project-owned commands such as `mix test`, `mix format --check-formatted`, `make test`, `make lint`, `make verify`, or CI-equivalent scripts when present.
- Report the exact command and outcome when closing work.
