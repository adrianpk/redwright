# Engineering Conventions

This document defines technical and architectural coding rules.

## Dependencies

- Prefer Ruby standard library.
- Ask before introducing external gems.

## Code style

- Keep methods short and explicit.
- Use comments only for non-obvious logic.
- Prefer deterministic behavior in core flows.

## Boundaries

- Keep domain logic under `lib/`.
- Keep bootstrap/CLI logic minimal in `bin/`.
- Separate IO/adapters from decision logic.

## Testing

- Every behavior change must include tests.
- Favor table-driven style where inputs/outputs are explicit.
- Avoid fragile tests coupled to incidental formatting.

## Anti-patterns

Avoid:
- hidden global mutable state
- mixing unrelated concerns in one file or commit
- speculative abstractions without active use

Prefer:
- explicit contracts
- small cohesive units
- incremental safe changes
