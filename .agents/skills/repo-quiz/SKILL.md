---
name: repo-quiz
description: Conduct bounded RedWright repository questionnaire sessions and curate the outcome into ops/quiz artifacts. Use when the user asks to run a quiz, questionnaire, discovery round, structured questions, "hagamos un quiz", "ronda de preguntas", "quiz me", capture or curate quiz notes, create raw quiz capture, or turn a quiz result into pre-spec alignment context for RedWright.
---

# Repository Quiz

Use this skill only inside repositories that follow the RedWright quiz workflow.

The source of truth is the repository workflow, not this skill:

- `.agents/playbooks/quiz.md`
- `.agents/playbooks/specification-workflow.md`
- `ops/templates/spec-quiz-template.md`
- `ops/quiz/`

## Startup

1. Confirm the repository has `.agents/playbooks/quiz.md`, `.agents/playbooks/specification-workflow.md`, `ops/templates/spec-quiz-template.md`, and `ops/quiz/`.
2. Read `.agents/playbooks/quiz.md` before conducting or curating a questionnaire.
3. Read `.agents/playbooks/specification-workflow.md` when the quiz will become a draft/spec input.
4. Keep all artifact content in English, even when the conversation is in another language.

## Invocation Modes

- `run quiz`: conduct a bounded questionnaire with the user.
- `continue quiz`: resume from an existing raw capture or curated quiz file.
- `curate quiz`: convert raw capture into curated notes.
- `promote quiz`: use curated quiz notes as source context for a spec draft or formal spec when explicitly requested.

## Run Quiz

Before asking the first question:

1. Identify the topic and choose a slug.
2. Internally precompute a finite candidate question set with a hard cap of 50 questions.
3. Define what sufficient clarity means for the topic.
4. Track question count, remaining budget, active topic, nesting level, and topic coverage.
5. For long sessions, create or update `ops/quiz/YYYY-MM-DD-<topic>-quiz-raw.md` as working memory.

During the session:

1. Ask exactly one question at a time.
2. Wait for the user response before asking the next question.
3. Use follow-ups only when they materially improve clarity.
4. Do not go deeper than primary question -> follow-up -> deep clarification.
5. Shift topics when one area is becoming overrepresented.
6. Stop early when clarity is sufficient, questions become low-value, or the 50-question cap is reached.

Raw capture rules:

1. Preserve enough question and answer context to prevent information loss.
2. Polish spelling and grammar while preserving intent.
3. Treat raw capture as working memory, not the final curated output.
4. Update raw capture incrementally after each answer or small group of related answers in long sessions.

## Curate Quiz

Create or update `ops/quiz/YYYY-MM-DD-<topic>-quiz.md`.

1. Use `ops/templates/spec-quiz-template.md` when a new curated artifact is needed.
2. Distill decisions, constraints, tensions, assumptions, and open questions.
3. Do not map questions one-to-one into the curated artifact.
4. Do not include chat transcript noise or conversational scaffolding.
5. Include `Open Questions` explicitly.
6. Cross-reference related draft/spec artifacts when they exist.
7. Keep provisional decisions clearly marked.

## Handoff

When the questionnaire ends, report:

- quiz artifact paths created or updated
- whether sufficient clarity was reached
- remaining open questions
- whether the curated quiz is enough pre-spec context or whether a separate draft is still needed

Do not create a spec draft or formal spec unless the user explicitly asks for that next step.
