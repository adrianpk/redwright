# RedWright Project Setup Runnable Saga Quiz Notes

## Status

- type: `quiz-notes`
- status: `living`
- date: `2026-05-03`
- related_draft: `ops/specs/drafts/2026-05-03-redwright-project-setup-runnable-saga-draft.md`

## Purpose

These notes preserve the reasoning behind the runnable project setup saga draft. They are curated discussion notes, not a raw transcript.

## Sessions

### Session 2026-05-03

#### Context

- The Rails-backed Telegram setup conversation works better than the earlier repository-first behavior.
- The user verified that `/project new` no longer requires a repository and that the questionnaire can collect name, description, project type, language/runtime, framework, and libraries.
- Manual testing showed the completed setup persisted a full manifest under the project workspace.
- The project workspace still lacked runnable files, so the practical result did not feel like a created project.
- Logs showed model resolution and ingress traces, but not LLM request/response traces for setup prompt rendering.

#### Questions Raised

- How should the backend know whether the user is operating inside a given project from Telegram?
- What does it mean for setup to "create a project" if there is only a manifest?
- Should setup be understood as a saga with visible stages instead of an opaque action?
- How should the system preserve DB state while also producing something useful on disk?
- How should raw natural-language answers be converted into reliable canonical slot values?

#### Candidate Answers

- Keep Rails as the application source of truth for projects, setup sessions, boards, documents, tickets, and setup materialization state.
- Keep Telegram as an adapter that drives Rails commands and renders Rails responses.
- Treat project setup as a saga with stages: `new`, `questionnaire`, `materialization`, `initial_implementation`, and `ticket_operation`.
- Persist raw answers and normalized canonical values separately.
- Let LLMs render human questions and normalize semantic answers, but keep deterministic schema validation and fallback behavior.
- Treat a completed local project setup as either runnable or planned, never as an ambiguous success.

#### Current Convergences

- The DB should keep complete canonical setup context.
- The workspace should contain more than a manifest for supported stacks.
- The first concrete runnable target should be a minimal local scaffold, with Go CLI as a strong acceptance scenario.
- If scaffold generation cannot produce a runnable project, the system should create a planned workspace and starter tickets with an explicit reason.
- LLM traces for setup prompts and normalization must be visible under foreground trace settings.
- Later work should proceed through Rails tickets and documents, not hidden Telegram-only state.

#### Open Tensions

- Whether LLM normalization should run inside Rails or in the Telegram adapter before sending `normalized_fields`.
- Whether `/done` should synchronously scaffold the initial project or create a queued saga step.
- Whether a missing local toolchain should fail runnable materialization or downgrade it to planned materialization.
- How much Rails UI should be included in the first implementation cycle.

#### Provisional Decisions

- `keep`: define explicit saga stages and persist them.
- `keep`: record both raw answer and normalized canonical slot value.
- `keep`: add LLM tracing for project setup prompt rendering and normalization.
- `keep`: implement at least one deterministic scaffold profile before claiming runnable success.
- `keep`: route post-setup work through board tickets.
- `defer`: Protocol template CRUD.
- `defer`: Runtime Containers CRUD and sandbox orchestration.
- `defer`: remote repository creation.

#### Deferred / Out of Scope

- full project management UI
- remote Git provider provisioning
- container sandbox execution
- Protocol template management
- autonomous multi-agent scheduling

## Open Questions

- Should Go CLI be the only first runnable scaffold profile?
- Should web setup use the same LLM normalizer immediately, or should the first slice target Telegram only while preserving the Rails contract?
- Should scaffold templates be pure deterministic templates, LLM-assisted generated files, or deterministic templates with LLM-written README/spec content?

## Edit Notes

- Keep this file aligned with `2026-05-03-redwright-project-setup-runnable-saga-draft.md`.
- Do not add raw chat excerpts unless they clarify a product decision.
