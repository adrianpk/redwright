---
id: TKT-20260506074054
title: Implement ticket comments system
status: solved
kind: task
severity: medium
priority: high
scope: web
tags: ticket-comments, mentions, agent-user-loop
source: chat
reported_at: 2026-05-06T07:40:54Z
ready_at: 2026-05-06T08:46:02Z
started_at: 2026-05-06T14:37:57Z
reviewed_at: 2026-05-06T15:13:51Z
closed_at: 2026-05-06T15:29:51Z
resolution: fixed
owner:
branch: fix/ticket-20260506074054-ticket-comments-system
pr: https://codeberg.org/adrianpk/redwright/pulls/326
commits: [ac4198d]
---

## Context
RedWright agents interact with users through Telegram, but in automode they should primarily operate through tickets.

When an agent needs to communicate an issue, ask a question, or leave context for a user who is not currently available, the system should support ticket comments.

This ticket is the canonical implementation ticket for the ticket comments system. Follow-up notification and messenger workflows should build on this instead of redefining comments.

Related design placeholder:
`ops/specs/drafts/2026-05-06-redwright-agent-user-notification-comments-draft.md`

Alignment quiz:
`ops/quiz/2026-05-06-redwright-ticket-comments-system-quiz-raw.md`

## Problem
Agents need a durable, ticket-scoped way to communicate with users. Plain chat is not enough because the relevant context belongs to the ticket and may need to be reviewed later.

## Expected
- Tickets should support a durable comment thread.
- Agents and humans should be able to leave comments on tickets.
- Comments are conversational only; they are not a system event log.
- Comments should render in ticket detail/edit surfaces with Markdown support.
- Comments should preserve author, timestamp, body, and ticket association.
- Comments should preserve structured author identity where possible, with a cached display label for agents or historical stability.
- Comments may include `@user` mentions.
- Comments may include `@agent` mentions.
- Comments without mentions should also be valid.
- A mention should be treated as notification intent, not only as display text.
- Mentions should be persisted as structured records, not only parsed from comment body text.
- Unresolved mention intent should not block comment creation.
- Mentioned comments should preserve the ticket context needed for later notification delivery.
- A command-query entry point such as `AddTicketComment` should exist so comments are not browser-only.
- The first slice should support creating and listing comments only; editing and deletion are deferred.
- Comments should render in chronological ascending order by default.
- Compact ticket modal view should place comments after linked documents.
- Maximized ticket modal view may place comments closer to the expanded body, but should not significantly reduce the body area.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Define the minimal ticket comment model and persistence boundary.
- Define structured mention persistence, such as `TicketCommentMention`.
- Add support for storing comments associated with tickets.
- Add UI support for reading and adding ticket comments.
- Add mention parsing or equivalent structured mention capture.
- Ensure comments can be created by agents and humans.
- Add an `AddTicketComment` command-query operation following the existing ticket command pattern.
- Keep notification delivery out of this ticket except for preserving mention intent.
- Keep autocomplete, inbox, Telegram replies, ticket body mentions, and `#ticket` reference autocomplete out of this ticket.

## Validation
- Create a ticket comment without a mention.
- Create a ticket comment with an `@user` mention.
- Verify both comments persist and render on the ticket.
- Verify author and timestamp are preserved.
- Verify mention metadata can be detected for later notification processing.
- Verify comments can be created through the web UI.
- Verify comments can be created through the command-query boundary.
- Verify comments render Markdown.

## Outcome
Implemented and merged.

The first comments slice now supports:

- Persistent ticket comments.
- Persistent structured comment mentions.
- Human and agent author metadata.
- Web UI comment creation and listing.
- Markdown rendering for comment bodies.
- Plain `@handle` mention capture.
- `AddTicketComment` command-query support.
- Visual fixes for the comment composer textarea resize handle and right-edge alignment.

Deferred follow-up work:

- Textarea autocomplete for `@` mentions and `#` ticket references.
- Notification delivery.
- Inbox integration.
- Telegram reply support.
- Comment editing and deletion.
