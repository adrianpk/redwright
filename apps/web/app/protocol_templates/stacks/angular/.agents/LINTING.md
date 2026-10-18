# Angular Linting and Quality Gates

This repository uses focused quality gates for Angular application code.

## Baseline checks

- Type checking and build validation:
  - the project's configured build or typecheck script
  - commonly: `npm run build`, `pnpm build`, or `ng build`
- Test suite:
  - the project's configured test script
- Formatting:
  - the project's configured formatter script when present

## Optional stricter checks

If enabled by project setup:
- Angular ESLint for static analysis.
- Prettier or another configured formatter for style consistency.
- package-manager audit commands for dependency advisories.
- the project's configured coverage command.
- end-to-end tests for user-facing flows when configured.

## Hook policy

If git hooks are configured, pre-commit should run fast checks only:
- formatting checks
- focused tests where practical
- lightweight typecheck or lint checks for changed code

Full typecheck, lint, build, and test gates should run before merge.

## Rules

- Do not skip tests for behavior changes.
- Fix failing checks before declaring work complete.
- For docs-only changes, validate the diff and whitespace instead of running unrelated application tests.
- Keep stricter checks useful; avoid introducing rules that cause mechanical churn without improving maintainability.

## Root-level gates

- Repository-level quality tasks should run from the repository root unless the project documents a different working directory.
- Prefer project-owned commands such as `npm test`, `pnpm test`, `ng test`, `npm run lint`, `pnpm lint`, `make test`, `make lint`, `make verify`, or CI-equivalent scripts when present.
- Report the exact command and outcome when closing work.
