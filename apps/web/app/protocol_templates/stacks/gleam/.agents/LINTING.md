# Gleam Validation

- Run `gleam format --check src test` for the existing source and test directories,
  then `gleam check` and affected tests through the configured test command.
- Use `gleam test` with the project's chosen test package, commonly Gleeunit.
- Exercise every meaningful custom type and expected `Result` failure branch.
  Keep deterministic transformations testable without runtime processes.
- Verify foreign-function declarations against their actual target implementation.
- When a package supports both Erlang and JavaScript, run the relevant build and
  test commands for both targets. Do not claim portability from one target alone.

Reference: [Writing Gleam](https://gleam.run/writing-gleam/).
