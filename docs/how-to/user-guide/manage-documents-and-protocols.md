# Manage Documents And Protocols

## Purpose

Use documents for project knowledge and protocols for agent operating guidance.

## Before You Start

- Create or select a project.
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

5. Edit a project protocol document.

Protocol documents are Markdown documents. Changes are persisted in Rails and projected to workspace files such as:

```text
AGENTS.md
.agents/*.md
.agents/playbooks/*.md
```

6. Open protocol templates.

Use the protocol templates area to inspect and edit common templates and stack templates.

Template edits affect future project setup composition. They do not rewrite protocol copies that already belong to existing projects.

## Verify

- Draft changes are visible after save.
- Promoted specs appear under `Specs`.
- Project protocol edits are saved in the web app.
- Materialized project protocol files update in the workspace when the project has a local workspace.
- Template edits remain scoped to future project setup.

## Troubleshooting

- If a document cannot be edited, confirm it is a draft.
- If protocol edits do not appear in files, confirm the project workspace has been materialized locally.
- If template edits do not affect an existing project, that is expected; existing project protocols are copied project state.

## Related Docs

- [Project Protocol Templates Specification](../../../ops/specs/specs/2026-05-03-redwright-project-protocol-templates-spec.md)
- [Application Semantics v1](../../reference/application-semantics-v1.md)
