# TypeScript Architecture

This document describes TypeScript repository structure and runtime boundaries.

- Follow the framework or package layout already in use. Keep package exports
  deliberate and avoid barrel files that create cycles or hide expensive imports.
- Separate pure domain transformations from browser, server, storage, and network
  adapters where their dependencies differ.
- Treat compiler types and runtime data as separate contracts: validate external
  payloads before using them as domain values.
- Use discriminated unions for states with different required data rather than
  collections of optional fields.
- Match module resolution and ESM/CommonJS output to the actual runtime and
  package configuration. Keep type-only imports explicit when required.
- Give asynchronous operations clear cancellation, error, and resource lifetimes.

Reference: [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html).
