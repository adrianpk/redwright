# Rails Architecture Overlay

Apply this overlay with `.agents/ARCHITECTURE.md` and
`.agents/ENGINEERING_DISCIPLINE.md`.

## Rails Boundaries

- Keep controllers focused on request handling, authorization, delegation, and
  response coordination.
- Keep persistence-backed invariants, associations, validations, and simple
  domain behavior in Active Record models.
- Use service objects for multi-step workflows, materializers, imports,
  external integrations, and orchestration across model boundaries.
- Use jobs for asynchronous, retryable, or scheduled execution.
- Keep views and helpers focused on presentation rather than business
  workflows.
- Keep concerns small and cohesive; do not use them to hide broad shared
  behavior.
- Keep Rails tests under `test/` and aligned with the boundary being changed.

## Persistence

- Keep migrations reversible when practical and explicit when not.
- Separate risky data migrations from broad schema refactors.
- Use transactions for multi-record changes that must commit atomically.
- Do not use callbacks for complex orchestration or external side effects.
