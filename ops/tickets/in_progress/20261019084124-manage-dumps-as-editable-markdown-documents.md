---
id: TKT-20261019084124
title: Manage dumps as editable Markdown documents
status: in_progress
kind: task
severity: medium
priority: normal
scope: web
tags: dumps, markdown, persistence
source: chat
reported_at: 2026-10-19T08:41:24Z
ready_at: 2026-10-19T08:41:24Z
started_at: 2026-10-19T08:41:24Z
reviewed_at:
closed_at:
resolution:
owner:
branch: feat/ticket-20261019084124-file-backed-dumps
pr:
commits: []
---

## Context
A dump supplies the context for elaborating one use case. The product already
limits each use case to one dump, but the current page exposes database entries,
a concatenated body, and a separate curated body. The same content appears in
several forms and the capture/curation states do not describe an editable document.

## Decision
- A dump is one reeditable Markdown document per use case.
- The project file owns its content, title, case association, and document status.
- The database is a rebuildable index of the path, metadata, and source revision.
- The list shows one card per dump. The detail shows one rendered document.
- Clicking the document starts editing. Leaving the editor saves the complete
  document and returns to reading only after the save succeeds.
- A failed or conflicting save preserves the user's edits and provides a retry
  or reload path. External file edits must never be silently overwritten.
- Quiz and specification context read the current document from its file.

## Expected
- Remove entry cards, append operations, separate raw/curated bodies, and the
  capture/curation state machine from dump persistence, APIs, and UI.
- Keep an explicit Curate action that uses the wrapped harness to polish the
  same Markdown document while preserving its meaning and revision safety.
- Expose one readable document status rather than several overlapping statuses.
- Preserve legacy project-level dumps and existing case-linked dumps, including
  their captured notes and useful synthesized content, as editable documents.
- Preserve Factory tickets, specs, associations, and other artifacts.
- Rewrite the original migrations and schema; add no corrective migrations.
- Keep the previously reviewed primary-navigation cleanup in this same branch.

## Fix Strategy
- Reuse the project's guarded Markdown file store and revision checks.
- Replace the dump body/entry tables with a metadata-only dump index.
- Provide explicit legacy export and database preparation with a source snapshot.
- Update all dump consumers and remove obsolete pipeline code and fixtures.
- Provide the preview with an isolated copy of the example database and workspace.

## Validation
- Test create/read/update, status metadata, index reconstruction, external edits,
  deleted files, stale saves, project isolation, and path/size limits.
- Test current dump content in quiz, specification, and agent context.
- Test lossless legacy export, original-schema creation, and preserved relationships.
- Verify inline editing, save on blur, failed saves, and conflicts in the browser.
- Run the affected Rails suite, repository checks, and ticket validation.

## Verification
- Full Rails suite: 519 tests, 3562 assertions, no failures or errors.
- Full repository Ruby suite: 551 tests, 2902 assertions, no failures or errors.
- Ruby syntax, JavaScript syntax, Sass build, whitespace, and ticket checks pass.
- Browser: click-to-edit, complete replacement on blur, failed-save retry,
  external-write conflict, active navigation, and three viewport widths pass.
- Actual configured harness: Curate saves the same file with a new revision
  while preserving document status.
- Original migrations create the index schema without a dump-entry table.
- Example database preparation retains 3 dumps, 11 tickets, 6 documents,
  3 cases, 2 quizzes, and valid foreign keys in the isolated test bed.

## Outcome
Implementation complete; PR publication and maintainer acceptance pending. Keep the ticket and PR open for maintainer testing;
do not merge or mark the ticket solved before explicit acceptance.
