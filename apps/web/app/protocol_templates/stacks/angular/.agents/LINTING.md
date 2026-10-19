# Angular Validation

- Use the repository's package manager and configured build, lint, and test
  scripts. A production build should check templates as well as TypeScript.
- Test components through rendered behavior and user interactions, services
  through their public API, and router behavior at the routing boundary.
- Control HTTP requests and async scheduling with the project's testing tools;
  do not rely on arbitrary waits.
- Verify teardown when changing subscriptions or component-scoped resources.
- Use browser tests for focus, navigation, accessibility, or layout changes that
  a component unit test cannot establish. Keep the existing test runner.

Reference: [Angular testing](https://angular.dev/guide/testing).
