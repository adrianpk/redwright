# Agent Operating Contract

Read this document before starting any work in this repository.

This contract defines agent behavior, execution discipline, communication style, and governance boundaries.
It is intentionally not a source of product or runtime specification.

## 1) Execution Discipline

- Execute tasks directly once explicitly requested.
- Do not convert discussion into implementation without a clear request.
- Questions are not implementation requests.
- For high-impact changes, present the approach first and wait for explicit approval.
- Complete the requested scope, report outcomes, and stop.
- Do not expand scope with unsolicited follow-up work.

## 2) Planning Protocol

- Before creating a plan, ask whether the user wants a plan.
- If planning is requested, produce a concrete, execution-oriented plan.
- Do not start implementation while a plan is pending user confirmation.
- Keep execution strictly inside the approved scope.

## 3) Communication Protocol

- Use direct, neutral language.
- Keep updates factual and concise.
- Explain reasoning before proposing significant changes.
- Trust user-provided facts unless technical evidence proves otherwise.

## 4) Repository and Git Safety

- `origin` is the canonical remote for this repository.
- Never perform destructive Git operations without explicit approval.

## 5) Language and Documentation Rules

- All code and repository documentation must be written in English.
- Keep naming, comments, and repository text in English.

## 6) Scope Boundary

- Keep this file focused on working rules only.
- Product/runtime specification belongs in `docs/`.

## 7) Referenced Agent Docs

- `.agents/DOCUMENTING.md` — documentation model and placement rules.
- `.agents/CONVENTIONS.md` — coding standards and codebase boundaries.
- `.agents/ARCHITECTURE.md` — repository structure map.
- `.agents/LIFECYCLE.md` — delivery lifecycle and handoff rules.
- `.agents/VERSIONING.md` — commit, branch, and merge rules.
- `.agents/SLICES.md` — task decomposition and delivery strategy.
- `.agents/ROUTING.md` — request classification for execution workflow.
- `.agents/PLAYBOOKS.md` — operational procedures.
- `.agents/LINTING.md` — linting policy and quality-gate setup.
- `.agents/INVARIANTS.md` — non-negotiable collaboration invariants.
