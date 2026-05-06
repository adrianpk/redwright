---
id: TKT-20260506151344
title: Add textarea autocomplete for mentions and ticket references
status: open
kind: task
severity: medium
priority: normal
scope: web
tags: autocomplete, mentions, ticket-links
source: chat
reported_at: 2026-05-06T15:13:44Z
ready_at:
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
Ticket textareas should support lightweight reference autocomplete while preserving Markdown as the editable source. When a user types @, the UI should suggest known human users and agents. When a user types #, the UI should suggest existing tickets that can be cross-referenced. Selecting an item should insert a stable Markdown reference into the textarea. In edit mode the Markdown source remains visible. Outside edit mode the rendered surface should show a normal link or mention label. The implementation should be reusable for ticket comments and ticket body textareas.

Expected behavior:
- @ trigger suggests users and agents.
- # trigger suggests existing tickets in the relevant project or board context.
- Keyboard navigation supports ArrowUp, ArrowDown, Enter, Tab, and Escape.
- Selection inserts a stable Markdown reference rather than only visible text.
- Rendered mode displays links or mention labels instead of raw reference syntax.
- The parser should recognize structured Markdown references in addition to plain @handle mention intent.
- Unknown or unresolved references should not block text entry.
- Comment and ticket body inputs should be able to opt into the same component.

Implementation notes:
- Prefer a small trigger-based JavaScript component attached to explicit textarea data attributes.
- Keep trigger behavior configurable so @ and # can use different search endpoints.
- Position the popup near the caret, but keep a fallback position that remains usable in modals.
- Add dedicated search endpoints for mentionable identities and ticket references.
- Mention persistence should stay structured; the Markdown reference is an input/rendering representation, not the only source of truth.
- Do not implement notification delivery as part of this ticket.

Validation:
- Typing @ in a ticket comment textarea shows mention suggestions.
- Typing # in a ticket comment textarea shows ticket suggestions.
- Selecting a suggestion inserts Markdown reference syntax.
- Saving and reopening preserves the Markdown source.
- Rendered comments display readable links/mentions.
- Existing plain @handle mention parsing continues to work.

## Problem
To be clarified during triage.

## Expected
- To be clarified during triage.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Pending triage.

## Validation
- Pending triage.

## Outcome
Pending implementation.
