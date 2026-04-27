# Repository Architecture

This document describes repository structure and ownership boundaries.

## Objective

Keep the prototype codebase simple, navigable, and easy to promote later.

## Baseline structure

```
bin/           # executable entry points
lib/           # application/runtime code
test/          # automated tests
docs/          # specifications and technical documentation
.agents/       # collaboration and execution rules
```

## Boundary rules

- Business logic belongs in `lib/`.
- Entry points in `bin/` should stay thin.
- Tests mirror behavior in `lib/`.
- Product specification stays in `docs/`.
- Working rules stay in `.agents/` and `AGENTS.md`.

## Change discipline

- Structural changes must be explicit in commit scope.
- Do not introduce additional top-level directories without clear need.
