# Repository Architecture

- Describe the repository's actual entrypoints, modules, and dependency direction.
  Follow the selected language and framework's established layout.
- Keep public APIs small and make ownership of state and resources explicit.
- Isolate external services, storage, and transport where their failure or
  lifecycle needs a distinct boundary.
- Start with the existing structure. Add packages, layers, or services when
  concrete responsibilities justify them.
- Document deployment units and durable data boundaries when they exist.
- Keep working instructions in `AGENTS.md` and `.agents/`; keep product
  documentation with the project documentation.
