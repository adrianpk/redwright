# RedWright Rails Project Setup Conversational Saga Conversation Notes

## Status
Living discussion

## Related Draft
`2026-05-03-redwright-rails-project-setup-conversational-saga-draft.md`

## Promoted Specification
`ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`

## Purpose
Curated discussion log supporting the Rails project setup conversational saga draft.

## Sessions

### Session 2026-05-03
#### Context
- A Rails-centered command/query API and project setup saga were already implemented across prior slices.
- Manual Telegram verification showed that `/project new` reaches Rails, but Rails still responds through a repository-first contract.
- The current implementation treats plain project names as repository input and returns an internal `awaiting_repository` state to the user.
- The desired behavior is not another parser patch; it is a functional setup saga with Rails as the core application boundary.

#### Questions Raised
- How should Rails remain the core without losing ActiveRecord convenience?
- Should Telegram host business logic or call Rails APIs as an adapter?
- How should a user-visible loop collect project setup context without becoming rigid or endless?
- Where should canonical answers be persisted before and after project creation?
- How should setup output connect to boards, tickets, documents, and runtime container settings?

#### Candidate Answers
- Keep Rails as the source of truth and keep ActiveRecord models/services as the invariant layer.
- Keep Telegram as an adapter that translates Telegram messages into Rails command/query requests and renders Rails responses.
- Use a two-phase loop: deterministic canonical slots first, adaptive LLM refinement second, while preserving one simple user conversation.
- Persist in-progress canonical answers in `ProjectSetupSession.metadata` and audit each turn in `ProjectSetupTurn`.
- Materialize completed setup context into `Project`, weighted `ProjectAttribute` rows, `Document` summaries, board/ticket artifacts, and runtime bridge settings.

#### Current Convergences
- Repository input must be optional and skippable.
- `/project new` must start even without arguments.
- The first user-facing prompt should ask for missing setup context, not repository syntax unless repository import is the active need.
- The web UI can remain idiomatic Rails while sharing services with the API path.
- Agents should operate visible workflow through Rails command/query APIs, not through adapter-local state.

#### Open Tensions
- The minimum blocking slot set still needs a firm policy.
- The exact boundary between Phase 1 deterministic prompts and Phase 2 LLM refinement needs implementation characterization.
- Container settings may begin as project attributes, but later they may deserve first-class tables if they become operationally complex.
- Initial board/ticket generation may be part of setup completion or a separate explicit action.

#### Provisional Decisions
- Do not undo the Rails-centered architecture.
- Do not continue treating this as a Telegram parser issue.
- Formalize a new spec and plan focused on behavior: conversational project setup over Rails.
- Keep all tests and examples in English and avoid exact user-provided transcript text.

#### Deferred / Out of Scope
- Implementing code before the formal spec, plan, and tracker exist.
- Redesigning the whole runtime executor.
- Final web UI layout decisions.

## Open Questions
- Which setup slots must block `/done`?
- Which normalized fields should be promoted to first-class columns versus weighted attributes?
- What is the first acceptable end-to-end deliverable for Telegram after setup completion: project only, project plus board, or project plus starter tickets?
- How much LLM variation should be allowed in human prompt wording while preserving deterministic testability?

## Edit Notes
- This file is curated, not a raw transcript.
- Keep repository documentation in English.
- Keep this document aligned with the draft and promoted spec.
