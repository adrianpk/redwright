# Rust Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

```text
src/main.rs  # binary entrypoint when present
src/lib.rs   # library root when present
tests/       # public integration tests
examples/    # runnable examples
benches/     # configured benchmarks
```

- Keep binary entrypoints thin and delegate behavior to library modules.
- Use traits at boundaries with a real substitution need.
- Keep ownership and lifetime decisions visible in public APIs.
- Keep feature flags explicit when they affect public behavior.
- Use `Result` for expected failures and preserve useful error context.
- Avoid panics in library behavior unless they defend a local invariant.
- Keep unsafe code behind a documented invariant and narrow boundary.
- Do not split a workspace or add a broad trait hierarchy without a concrete
  ownership need.
