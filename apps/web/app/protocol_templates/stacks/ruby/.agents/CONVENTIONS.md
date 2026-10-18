# Engineering Conventions

This document defines coding rules for Ruby application code.

## Dependencies

- Prefer Ruby standard library, framework built-ins, and existing app tooling before adding dependencies.
- Ask before introducing new gems, packages, services, or build tools.
- Do not add dependencies to avoid small, local design decisions.

## Code style

- Keep methods short and explicit.
- Use comments only for non-obvious logic.
- Prefer deterministic behavior in core flows.
- Name objects after the responsibility they own, not the implementation trick they use.
- Prefer plain Ruby objects for application workflows that do not need a framework base class.

## Boundaries

- Put framework behavior in the established model, service, controller, job, helper, or view boundary for that subsystem.
- Use service objects or cohesive modules for multi-step workflows.
- Keep controllers, command/query entrypoints, CLIs, and scripts thin.
- Separate IO/adapters from decision logic.
- Keep persistence, rendering, orchestration, and external integrations in distinct units.
- Keep reusable runtime/library code under `lib/` when it genuinely belongs outside the framework app.

## Testing

- Behavior changes must include appropriate validation.
- Add or update tests when behavior, contracts, persistence, or workflow boundaries change.
- Favor table-driven style where inputs/outputs are explicit.
- Avoid fragile tests coupled to incidental formatting.
- Match test scope to risk: unit tests for local rules, integration tests for workflow contracts.
- Use the project's Ruby test suite for application behavior.

## Anti-patterns

Avoid:
- hidden global mutable state
- mixing unrelated concerns in one file or commit
- speculative abstractions without active use
- broad rewrites that do not reduce current complexity
- controller or CLI branches that hide multi-step workflow behavior

Prefer:
- explicit contracts
- small cohesive units
- incremental safe changes
- local consistency over generic architecture
- Ruby and framework conventions before custom framework layers
