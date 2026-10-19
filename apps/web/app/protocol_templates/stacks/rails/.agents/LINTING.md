# Rails Validation

- Check changed Ruby syntax and run affected tests through `bin/rails test`
  or the application's established RSpec command.
- Match tests to the boundary: model tests for invariants, request/integration
  tests for HTTP behavior, job tests for queuing and retries, and system tests
  for interactions that need a browser.
- Verify persistence failures, authorization, and transaction behavior when
  changed. Assert observable behavior rather than private method calls.
- Run `bin/rails zeitwerk:check` when adding or moving autoloaded constants.
- Use the configured style and security checks. Build changed frontend assets
  through repository commands when browser verification depends on them.

Reference: [Rails testing guide](https://guides.rubyonrails.org/testing.html).
