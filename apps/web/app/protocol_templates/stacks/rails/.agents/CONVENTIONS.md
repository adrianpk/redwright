# Rails Conventions

This document defines coding rules for Rails application code.

## Dependencies

- Prefer Ruby standard library, Rails built-ins, and existing app tooling before adding dependencies.
- Ask before introducing new gems, packages, services, generators, or build tools.
- Do not add dependencies to avoid small, local design decisions.
- Keep gem additions tied to a clear application responsibility.

## Code style

- Keep methods short and explicit.
- Use comments only for non-obvious logic.
- Prefer deterministic behavior in core flows.
- Name objects after the responsibility they own, not the implementation trick they use.
- Prefer plain Ruby objects for application workflows that do not need a Rails base class.

## Controllers

- Keep controller actions focused on request handling.
- Use strong parameters explicitly.
- Keep branching minimal; move workflow decisions into models, services, policies, or form objects when needed.
- Avoid embedding persistence orchestration directly in controller actions.

## Models

- Keep validations, associations, scopes, and persistence invariants close to the model they protect.
- Keep scopes composable and named after domain intent.
- Avoid callbacks for multi-step workflows or external side effects.
- Prefer explicit service calls when behavior crosses multiple models or external systems.

## Services and jobs

- Use service objects for multi-step workflows, materializers, imports, integrations, and cross-model orchestration.
- Keep service inputs explicit and validate required collaborators early.
- Use jobs for asynchronous, retryable, or scheduled work.
- Keep jobs thin when the business behavior belongs in a service object.

## Testing

- Use Rails tests from `test/` for application behavior.
- Add or update tests when behavior, contracts, persistence, or workflow boundaries change.
- Prefer focused model, service, controller, job, and integration tests over broad incidental coverage.
- Avoid fragile tests coupled to incidental HTML, ordering, or formatting unless that output is the behavior.

## Anti-patterns

Avoid:
- fat controllers
- models that become generic orchestration containers
- callbacks that hide cross-system workflows
- hidden global mutable state
- speculative abstractions without active use
- broad rewrites that do not reduce current complexity

Prefer:
- Rails conventions
- explicit contracts
- small cohesive objects
- incremental safe changes
- local consistency over generic architecture
