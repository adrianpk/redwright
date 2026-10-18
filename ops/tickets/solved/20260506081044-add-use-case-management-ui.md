---
id: TKT-20260506081044
title: Add use case management UI
status: solved
kind: task
severity: medium
priority: normal
scope: web
tags: use-cases, web, crud
source: chat
reported_at: 2026-05-06T08:10:44Z
ready_at: 2026-05-06T16:47:39Z
started_at:
reviewed_at: 2026-10-18T20:45:27Z
closed_at: 2026-10-18T20:45:27Z
resolution: fixed
owner:
branch: multi-slice; see ops/trackers/2026-05-06-redwright-use-case-management-ui-cycle-tracker.md
pr: https://codeberg.org/adrianpk/redwright/pulls/335
commits:
  - a10bbfa
  - 93b950a
  - 81a70df
  - 274429b
  - 34f7570
  - 1c2c5c7
  - d6adcca
  - 45163f2
---

## Context
Quizzes currently handles the concept of use cases, but use cases should not be created or administered from the Quizzes surface itself.

RedWright needs a UI surface to manage use cases consistently with the rest of the site.

Alignment artifacts:

- Raw quiz: `ops/conv/quiz/2026-05-06-redwright-use-case-management-ui-quiz-raw.md`
- Curated quiz: `ops/conv/quiz/2026-05-06-redwright-use-case-management-ui-quiz.md`
- Spec: `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md`

## Problem
Use cases exist as a meaningful namespace for questions and project context, but there is no dedicated CRUD UI for managing them.

Without a clear management surface, Quizzes may become overloaded with use-case administration concerns.

## Expected
- Add a CRUD UI for managing use cases.
- Keep use cases scoped to the currently selected project.
- Model use cases as first-class project-local namespaces, not only tags.
- Require `name` and `description`.
- Generate readable slug URLs without exposing slug editing in the first UI.
- The UI should be consistent with the rest of the RedWright web site.
- Use cases should function primarily as namespaces for organizing related questions/context.
- Quizzes should consume/use use cases, not own their creation and administration.
- The implementation should remain simple and avoid Jira-style generalization.
- Add useful associations so the CRUD is not empty: tickets, documents, quizzes, and plan artifacts should be scopeable to a use case where appropriate.
- Ticket and document use-case assignment should remain optional.
- Do not create use cases inline from Quizzes, Tickets, or Documents in the first version.
- Do not cascade delete associated records.
- Provide command-query operations for agent/messaging operation.

## Actual
- Use cases are represented through Quizzes behavior, but no dedicated use-case administration surface is available.

## Fix Strategy
- Use `ops/specs/specs/2026-05-06-redwright-use-case-management-ui-spec.md` as the source of truth.
- Add or complete backend/model associations before UI where practical.
- Add command-query operations such as `CreateUseCase`, `UpdateUseCase`, `DeleteUseCase`, `ListUseCases`, and `GetUseCase`.
- Add a dedicated `Use Cases` navbar entry between `Protocols` and `Quizzes`.
- Add a minimalist newest-first Use Cases table scoped to the selected project.
- Use modals for create/edit/detail.
- Show discreet metrics in the detail/edit modal.
- Place delete in the detail/edit modal only, with backend safety checks and no cascade.
- Add optional use-case selectors to ticket and document create/edit surfaces in the appropriate slice.

## Validation
- Validate the behavior defined in the spec.
- Verify current-project scoped Use Cases navigation.
- Verify create/edit/detail modal behavior.
- Verify required `name` and `description`.
- Verify generated slug URL behavior and project-local uniqueness.
- Verify optional ticket/document use-case assignment.
- Verify associated metrics.
- Verify delete is safe, non-cascading, and blocked when references exist.
- Verify command-query operations.

## Triage Notes
Quiz alignment completed. The ticket is ready, but the spec may justify splitting implementation into slices.

## Outcome
Implemented through the eight-slice Use Case Management UI cycle. Project-scoped CRUD, generated slugs, command/query operations, reference metrics, optional ticket assignment, and protected deletion are integrated into `dev`.

## Resolution Evidence

Status reconciled on 2026-10-18 after verifying that every listed commit is included in `origin/dev`.

- Cycle evidence: `ops/trackers/2026-05-06-redwright-use-case-management-ui-cycle-tracker.md`.
- Current implementation: `apps/web/app/controllers/use_cases_controller.rb` and `apps/web/app/services/use_cases/command_query_handlers.rb`.
