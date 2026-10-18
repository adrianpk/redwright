# Zig Conventions

This document defines coding rules for Zig application code.

## Dependencies

- Prefer Zig standard library and existing project tooling before adding dependencies.
- Ask before introducing packages, generators, services, or build tools.
- Keep dependency additions tied to a concrete module or runtime responsibility.
- Avoid dependencies that replace small, local design decisions.

## Code style

- Keep functions short and explicit.
- Make allocator use visible in function signatures when allocation can occur.
- Prefer clear ownership names and comments at boundaries where ownership is not obvious.
- Use `defer` and `errdefer` to keep cleanup close to acquisition.
- Prefer explicit error handling over hidden panics.
- Keep comptime usage purposeful and local to the problem it solves.

## Module boundaries

- Keep IO adapters separate from core logic.
- Keep parsing, validation, persistence, and rendering in distinct modules when the behavior grows.
- Avoid generic utility modules without a clear owner.
- Keep public APIs small and documented when they cross module boundaries.
- Prefer simple structs and functions before interface-like abstractions.

## Testing

- Use Zig's built-in test runner.
- Prefer deterministic tests for parsing, memory ownership, and boundary behavior.
- Add tests for expected failures and allocator-sensitive paths.
- Use leak-detecting test allocators when allocation behavior matters.
- Do not skip tests for behavior changes.

## Anti-patterns

Avoid:
- hidden allocator ownership
- broad `anytype` APIs without a clear need
- global mutable state
- unchecked assumptions expressed as `unreachable`
- clever comptime code that obscures ordinary behavior
- broad rewrites that do not reduce current complexity

Prefer:
- explicit ownership
- precise errors
- small modules
- deterministic tests
- local consistency over generic architecture
