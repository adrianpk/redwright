# Ruby Quality-Gate Overlay

Apply this overlay with `.agents/LINTING.md`. Repository-owned commands
override these examples.

## Baseline Commands

- Syntax: `ruby -wc <file>` for changed Ruby files.
- Focused tests: `bundle exec ruby -Itest <test-path>` when the repository uses
  Minitest directly.
- Use the repository's configured suite command for other Ruby test frameworks.

## Configured Extensions

- Use RuboCop or Standard, Bundler Audit, and coverage only when configured or
  relevant to the changed risk.
