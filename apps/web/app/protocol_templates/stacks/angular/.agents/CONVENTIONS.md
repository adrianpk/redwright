# Angular Conventions

This document defines coding rules for Angular application code.

## Dependencies

- Prefer Angular, TypeScript, RxJS, browser APIs, and existing project tooling before adding dependencies.
- Ask before introducing packages, services, generators, state libraries, component libraries, or build tools.
- Keep dependency additions tied to a concrete feature or application responsibility.
- Avoid dependencies that replace small, local design decisions.

## Code style

- Keep components, services, guards, and interceptors small and explicit.
- Keep strict typing meaningful; do not replace uncertainty with `any`.
- Use `unknown` at untrusted boundaries and narrow before use.
- Prefer explicit object shapes and discriminated unions for multi-state behavior.
- Keep async behavior explicit and handle expected failures deliberately.
- Prefer named intermediate values when they clarify complex transformations.

## Components and templates

- Keep components focused on UI behavior and local interaction state.
- Keep templates readable; move complex transformations into component code, pipes, or services.
- Keep inputs, outputs, and required dependencies explicit.
- Avoid broad shared components that mix unrelated product behavior.
- Keep accessibility and responsive behavior part of the component contract when user-facing.

## Services and data access

- Use injectable services for reusable data access, orchestration, and integration behavior.
- Keep HTTP and external adapter concerns separate from domain transformations.
- Keep route guards and interceptors narrow and predictable.
- Avoid hidden global mutable state.

## Testing

- Use the project's configured Angular test runner.
- Prefer focused component, service, guard, interceptor, and integration tests.
- Cover expected failures, async behavior, form validation, route behavior, and external adapter boundaries.
- Avoid tests coupled to incidental HTML unless that output is the behavior.
- Do not skip tests for behavior changes.

## Anti-patterns

Avoid:
- large components that own feature workflows end to end
- complex template expressions
- `any` as a shortcut around unclear contracts
- broad shared modules or service buckets
- state libraries introduced before they are needed
- unvalidated external data treated as trusted

Prefer:
- typed component contracts
- narrow services
- explicit routing and state boundaries
- deterministic tests
- local consistency over generic architecture
