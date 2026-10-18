# TypeScript Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

- Keep domain behavior independent from rendering, transport, persistence, and
  process wiring.
- Keep asynchronous boundaries and side effects visible behind narrow adapters.
- Use typed contracts for external responses, configuration, persisted data,
  and cross-module messages.
- Validate untrusted input at runtime; static types do not establish a runtime
  boundary.
- Keep DTOs, domain types, and persistence shapes distinct when their
  responsibilities differ.
- Use `unknown` at untrusted boundaries and narrow it deliberately.
- Keep public package entrypoints and exported types intentional.
- Do not introduce broad state or framework layers without a concrete product
  need.
