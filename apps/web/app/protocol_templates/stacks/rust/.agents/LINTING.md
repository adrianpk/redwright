# Rust Linting and Quality Gates

This repository uses focused quality gates for Rust application code.

## Baseline checks

- Formatting:
  - `cargo fmt --check`
- Test suite:
  - `cargo test`
- Compilation and static checks:
  - `cargo check`

## Optional stricter checks

If enabled by project setup:
- `cargo clippy -- -D warnings` for lint checks.
- `cargo test --all-features` for feature coverage.
- `cargo test --workspace` for workspace projects.
- `cargo audit` for dependency advisories.
- `cargo tarpaulin` or the project's configured coverage command.

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- formatting checks
- focused tests where practical
- lightweight `cargo check` or clippy checks for changed code

Full lint and test gates should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.
- For docs-only changes, validate the diff and whitespace instead of running unrelated application tests.
- Keep stricter checks useful; avoid introducing rules that cause mechanical churn without improving maintainability.

## Root-level gates

- Repository-level quality tasks should run from the repository root unless the project documents a different working directory.
- Prefer project-owned commands such as `cargo test`, `cargo clippy`, `make test`, `make lint`, `make verify`, or CI-equivalent scripts when present.
- Report the exact command and outcome when closing work.
