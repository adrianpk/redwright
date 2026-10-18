# TypeScript Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Use the selected package manager
and repository-owned scripts instead of assuming a universal command.

## Baseline Commands

- Run the configured type-check command, commonly a `typecheck` script or
  `tsc --noEmit`.
- Run the configured focused tests and test suite.
- Run the configured formatter and lint scripts when present.

## Configured Extensions

- Use ESLint, Prettier or another formatter, dependency audits, coverage, and
  build validation through the repository's configured scripts.
