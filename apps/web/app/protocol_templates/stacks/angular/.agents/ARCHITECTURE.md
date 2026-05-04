# Angular Architecture

This document describes Angular repository structure and ownership boundaries.

## Objective

Keep the Angular application feature-oriented, typed, and explicit about UI, routing, state, and data-access boundaries.

## Baseline structure

```text
src/app/          # Angular application source
src/app/features/ # feature areas when the project uses feature folders
src/app/shared/   # shared UI, pipes, directives, and small reusable helpers
src/app/core/     # app-wide providers, guards, interceptors, and singleton services
src/assets/       # static browser assets
src/environments/ # environment configuration when used
docs/             # user-facing and technical documentation
angular.json      # Angular workspace configuration
package.json      # package scripts, dependencies, and metadata
tsconfig*.json    # TypeScript compiler configuration
.agents/          # collaboration and execution rules for this repository
AGENTS.md         # top-level agent operating contract
```

## Boundary rules

- Organize application code around features when it improves navigation.
- Keep components focused on presentation, user interaction, and local view state.
- Put reusable orchestration, data access, and integration behavior behind injectable services.
- Keep routing, guards, interceptors, and app-wide providers explicit.
- Keep domain transformations independent from templates and browser APIs when practical.
- Use typed contracts for API responses, forms, route params, and state.
- Keep runtime validation close to untrusted input boundaries.
- Tests should mirror the component, service, route, or feature boundary being changed.

## UI and state

- Keep templates readable and avoid embedding complex decision logic in markup.
- Use reactive forms or typed forms where the project supports them.
- Use signals, RxJS, or a state library according to the project's existing Angular version and conventions.
- Do not add a state library unless project complexity and existing patterns justify it.
- Keep component inputs and outputs explicit.

## Change discipline

- Structural changes must be explicit in commit scope.
- Prefer extending Angular's established workspace and feature structure before creating custom framework layers.
- Keep shared modules, shared components, and shared services narrow enough to avoid becoming dumping grounds.
