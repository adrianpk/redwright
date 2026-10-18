# Rails Conventions Overlay

Apply this overlay with `.agents/CONVENTIONS.md`.

- Prefer Rails conventions, built-ins, and plain Ruby objects before custom
  framework layers.
- Use strong parameters explicitly.
- Keep scopes composable and named after domain intent.
- Move multi-step controller decisions into models, services, policies, or form
  objects as appropriate.
- Keep service inputs explicit and validate required collaborators early.
- Keep jobs thin when a service owns the business behavior.
- Use focused model, service, controller, job, and integration tests.
- Avoid tests coupled to incidental HTML or ordering unless that output is the
  behavior.
