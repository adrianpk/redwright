# Odin Validation

Use repository-owned commands and its selected compiler version. Replace the
package placeholders below with actual package directories.

```text
odin check <package>
odin test <package>
odin build <entry-package>
```

- Compile the affected package and its relevant entrypoint. Use `-file` only
  when one source file intentionally forms the complete package.
- Write `@(test)` procedures using `core:testing` and a `^testing.T` parameter.
- Exercise invalid inputs and ownership boundaries alongside successful results.
  Use the test runner's memory tracking when allocation or cleanup changes.
- Isolate state shared by parallel tests. Use deterministic inputs or record
  the random seed so a failure can be reproduced.
- Add target or foreign-library checks only when the change affects them.

Reference: [Odin testing package](https://pkg.odin-lang.org/core/testing/).
