# Manage Documents And Protocols

## Purpose

Use documents for project knowledge and protocols for agent operating guidance.

## Before You Start

- Create or select a project.
- Make the project workspace available locally before editing protocols.
- Use the web app for Markdown editing.
- Keep the distinction between documents and protocols clear.

## Steps

1. Open documents.

The documents area is organized by artifact type:

- drafts
- specs
- plan trackers

2. Create or edit a draft.

Drafts support Markdown editing.

3. Promote a draft to a spec.

From a draft page, use `Promote to Spec`.

After promotion, the spec is read-only in the current web surface.

4. Open project protocols.

From a project page, select `Protocols`.

Protocols are the operational instructions for agents and LLMs. They are distinct from project documents.

The list follows the files in the project workspace: root `AGENTS.md` and every
Markdown file under `.agents/`, including subdirectories. Add or remove files
with your editor and reload the page to see the updated set.

The page identifies the selected project and its local workspace path.
RW reads only that directory. An unavailable workspace produces an empty list;
RW does not substitute its own instructions, templates, or another workspace.

5. Edit a project protocol document.

The web editor reads and saves the selected file directly. RW and external
agents such as Codex and Pi use the same files:

```text
AGENTS.md
.agents/**/*.md
```

Saving one file leaves the others untouched. If another tool changes the file
while the editor is open, RW rejects the outdated save. Reload the file and
reconcile your edits before saving again. Opening Protocols does not create
missing files or restore deleted ones.

6. Open protocol templates.

Use `Settings` to inspect and edit common and stack templates. This catalog is
separate from the selected project's Protocols page.

Templates initialize new project files. Editing a template does not rewrite
an existing project's files, add missing defaults, or restore removed files.

## Verify

- Draft changes are visible after save.
- Promoted specs appear under `Specs`.
- Web edits appear directly in the selected project file.
- External edits appear after reloading the web editor and in subsequent agent context.
- Added and removed Markdown files change the Protocols list without re-import.
- Template edits remain scoped to future project setup.

## Troubleshooting

- If a document cannot be edited, confirm it is a draft.
- If Protocols is empty, check the project workspace path and its `AGENTS.md` and `.agents/` files.
- If a save reports an external change, reload the current file before applying your edits.
- Template edits apply to new projects; existing files remain under project control.

## Related Docs

- [Original Protocol Design](../../../ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md) (historical)
- [Application Semantics v1](../../reference/application-semantics-v1.md)
