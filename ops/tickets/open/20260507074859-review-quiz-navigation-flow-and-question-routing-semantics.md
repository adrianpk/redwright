---
id: TKT-20260507074859
title: Review quiz navigation flow and question routing semantics
status: open
kind: task
severity: medium
priority: normal
scope: web
tags: quiz,navigation,web,telegram,semantics
source: chat
reported_at: 2026-05-07T07:48:59Z
ready_at:
started_at:
reviewed_at:
closed_at:
resolution:
owner: 
branch:
pr:
commits: []
---

## Context
The current web quiz flow exposes the current question and tag state through URL query parameters such as:

```text
/projects/9/quizzes/5?question=...
```

This ticket captures a review and implementation task for quiz navigation and question routing semantics. The work should align the web flow with the already established Telegram interaction model while preserving the product constraints from the quiz specification.

Reference artifacts:
- `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
- `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`
- `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`
- `apps/web/app/services/quiz_loops/runtime.rb`
- `apps/web/app/controllers/project_quizzes_controller.rb`
- `apps/web/test/integration/project_setup_telegram_e2e_test.rb`

Spec contrast:
- The draft is consistent with the spec in requiring a transport-agnostic quiz loop, one-question-at-a-time progression, and shared web/Telegram semantics.
- The draft should not treat `Done` as a permanent finalization unless implementation later introduces explicit lifecycle state. The spec says `done` means the user considers the quiz sufficiently answered for now.
- The draft should not imply first-class questionnaire sessions in this ticket. The spec explicitly excludes session records from the first design.
- `Cancel` should mean stopping the loop without marking it as sufficiently answered; the same quiz can be opened again later.
- `Done` and `Cancel` currently need distinct semantics, but those semantics may be represented by navigation/outcome behavior rather than persistent quiz closure in the first version.

## Problem
The current web quiz navigation appears coupled to URL state and does not reliably model deterministic question progression. Current symptoms and risks:

- The current question content is passed through query parameters.
- `Answer` and `Skip` redirect with a generated next question in the URL.
- Question transitions may diverge from backend runtime state.
- The next question may not be resolved or received consistently.
- Web behavior may drift from the Telegram quiz flow even though both should use the same port-agnostic runtime.
- `Done` and `Cancel` semantics need validation against the specification and Telegram behavior.

## Expected
- The quiz flow is deterministic, sequential, and state-consistent.
- Web quiz navigation avoids exposing the actual question payload/content through URL parameters when a cleaner server-side or identifier-based mechanism is feasible.
- Question progression is represented through sequential identifiers, internal state resolution, server-side progression logic, or another clean state mechanism.
- `Answer` submits the current answer and advances to the next question.
- `Skip` records an intentional bypass of the current question and advances to the next question.
- `Cancel` stops the current loop without marking the quiz as sufficiently answered.
- `Done` stops the current loop because the user considers the quiz sufficiently answered for now.
- Both `Cancel` and `Done` allow the same quiz to be opened again later unless a future spec explicitly changes lifecycle semantics.
- Web and Telegram use the same quiz runtime semantics rather than separate business rules.

## Actual
- `ProjectQuizzesController#show` resolves the current question from `params[:question]` or opens the runtime.
- `ProjectQuizzesController#use_case`, `#answer`, and `#skip` redirect with `question:` and `tags:` query parameters.
- `ProjectQuizzesController#done` and `#cancel` both call `advance!` with control answers and redirect to the quiz list.
- `QuizLoops::Runtime` returns terminal `done` and `cancelled` results but does not currently persist a first-class session or permanent quiz terminal state.
- Telegram tests establish that `/quiz` opens a quiz and that an answer is recorded through the Telegram adapter.

## Fix Strategy
- Review the web quiz controller, runtime, Telegram adapter behavior, and tests before changing persistence.
- Identify whether the current URL-based question passing can be replaced by a safer server-side or identifier-based progression mechanism without introducing first-class questionnaire sessions.
- If persistent state is required, keep it aligned with the spec's first-version constraints and avoid broad session architecture unless explicitly promoted to spec/plan work.
- Ensure `Answer`, `Skip`, `Cancel`, and `Done` have distinct and tested semantics.
- Align web behavior with Telegram behavior through the shared runtime rather than duplicating control logic in the controller.
- Add or update tests for question progression, skipped entries, answer advancement, cancel behavior, done behavior, reopening after cancel, and reopening after done.
- Capture any larger lifecycle or session-model decision as a follow-up if it exceeds this ticket.

## Validation
- Targeted Rails tests for `ProjectQuizzesController`.
- Targeted Rails tests for `QuizLoops::Runtime`.
- Telegram adapter or integration tests covering quiz answer/skip/done/cancel behavior where applicable.
- Full Rails test suite from `apps/web`.
- Repository ticket checks after status or metadata changes.

## Outcome
Pending implementation.
