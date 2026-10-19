# Angular Conventions

- Keep templates declarative and move complex transformations into component
  logic, computed state, or focused pipes.
- Keep inputs, outputs, dependencies, and change propagation explicit. Preserve
  strict template checking and type forms and external data deliberately.
- Prefer computed values for derived signal state. Use effects for genuine side
  effects rather than copying values between signals.
- Manage subscriptions with the async pipe or the lifecycle utilities supported
  by the installed version. Prevent stale subscriptions after component teardown.
- Use semantic HTML, accessible labels, and predictable focus behavior.
- Treat HTTP payloads as untrusted input. Use framework sanitization and avoid
  bypassing it merely to silence errors.

Reference: [Angular style guide](https://angular.dev/style-guide).
