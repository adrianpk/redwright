# Engineering Conventions

This document defines technical and architectural coding rules for RedWright.

## Dependencies

- Prefer Ruby standard library, Rails built-ins, and existing app tooling before adding dependencies.
- Ask before introducing new gems, packages, services, or build tools.
- Do not add dependencies to avoid small, local design decisions.

## Code style

- Keep methods short and explicit.
- Use comments only for non-obvious logic.
- Prefer deterministic behavior in core flows.
- Name objects after the responsibility they own, not the implementation trick they use.

## Boundaries

- Put Rails behavior in the established app, model, service, controller, or view boundary for that subsystem.
- Keep runtime/library code under `lib/` when it belongs outside the Rails app.
- Keep controllers, `bin/` entrypoints, and scripts thin.
- Separate IO/adapters from decision logic.
- Keep persistence, rendering, orchestration, and external integrations in distinct units.

## Testing

- Behavior changes must include appropriate validation.
- Add or update tests when behavior, contracts, persistence, or workflow boundaries change.
- Favor table-driven style where inputs/outputs are explicit.
- Avoid fragile tests coupled to incidental formatting.
- Match test scope to risk: unit tests for local rules, integration tests for workflow contracts.

## Anti-patterns

Avoid:
- hidden global mutable state
- mixing unrelated concerns in one file or commit
- speculative abstractions without active use
- broad rewrites that do not reduce current complexity

Prefer:
- explicit contracts
- small cohesive units
- incremental safe changes
- local consistency over generic architecture
