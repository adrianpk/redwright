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
- The current concern about `Skip` and `Answer` is supported by the spec: `answer` must save an answer for the current question, and `skip` must persist the entry as skipped or otherwise move past it without an answer.
- The current concern is also supported by the curated quiz notes: Telegram quiz execution should be a one-question-at-a-time loop, the next question should be LLM-based, and previous questions and answers may influence the next question.
- The cycle plan reinforces this as a runtime concern: Slice 4 requires a port-agnostic quiz loop service that persists answered and skipped `QuizEntry` records, and Slice 6 requires the web surface to use the same adaptive loop semantics as Telegram.
- The draft should not treat `Done` as a permanent finalization unless implementation later introduces explicit lifecycle state. The spec says `done` means the user considers the quiz sufficiently answered for now.
- The draft should not imply first-class questionnaire sessions in this ticket. The spec explicitly excludes session records from the first design.
- `Cancel` should mean stopping the loop without marking it as sufficiently answered; the same quiz can be opened again later.
- `Done` and `Cancel` currently need distinct semantics, but those semantics may be represented by navigation/outcome behavior rather than persistent quiz closure in the first version.

Relevant references:
- `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`, section `Telegram Quiz Loop`: defines one-question-at-a-time execution, LLM-generated next question, previous Q/A influence, and control semantics for `answer`, `skip`, `done`, and `cancel`.
- `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`, section `Web Counterpart`: requires the web counterpart to reuse the same adaptive quiz loop concept as Telegram and expose the current question plus answer controls.
- `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`, section `Telegram Flow`: requires a one-question-at-a-time loop where previous questions and answers may influence the next question.
- `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`, section `Web Counterpart`: says the web counterpart should reuse the same adaptive loop concept as Telegram.
- `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`, Slice 4: requires a reusable quiz loop runtime that persists answered and skipped entries and supports answer, skip, done, and cancel independently of Telegram or web ports.
- `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`, Slice 6: requires web answer, skip, done, and cancel controls using the same adaptive loop semantics as Telegram.

## Problem
The current web quiz navigation appears coupled to URL state and does not reliably model deterministic question progression. Current symptoms and risks:

- The current question content is passed through query parameters.
- `Answer` and `Skip` redirect with a generated next question in the URL.
- `Answer` and `Skip` appear visually present but may not be sufficiently coupled to the intended question-answering logic described in the quiz spec and cycle plan.
- `Answer` must represent "save this answer for this exact current question, then route to the next resolved question"; it should not behave as a generic form post whose correctness depends on URL-carried question content.
- `Skip` must represent "persist or otherwise record this exact current question as skipped, then route to the next resolved question"; it should not simply navigate away or rely on fragile query state.
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
- `Answer` and `Skip` are both coupled to a backend-resolved current question identity or state, not merely to question text copied through URL params.
- The next question after `Answer` or `Skip` is resolved by the shared quiz runtime using prior quiz entries as context.
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
