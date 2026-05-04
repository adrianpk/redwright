# Engineering Conventions

This document defines RedWright coding rules for the Rails application and supporting Ruby code.

## Dependencies

- Prefer Ruby standard library, Rails built-ins, and existing app tooling before adding dependencies.
- Ask before introducing new gems, packages, services, or build tools.
- Do not add dependencies to avoid small, local design decisions.

## Code style

- Keep methods short and explicit.
- Use comments only for non-obvious logic.
- Prefer deterministic behavior in core flows.
- Name objects after the responsibility they own, not the implementation trick they use.
- Prefer plain Ruby objects for application workflows that do not need a Rails base class.

## Boundaries

- Put Rails behavior in the established model, service, controller, job, helper, or view boundary for that subsystem.
- Use service modules for sagas, setup flows, materializers, protocol composition, runtime container generation, and command/query handlers.
- Keep controllers, command/query entrypoints, and scripts thin.
- Separate IO/adapters from decision logic.
- Keep persistence, rendering, orchestration, and external integrations in distinct units.
- Keep reusable runtime/library code under `lib/` only when it genuinely belongs outside the Rails app.

## Testing

- Behavior changes must include appropriate validation.
- Add or update tests when behavior, contracts, persistence, or workflow boundaries change.
- Favor table-driven style where inputs/outputs are explicit.
- Avoid fragile tests coupled to incidental formatting.
- Match test scope to risk: unit tests for local rules, integration tests for workflow contracts.
- Use Rails tests from `apps/web/test/` for application behavior.

## Anti-patterns

Avoid:
- hidden global mutable state
- mixing unrelated concerns in one file or commit
- speculative abstractions without active use
- broad rewrites that do not reduce current complexity
- controller branches that hide multi-step workflow behavior

Prefer:
- explicit contracts
- small cohesive units
- incremental safe changes
- local consistency over generic architecture
- Rails conventions before custom framework layers
