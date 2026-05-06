---
id: TKT-20260506074054
title: Implement ticket comments system
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: ticket-comments, mentions, agent-user-loop
source: chat
reported_at: 2026-05-06T07:40:54Z
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
RedWright agents interact with users through Telegram, but in automode they should primarily operate through tickets.

When an agent needs to communicate an issue, ask a question, or leave context for a user who is not currently available, the system should support ticket comments.

This ticket is the canonical implementation ticket for the ticket comments system. Follow-up notification and messenger workflows should build on this instead of redefining comments.

Related design placeholder:
`ops/specs/drafts/2026-05-06-redwright-agent-user-notification-comments-draft.md`

## Problem
Agents need a durable, ticket-scoped way to communicate with users. Plain chat is not enough because the relevant context belongs to the ticket and may need to be reviewed later.

## Expected
- Tickets should support a durable comment thread.
- Agents and humans should be able to leave comments on tickets.
- Comments should render in ticket detail/edit surfaces.
- Comments should preserve author, timestamp, body, and ticket association.
- Comments may include `@user` mentions.
- Comments without mentions should also be valid.
- A mention should be treated as notification intent, not only as display text.
- Mentioned comments should preserve the ticket context needed for later notification delivery.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Define the minimal ticket comment model and persistence boundary.
- Add support for storing comments associated with tickets.
- Add UI support for reading and adding ticket comments.
- Add mention parsing or equivalent structured mention capture.
- Ensure comments can be created by agents and humans.
- Keep notification delivery out of this ticket except for preserving mention intent.

## Validation
- Create a ticket comment without a mention.
- Create a ticket comment with an `@user` mention.
- Verify both comments persist and render on the ticket.
- Verify author and timestamp are preserved.
- Verify mention metadata can be detected for later notification processing.

## Outcome
Pending implementation.
