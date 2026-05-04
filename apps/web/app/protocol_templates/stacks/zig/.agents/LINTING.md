# Zig Linting and Quality Gates

This repository uses focused quality gates for Zig application code.

## Baseline checks

- Formatting:
  - `zig fmt --check .`
- Test suite:
  - `zig build test` when the build graph defines tests
  - `zig test <file>` for focused file-level validation
- Build:
  - `zig build` for project-level build validation

## Optional stricter checks

If enabled by project setup:
- sanitizer or safety-mode builds when the project defines them.
- leak-checking tests with a test allocator.
- target-specific build steps for supported deployment targets.
- the project's configured coverage command.

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- formatting checks
- focused tests where practical
- lightweight build checks for changed code

Full build and test gates should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.
- For docs-only changes, validate the diff and whitespace instead of running unrelated application tests.
- Keep stricter checks useful; avoid introducing rules that cause mechanical churn without improving maintainability.

## Root-level gates

- Repository-level quality tasks should run from the repository root unless the project documents a different working directory.
- Prefer project-owned commands such as `zig build test`, `zig build`, `make test`, `make lint`, `make verify`, or CI-equivalent scripts when present.
- Report the exact command and outcome when closing work.
