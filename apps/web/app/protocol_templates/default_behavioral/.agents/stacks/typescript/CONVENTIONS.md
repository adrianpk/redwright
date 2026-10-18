# TypeScript Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

- Preserve meaningful strict typing; do not replace uncertainty with `any`.
- Prefer explicit object shapes and discriminated unions for multi-state
  behavior.
- Handle expected asynchronous failures explicitly.
- Keep runtime parsing and validation close to untrusted boundaries.
- Keep public exports small and intentional.
- Use dependency injection only at boundaries with a real substitution need;
  avoid global mutable singletons.
- Use the repository's configured TypeScript test runner and test asynchronous
  and adapter behavior explicitly.
- Avoid generic `utils` buckets and broad state abstractions without active use.
