---
name: repo-dump
description: Capture and curate RedWright repository knowledge dumps into raw and curated ops/conv/dump artifacts. Use when the user wants to brain dump, context dump, knowledge dump, free-form exploration, "volcar" ideas, preserve project thinking, or extract structured notes from a broad unstructured explanation without running a bounded quiz.
---

# Repository Dump

Use this skill only inside repositories that follow the RedWright conversation
artifact workflow.

The source of truth is the repository playbook:

- `.agents/playbooks/dump.md`
- `.agents/playbooks/specification-workflow.md`
- `ops/conv/dump/`

## Startup

1. Confirm the repository has `.agents/playbooks/dump.md` and `ops/conv/dump/`.
2. Read `.agents/playbooks/dump.md` before conducting or curating a dump.
3. Keep all artifact content in English, even when the conversation is in another language.
4. Identify the central topic and choose a slug.
5. Decide whether the current dump needs raw capture immediately.

## Invocation Modes

- `start dump`: begin a free-form dump capture.
- `continue dump`: resume from an existing raw or curated dump artifact.
- `curate dump`: turn raw dump capture into curated notes.
- `handoff dump`: summarize central topic, derived threads, and possible next artifacts.

## Raw Capture

Create or update:

`ops/conv/dump/YYYY-MM-DD-<topic>-dump-raw.md`

Rules:

1. Preserve the user's thinking path and useful sequence.
2. Correct spelling, punctuation, and grammar while preserving intent.
3. Group obvious topic shifts with headings.
4. Mark derived threads without expanding them into separate artifacts.
5. Avoid adding interpretation that belongs in curated notes.

## Curated Dump

Create or update:

`ops/conv/dump/YYYY-MM-DD-<topic>-dump.md`

Curate into:

- central topic
- raw source path
- summary
- key concepts
- decisions or strong preferences
- tensions and tradeoffs
- assumptions
- derived threads
- possible downstream artifacts
- open questions

## Interaction Rules

1. Let the user dump freely before steering.
2. Ask clarifying questions sparingly.
3. Use steering only to preserve the center of gravity or identify derived threads.
4. If the work becomes primarily question-driven, suggest switching to `repo-quiz`.
5. Do not create specs, plans, tickets, or derived drafts unless the user explicitly asks.

## Handoff

When the dump ends, report:

- raw dump artifact path
- curated dump artifact path
- whether the central topic is clear
- derived threads
- recommended next artifact options
- open questions
