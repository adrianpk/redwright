# TypeScript Conventions

- Preserve strict checking. Use `unknown` at untrusted boundaries and narrow it
  with checks; do not replace missing understanding with `any` or type assertions.
- Prefer inference for obvious local values and explicit types at public boundaries.
- Use discriminant checks and exhaustive switches for variant behavior. Keep
  `null`, `undefined`, and absent properties deliberate.
- Use `satisfies` when validating a shape without unnecessarily widening the value.
- Handle rejected promises and preserve error context. Avoid fire-and-forget work
  without an owner and a failure path.
- Keep mutation visible; use `readonly` where callers should not modify values.
  Remember that readonly types alone do not freeze runtime objects.

Reference: [Everyday types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html).
