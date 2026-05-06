---
id: TKT-20260506073458
title: Enable ticket linked document management
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: linked-documents, ticket-modal, web
source: chat
reported_at: 2026-05-06T07:34:58Z
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
The ticket modal shows a `Linked documents` area below the ticket, but it is currently non-editable.

In the current observed case, linked documents were created by the agent itself. A human user should also be able to attach relevant documents manually.

## Problem
Users can see linked documents but cannot humanly search for, select, attach, or remove documents from a ticket.

This prevents tickets from being connected to existing drafts, specs, quiz artifacts, or other relevant RedWright documents through the UI.

## Expected
- The `Linked documents` area should support attaching documents manually.
- Users should be able to search documents with an autocomplete control.
- The UI does not need to look like a text area.
- The search/autocomplete can be implemented with a Turbo Streams-style interaction if that fits the existing Rails patterns.
- Users should be able to select and attach drafts, specs, quiz artifacts, and other relevant documents.
- Attached documents should render below the search control as removable items similar to Tagify tags.
- Users should be able to remove attached documents with the same lightweight interaction pattern.
- If a ticket has a specified use case, that use case may help rank or filter autocomplete suggestions.
- Use-case filtering must not restrict the user only to matching documents; users should still be able to find and attach other documents.

## Actual
- `Linked documents` is visible but not human-editable.
- There is no obvious way to search, select, attach, or remove linked documents manually.

## Fix Strategy
- Identify the current ticket linked-documents rendering path and persistence model.
- Add a document search endpoint or reuse an existing document query path.
- Add autocomplete UI for selecting documents.
- Render selected documents as removable tag-like attachments.
- Preserve agent-created links while adding human-managed links.
- Use ticket use-case context as ranking/filtering input only when available.

## Validation
- Open a ticket with no linked documents and attach an existing document manually.
- Search and attach drafts, specs, and quiz artifacts where available.
- Remove an attached document and verify it disappears from the ticket.
- Verify agent-created links still render correctly.
- Verify use-case-specific suggestions do not prevent searching broader documents.

## Outcome
Pending implementation.
