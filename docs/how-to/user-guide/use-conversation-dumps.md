# Use Conversation Dumps

## Purpose

Keep the context for one feature in one editable Markdown document. A quiz can
then uncover missing decisions, and a specification can use both sources.

## Edit a Dump

1. Select the project and open `Dumps`.
2. Click `New` and choose the feature's use case. Each case has one dump;
   opening it again reuses the document.
3. Click the rendered document to edit its Markdown.
4. Leave the editor or click `Save`. The complete document replaces the previous
   content. Reading resumes only after a successful save.

Use the `Draft / Ready` sliding control beside the title to change status.
Changes save immediately. Ready documents remain editable. Status is stored in the
file's YAML frontmatter; the database indexes its metadata and path.

There are no contribution cards, append history, or separate raw and curated
bodies. Legacy project-level dumps remain accessible.

## Curate the Text

Click `Curate` to correct the text, remove filler and repetition, and organize
its ideas into clear source material for later quiz and specification work.
The local wrapped harness preserves meaningful details, decisions, uncertainty,
and open questions. It produces an editable dump, writes the same file, and
leaves its status unchanged.
`REDWRIGHT_DUMP_HARNESS` selects the executable; otherwise the configured
specification harness or `codex` is used.

A harness failure leaves the document unchanged. There is no generated fallback
summary presented as successful curation.

## Edit Outside RedWright

New dumps live at `ops/default/dump/<ordinal>-<slug>/artifact.md` inside their
project workspace. Existing `ops/conv/dump/*-dump.md` documents are also indexed.
The web app refreshes the index when reading Dumps or building discovery context.
Quiz and spec generation read the current Markdown file.

If the file changes while you edit or curate it, RedWright refuses to overwrite
it. The editor keeps your text and displays the conflict. Copy your changes,
reload the latest file, and reconcile them before saving again.

Both draft and ready dumps can supply quiz/spec context. Ticket execution also applies
its context policy, case scope, and topic selection.

## Related Docs

- [Use The Web App](use-the-web-app.md)
- [Use Telegram](use-telegram.md)
- [LLM Context Shaping](../../reference/llm-context-shaping.md)
- [Specification Files](../../reference/specification-files.md)
