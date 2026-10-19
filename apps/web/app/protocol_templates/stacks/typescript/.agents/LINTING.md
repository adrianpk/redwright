# TypeScript Validation

- Use the repository's package manager and typecheck script. Where configured,
  run `tsc --noEmit` or the project's build-mode check with its actual tsconfig.
- Run the existing linter and formatter; respect their TypeScript-aware rules
  for promises, imports, and unsafe values.
- Test runtime behavior with the configured runner, including malformed external
  data, promise rejection, and cancellation when changed.
- Build the package or application when emitted modules, declarations, bundling,
  or runtime entrypoints change. Type checking alone does not prove those work.
- Verify public declarations and consuming imports when changing package exports.

Reference: [TSConfig reference](https://www.typescriptlang.org/tsconfig/).
