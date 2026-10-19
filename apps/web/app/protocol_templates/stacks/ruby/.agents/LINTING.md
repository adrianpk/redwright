# Ruby Validation

- Check changed files with `ruby -wc <file>` using the project's Ruby version.
- Run affected tests with the existing runner: for example,
  `bundle exec ruby -Itest test/example_test.rb` or `bundle exec rspec <path>`.
- Test public object behavior, expected exceptions, and observable side effects.
  Use temporary resources for filesystem behavior and release them after tests.
- Run RuboCop, Standard, or another formatter only when already configured;
  follow the repository's version and rules rather than adding a second policy.
- For library changes, verify requiring the entrypoint and the supported Ruby
  versions where the affected syntax or API differs.

Reference: [Ruby command line](https://docs.ruby-lang.org/en/master/ruby/options_md.html).
