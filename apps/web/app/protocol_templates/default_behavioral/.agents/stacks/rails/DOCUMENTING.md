# Rails Documentation Overlay

Apply this overlay with `.agents/DOCUMENTING.md` and `.agents/LANGUAGE.md`.

- Keep commands aligned with actual binstubs and entrypoints, such as
  `bin/rails` or the repository's documented Bundler invocation.
- Use Rails names for models, controllers, routes, jobs, services, fields, and
  response contracts.
- Document routes, request and response contracts, persistence schemas,
  background jobs, and public service contracts when they are caller-visible.
- Keep generated API comments compatible with the repository's selected Ruby
  documentation tool.
