# TypeScript Conventions

This document defines coding rules for TypeScript application code.

## Dependencies

- Prefer TypeScript, the runtime standard APIs, and existing project tooling before adding dependencies.
- Ask before introducing packages, services, generators, state libraries, or build tools.
- Keep dependency additions tied to a concrete module or runtime responsibility.
- Avoid dependencies that replace small, local design decisions.

## Code style

- Keep functions short and explicit.
- Keep strict typing meaningful; do not replace uncertainty with `any`.
- Use `unknown` at untrusted boundaries and narrow before use.
- Prefer explicit object shapes and discriminated unions for multi-state behavior.
- Keep async behavior explicit and handle expected failures deliberately.
- Prefer named intermediate values when they clarify complex transformations.

## Module boundaries

- Keep IO adapters separate from core logic.
- Keep parsing, validation, persistence, rendering, and transport in distinct modules when the behavior grows.
- Avoid generic utility modules without a clear owner.
- Keep public exports small and intentional.
- Use dependency injection at boundaries where substitution is useful; avoid global mutable singletons.

## Testing

- Use the project's configured TypeScript test runner.
- Prefer focused tests for module behavior and integration tests for cross-boundary behavior.
- Cover expected failures, async behavior, parsing edge cases, and external adapter boundaries.
- Avoid tests coupled to incidental formatting unless formatting is the behavior.
- Do not skip tests for behavior changes.

## Anti-patterns

Avoid:
- `any` as a shortcut around unclear contracts
- hidden global mutable state
- generic `utils` buckets that mix unrelated concerns
- broad state or framework abstractions without active need
- unvalidated external data treated as trusted
- broad rewrites that do not reduce current complexity

Prefer:
- explicit types
- narrow adapters
- small cohesive modules
- deterministic tests
- local consistency over generic architecture
