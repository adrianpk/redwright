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
- `.agents/playbooks/quiz.md`
- `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`
- `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`
- `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`
- `ops/plans/2026-05-03-redwright-rails-project-setup-conversational-saga-cycle-plan.md`
- `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`
- `ops/quiz/2026-05-04-redwright-heavy-interaction-sagas-quiz.md`
- `apps/web/app/services/quiz_loops/runtime.rb`
- `apps/web/app/controllers/project_quizzes_controller.rb`
- `apps/web/test/integration/project_setup_telegram_e2e_test.rb`

Spec contrast:
- The repository quiz playbook and the RedWright app quiz runtime are different layers, but they operate in the same conceptual space: bounded, sequential, adaptive question-and-answer flow. The app implementation should not copy the agent workflow mechanically, but it should preserve the same core invariants when they apply.
- The draft is consistent with the spec in requiring a transport-agnostic quiz loop, one-question-at-a-time progression, and shared web/Telegram semantics.
- The current concern about `Skip` and `Answer` is supported by the spec: `answer` must save an answer for the current question, and `skip` must persist the entry as skipped or otherwise move past it without an answer.
- The current concern is also supported by the curated quiz notes: Telegram quiz execution should be a one-question-at-a-time loop, the next question should be LLM-based, and previous questions and answers may influence the next question.
- The cycle plan reinforces this as a runtime concern: Slice 4 requires a port-agnostic quiz loop service that persists answered and skipped `QuizEntry` records, and Slice 6 requires the web surface to use the same adaptive loop semantics as Telegram.
- Adaptive progression is not optional. It appears repeatedly across RedWright's interaction design: the quiz playbook allows bounded follow-up branches, the quiz spec expects prior Q/A to influence the next question, and the `/project new` conversational saga uses a compact Ariadne-style trunk loop with deterministic slots plus adaptive refinement.
- The Ariadne-style idea matters here as a conceptual guardrail: the LLM may enter useful follow-up cycles, but the runtime needs a thread/trunk that lets it return to broader coverage instead of getting lost in local re-questioning.
- The Telegram `/project new` guided/setup flows use an adjacent pattern with strongly biased questions over a specific slot set. That pattern is not the same product feature, but it shows a recurring RedWright design: LLM wording can vary while the state machine, target slot/question identity, and progression rules remain deterministic.
- The draft should not treat `Done` as a permanent finalization unless implementation later introduces explicit lifecycle state. The spec says `done` means the user considers the quiz sufficiently answered for now.
- The draft should not imply first-class questionnaire sessions in this ticket. The spec explicitly excludes session records from the first design.
- `Cancel` should mean stopping the loop without marking it as sufficiently answered; the same quiz can be opened again later.
- `Done` and `Cancel` currently need distinct semantics, but those semantics may be represented by navigation/outcome behavior rather than persistent quiz closure in the first version.

Relevant references:
- `.agents/playbooks/quiz.md`, sections `Core Principles`, `Question Execution Model`, and `State Awareness`: defines boundedness, sequential one-question delivery, adaptive progression after each answer, state tracking, and stopping when sufficient clarity is reached.
- `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`, section `Telegram Quiz Loop`: defines one-question-at-a-time execution, LLM-generated next question, previous Q/A influence, and control semantics for `answer`, `skip`, `done`, and `cancel`.
- `ops/specs/specs/2026-05-05-redwright-quiz-questionnaire-context-spec.md`, section `Web Counterpart`: requires the web counterpart to reuse the same adaptive quiz loop concept as Telegram and expose the current question plus answer controls.
- `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`, section `Telegram Flow`: requires a one-question-at-a-time loop where previous questions and answers may influence the next question.
- `ops/quiz/2026-05-05-redwright-quiz-me-questionnaire-context-quiz.md`, section `Web Counterpart`: says the web counterpart should reuse the same adaptive loop concept as Telegram.
- `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`, Slice 4: requires a reusable quiz loop runtime that persists answered and skipped entries and supports answer, skip, done, and cancel independently of Telegram or web ports.
- `ops/plans/2026-05-05-redwright-quiz-questionnaire-context-cycle-plan.md`, Slice 6: requires web answer, skip, done, and cancel controls using the same adaptive loop semantics as Telegram.
- `ops/plans/2026-05-03-redwright-rails-project-setup-conversational-saga-cycle-plan.md`, Slice 1: names the `/project new` setup behavior as a compact Ariadne-style trunk loop.
- `ops/specs/specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md`, section `Quizal Loop Contract`: defines deterministic canonical slot collection followed by adaptive refinement, with LLM-assisted wording that must not ask redundant questions for already filled, skipped, or defaulted slots.
- `ops/quiz/2026-05-04-redwright-heavy-interaction-sagas-quiz.md`, `Current Convergences`: says bounded interaction segments can be represented through normal state, turns, and prompt intent, and that prompt intent should be structured while adapters render channel-specific UI/copy.

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
- Web behavior may also drift from the repository quiz playbook's conceptual model: after a user answers or skips exactly one current question, the system should deterministically decide whether to continue, follow up, switch topic, or terminate. The current URL-carried question flow makes that decision boundary hard to trust.
- Without an Ariadne-style thread/trunk concept, adaptive progression can become a series of locally plausible LLM follow-ups that lose the broader question plan, repeat already-covered points, or fail to return to the next useful question.
- The current URL-driven web flow does not visibly encode the kind of state needed for biased-but-variable question generation: current question identity, prior entries, follow-up depth, coverage, and the route back to the trunk question sequence.
- This logic may already exist partially in another RedWright flow, especially `ProjectSetupSession`, guided alignment, saga state, prompt intent, or quiz runtime code. Reimplementing a parallel version without checking reuse would add avoidable drift.
- `Done` and `Cancel` semantics need validation against the specification and Telegram behavior.

## Expected
- The quiz flow is deterministic, sequential, and state-consistent.
- Web quiz navigation avoids exposing the actual question payload/content through URL parameters when a cleaner server-side or identifier-based mechanism is feasible.
- Question progression is represented through sequential identifiers, internal state resolution, server-side progression logic, or another clean state mechanism.
- `Answer` submits the current answer and advances to the next question.
- `Skip` records an intentional bypass of the current question and advances to the next question.
- `Answer` and `Skip` are both coupled to a backend-resolved current question identity or state, not merely to question text copied through URL params.
- The next question after `Answer` or `Skip` is resolved by the shared quiz runtime using prior quiz entries as context.
- The runtime maintains enough state to support the same conceptual invariants as the quiz playbook: one current question, explicit progression after response, bounded exploration, and no loss of current question identity.
- Adaptive progression supports useful LLM follow-up cycles while preserving an Ariadne-style return path to the broader question plan.
- Question generation may be strongly biased toward a specific question/slot set when the workflow requires it, as in `/project new`, while still allowing natural wording and useful variations.
- Follow-up depth, coverage state, and the trunk/current question relationship are explicit enough that `Answer` and `Skip` cannot accidentally advance the wrong question or trap the user in repeated local follow-ups.
- Question routing can later improve coverage or follow-up logic without depending on browser URL payloads as the source of truth.
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
- Use `.agents/playbooks/quiz.md` as a conceptual reference for invariants, not as an application architecture requirement.
- Use the `/project new` Ariadne-style trunk loop and guided alignment behavior as adjacent conceptual references for deterministic state plus LLM-varied prompts.
- Before introducing new state or services, verify whether equivalent logic already exists in `QuizLoops::Runtime`, `QuizLoops::QuestionContract`, `ProjectSetup::GuidedAlignmentService`, `ProjectSetup::PromptIntentBuilder`, `ProjectSetup::SagaState`, or related setup/session models.
- If an equivalent or adjacent mechanism exists, evaluate whether it can be generalized through configuration per use case/workflow rather than duplicated. Candidate configurable dimensions include question set, trunk sequence, follow-up depth, coverage policy, control semantics, prompt intent, and persistence target.
- Preserve domain-specific behavior where needed; do not force a generic abstraction if reuse would obscure quiz-specific or project-setup-specific semantics.
- Review whether the quiz runtime needs explicit current-question metadata such as sequence/trunk position, follow-up depth, coverage/topic, or prompt intent before changing routes.
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
