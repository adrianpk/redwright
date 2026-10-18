# Rails Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Repository-owned commands
override these examples.

## Baseline Commands

- Syntax: `ruby -wc <file>` for changed Ruby files.
- Focused tests: `bin/rails test <test-path>` when binstubs are available.
- Suite: `bin/rails test`, with `bundle exec rails test` as the portable
  fallback.

## Configured Extensions

- Use RuboCop or Standard, Brakeman, Bundler Audit, system tests, and coverage
  only when the repository configures them or the changed risk requires them.
