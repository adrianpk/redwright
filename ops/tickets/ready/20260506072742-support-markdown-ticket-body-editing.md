---
id: TKT-20260506072742
title: Support Markdown ticket body editing
status: ready
kind: task
severity: medium
priority: normal
scope: web
tags: ticket-body, markdown, web
source: chat
reported_at: 2026-05-06T07:27:42Z
ready_at: 2026-05-06T08:46:02Z
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
RedWright tickets need a body field that supports Markdown content.

The editing experience does not need to be a fancy WYSIWYG editor in the first implementation. A raw Markdown editing mode is acceptable if the read view renders Markdown nicely.

## Problem
The ticket body text area does not currently provide the desired Markdown authoring and rendered-reading workflow.

## Expected
- Ticket body content should support Markdown.
- The ticket body should render in a nice formatted mode when not being edited.
- Clicking the rendered body area may switch it into raw Markdown text editing mode.
- Clicking outside the body area, or into another field, should return the body to rendered mode.
- A WYSIWYG editor is not required for this ticket.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Identify the current ticket body rendering/editing path.
- Add Markdown rendering for read mode.
- Add raw Markdown editing behavior for edit mode if no existing editor abstraction is available.
- Keep the first implementation simple and avoid introducing a heavy editor unless already present.

## Validation
- Create or edit a ticket body with Markdown formatting.
- Verify read mode renders Markdown formatting.
- Verify clicking the body enters raw Markdown edit mode.
- Verify leaving the field returns to rendered mode without losing content.

## Outcome
Pending implementation.
