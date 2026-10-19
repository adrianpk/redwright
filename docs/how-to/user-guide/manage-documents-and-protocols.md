# Manage Specs And Protocol

## Purpose

Use Specs for feature contracts and Protocol for agent operating guidance.

## Before You Start

- Create or select a project.
- Make the project workspace available locally before working with Specs or Protocol.
- Use the web app for Markdown editing.
- Keep the distinction between documents and protocols clear.

## Steps

1. Generate a specification.

Open `Specs` and select `New`. In the modal, select the feature's use case,
describe the feature, and select `Generate`. RW invokes the local
wrapped harness with project context, relevant dumps, and quiz answers. A dump
is optional, and a quiz can start without one.

2. Review and approve.

Generated specifications start as `draft`. Read the result and choose `Approved`
on the status switch in the title row. Click the document to edit its Markdown.
Leave the editor or select `Save` below it to persist the same file with its
selected Draft/Approved state. Failed or conflicting saves keep your text open.
Approval does not start ticket execution. Regenerate and Build tickets are in
the header; editing and status changes are blocked once execution starts.

3. Write a specification directly when the behavior is already clear.

Select `New`, then `Write` in the modal. Fill in the title and Markdown body,
choose Draft or Approved on the status switch, and select `Save`.
Each use case is one feature with
one specification. No dump, quiz, or separate draft document is
required for manual authoring.

Specification files remain authoritative. External changes appear when the
section is refreshed. If another tool changes a file while you edit it, RW
rejects the outdated save. Reload and reconcile the changes. Removed files
are not recreated from the database.

Implementation progress is managed through tickets in Board. Generated internal
trackers reference those same tickets and order execution; they have no web
management surface.

Use `Regenerate` to incorporate later dump entries or quiz answers into the same
specification. Review and approve it again, then use `Build tickets` to generate
or revise its slicing. Useful tickets retain their identity; omitted work closes
as obsolete with its relationships and history preserved.

Once execution starts, the specification and tracker are protected, including
after returning a ticket to ready. Use `New corrective case` for subsequent
contract changes. Discovery can continue on the existing dump and quiz.

4. Open project protocols.

Select `Protocol` in the navigation.

Protocols are the operational instructions for agents and LLMs. They are distinct from project documents.

The list follows the files in the project workspace: root `AGENTS.md` and every
Markdown file under `.agents/`, including subdirectories. Add or remove files
with your editor and reload the page to see the updated set.

The project selector identifies the selected project. AGENTS is always the first
card when its file exists. RW reads only that project's directory. An unavailable workspace produces an empty list;
RW does not substitute its own instructions, templates, or another workspace.

Select `New` to create a concern. Enter its Name, Description, and Markdown Body,
then select `Save`. RW converts the name to uppercase, replaces spaces with
underscores, and adds `.md` under `.agents/`. The body is the document's content.
The configured local harness adds its reference and description to `AGENTS.md`.
The new document appears as a card. Protocol has no database index or content copy.

5. Edit a project protocol document.

The web editor reads and saves the selected file directly. RW and external
agents such as Codex and Pi use the same files:

```text
AGENTS.md
.agents/**/*.md
```

Edit Name to rename a concern, or Description to change what its reference says.
Select `Save` to update the document and its references in `AGENTS.md`. `Delete`
removes both the selected document and its references after confirmation. AGENTS
is the entrypoint and cannot be renamed or deleted from the web interface.

Body-only saves write the selected file without invoking the harness. If another tool changes the file
while the editor is open, RW rejects the outdated save. Reload the file and
reconcile your edits before saving again. Opening Protocols does not create
missing files or restore deleted ones.

6. Open protocol templates.

Use `Settings` to inspect and edit common and stack templates. This catalog is
separate from the selected project's Protocols page.

Templates initialize new project files. Editing a template does not rewrite
an existing project's files, add missing defaults, or restore removed files.

## Verify

- Generated and directly authored specifications appear under `Specs`.
- Approval updates the same specification and its file metadata.
- Web edits appear directly in the selected project file.
- External edits appear after reloading the web editor and in subsequent agent context.
- Added and removed Markdown files change the Protocols list without re-import.
- Template edits remain scoped to future project setup.

## Troubleshooting

- If specification generation fails, verify the local harness is installed and its session is available.
- If Specs reports unavailable or invalid files, correct the workspace path or Markdown metadata.
- If Protocols is empty, check the project workspace path and its `AGENTS.md` and `.agents/` files.
- If a save reports an external change, reload the current file before applying your edits.
- Template edits apply to new projects; existing files remain under project control.

## Related Docs

- [Original Protocol Design](../../../ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md) (historical)
- [Application Semantics v1](../../reference/application-semantics-v1.md)
