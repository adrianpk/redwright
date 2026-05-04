# Repository Architecture

This document describes Ruby repository structure and ownership boundaries.

## Objective

Keep the Ruby codebase simple, navigable, and easy to promote without hiding workflow behavior in oversized objects.

## Baseline structure

```
app/           # application code when the project uses a framework
lib/           # reusable Ruby code and framework-independent behavior
bin/           # executable entrypoints and local scripts
test/          # automated tests
docs/          # user-facing and technical documentation
.agents/       # collaboration and execution rules for this repository
AGENTS.md      # top-level agent operating contract
```

## Boundary rules

- Framework entrypoints should stay thin and delegate workflows to models, services, jobs, or plain Ruby objects.
- Multi-step workflows belong in focused service objects or cohesive modules.
- Persistence-backed models should own persistence invariants and associations; they should not become generic orchestration objects.
- Views or presenters should render state and local interaction affordances, not business workflows.
- Tests should mirror the behavior boundary being changed.
- Product and user documentation stays in `docs/`.
- Working rules stay in `.agents/` and `AGENTS.md`.

## Change discipline

- Structural changes must be explicit in commit scope.
- Do not introduce additional top-level directories or framework layers without clear need.
- Prefer extending the existing Ruby or framework structure before creating new architectural categories.
