# RedWright Quiz Questionnaire Context Conversation

## Status

- type: `alignment-conversation`
- date: `2026-05-05`
- source: curated questionnaire about `quiz` commands, questionnaire persistence, web counterpart, tagging, and future context retrieval

## 1. Scope

This conversation captures curated alignment for the RedWright quiz feature centered on persistent project and use-case questionnaires, Telegram commands, web counterpart behavior, tagging, and future context retrieval for ticket-driven engineering.

It is derived from the raw questionnaire capture:

`ops/specs/conv/2026-05-05-redwright-quiz-me-questionnaire-context-conv-raw.md`

## 2. Product Boundary

The first spec should focus on the quiz system itself:

- persistence
- entity relationships
- project-level quizzes
- use-case-level quizzes
- tagged question-and-answer entries
- Telegram command behavior
- web counterpart behavior

RedWright already has context injection. This feature should not be framed as introducing context injection from scratch. It adds a structured context source that can later optimize and refine existing context injection.

## 3. Naming

Use short names.

Preferred entity names:

- `Quiz`
- `QuizEntry`
- `UseCase`
- `Tag`
- `Tagging`

`Quiz` is preferred over `Questionnaire` because it is shorter and easier to spell.

`QuizEntry` represents a question-and-answer tuple. It should not imply that answers are modeled independently from questions.

## 4. Core Model

A project has quizzes.

A quiz is always the grouping entity.

Questions never hang directly from the project.

A quiz has many `QuizEntry` records.

Each `QuizEntry` stores the question and answer together.

Each `QuizEntry` should reference:

- project
- quiz
- use case when applicable

The project/use-case fields may duplicate data inferable through the quiz. This denormalization is acceptable because it can make future context retrieval queries faster and simpler.

## 5. Quiz Scope

There should be one main project-level quiz per project.

There should be one main use-case-level quiz per use case inside a project.

A project-level quiz has no use case.

A use-case-level quiz is associated with a `UseCase`.

Sessions are intentionally not part of the first design. Future session-like analysis may be inferred from timestamp bursts if needed.

## 6. Use Cases

RedWright needs a project `UseCase` concept.

Use cases belong to projects.

When a user runs a quiz command with a use-case name, the argument should be interpreted as a use case name.

If the use case does not exist in the active project, RedWright should create it.

The exact use-case command surface can be handled separately; this spec should focus on quizzes.

## 7. QuizEntry Semantics

The first design should not keep answer history.

Editing an answer should update the current answer.

Moderate duplicate or similar questions are acceptable. LLM-generated questions may overlap. Both entries can remain in the pool, and later retrieval can surface both if relevant.

Possible entry states may include values such as `answered`, `skipped`, or a technical incomplete state. The spec may suggest states, but should not overconstrain implementation beyond what is needed.

`position` can be reserved for future use but is not essential in the first version.

## 8. Tags

Tags apply to the `QuizEntry` tuple.

Because question and answer are stored together, tagging the tuple effectively tags both.

Tags should be free-form, with normalization such as lowercase kebab-case.

The initial design should use a transversal relational tagging model, even though it is more work than inline arrays.

The reason is future retrieval value across:

- quiz entries
- tickets
- documents
- use cases
- other artifacts

The implementation should verify any existing ticket tagging behavior and align it into one unified tagging system rather than creating incompatible tag mechanisms.

LLM-based tag generation should happen on the fly as part of the answer interpretation flow.

Manual tag editing in the web UI can come later.

The maximum number of tags per entry should be configurable. A default around 3 is preferred; 5 is a reasonable upper range.

## 9. Tickets

Tickets should eventually participate in the same context retrieval strategy.

Tickets should be able to have an optional `use_case_id`.

This is useful for queries such as:

```text
project + use case + tag
```

That query shape can retrieve related quiz entries and tickets efficiently for future prompt/context optimization.

## 10. Telegram Commands

Use one base command:

```text
/quiz
```

Initial command grammar:

- `/quiz`: run the active project's main quiz
- `/quiz for <use_case>`: run the active project's quiz for that use case
- `/quiz list`: list quizzes for the active project

The `for` keyword is an acceptable reserved word because it avoids reserving many possible use-case names such as `me`, `list`, `show`, or `help`.

## 11. Telegram Flow

Telegram quiz execution should be a one-question-at-a-time loop.

The next question should be LLM-based.

Previous questions and answers may influence the next question.

The loop should support bounded follow-up depth so it can explore a thread without getting trapped in one path.

The default hard question limit can follow the current questionnaire playbook value of 50, but the value should be configurable.

The default follow-up depth of 3 is reasonable, but should also be configurable.

Configuration should come from YAML first and later from web settings.

Minimum controls:

- answer
- skip
- done
- cancel

`done` means the user considers the current quiz sufficiently answered for now.

`cancel` means stop the loop without marking it as sufficiently answered. The same quiz can always be opened again later.

## 12. Web Counterpart

The web counterpart should reuse the same adaptive loop concept as Telegram.

The first web UI should not show a full list of prior questions and answers.

It should keep the UI simple:

- show the current question
- collect the answer
- expose basic controls
- hide the agent's reasoning

If the agent decides a follow-up is useful, it should ask it directly. The user does not need to see the reasoning process.

Quizzes can live as a project section near existing project surfaces such as Board and Docs. If the menu becomes overloaded later, the UX can be revisited.

## 13. LLM Contract

The LLM should generate quiz questions.

The formal output contract can be refined in the spec.

The existing structured question machinery used for project setup should be treated as a strong reference. RedWright should not reinvent that contract unnecessarily.

Any LLM rationale for choosing a question should remain hidden from the user and should not be persisted as primary content.

Rationale may appear in trace/debug when useful.

The prompt that generates questions must include guardrails against asking for:

- secrets
- passwords
- tokens
- credentials
- PII

## 14. Product Assumptions

RedWright is currently a single-user product and may remain that way.

The product model is one lead commanding a set of agents.

This spec should not introduce multi-user roles or permissions.

The current demo/test seeding may create more than one user and should be reviewed against the single-user product model.

Quiz records should be agnostic of the driving port. A `QuizEntry` should not need to store whether it came from Telegram, web, or another interface.

## 15. Minimum Success Criteria

The minimum successful feature includes:

- project-level quizzes
- use-case-level quizzes
- Telegram `/quiz`, `/quiz for <use_case>`, and `/quiz list`
- web counterpart for answering quiz questions
- persistent `QuizEntry` question-and-answer tuples
- relational tags/taggings for quiz entries
- enough project/use-case/tag structure to support future context retrieval optimization

## 16. Open Questions

- Exact Rails schema and constraints for nullable `use_case_id`.
- Exact `QuizEntry` status constants.
- Exact LLM output contract for next-question generation and tagging.
- Exact YAML configuration shape for question count and follow-up depth.
- Exact web routes and UI layout.
- How unified taggings should be introduced if ticket tagging already exists elsewhere.
- Whether context retrieval should record which quiz entries were used by a future ticket prompt.
