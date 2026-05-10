# Conversation Artifacts

This directory stores curated and raw conversation-derived artifacts.

These repository artifacts are distinct from the Rails app's Conversation surface. The app uses Conversation as the product entry point for database-backed Dump and Quiz loops; this directory stores durable repository-side conversation evidence.

## Subdirectories

- `quiz/`: bounded questionnaire artifacts created through the quiz playbook.
- `dump/`: free-form knowledge dump artifacts created through the dump playbook.

## Rules

- Keep artifact content in English.
- Keep raw and curated versions as sibling files.
- Use raw files to preserve recoverable working memory.
- Use curated files to preserve decisions, context, tensions, and open questions.
- Do not create downstream drafts, specs, plans, or tickets from conversation
  artifacts unless explicitly requested.
