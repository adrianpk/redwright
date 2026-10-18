# Ruby Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

```text
lib/   # reusable Ruby and framework-independent behavior
bin/   # executable entrypoints and local scripts
test/  # automated tests when the repository uses this layout
```

- Keep executable and framework entrypoints thin.
- Use focused objects or cohesive modules for multi-step workflows.
- Keep reusable runtime or library code under `lib/` when it belongs outside a
  framework application.
- Align tests with the behavior boundary they validate.
