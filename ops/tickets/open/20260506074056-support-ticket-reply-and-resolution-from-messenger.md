---
id: TKT-20260506074056
title: Support ticket reply and resolution from messenger
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: telegram, ticket-comments, reply-flow
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
When a user receives a Telegram notification for a ticket mention, they may need to respond without opening the web UI.

The user should eventually be able to reply or resolve the issue on the fly from the messenger.

Related design placeholder:
`ops/specs/drafts/2026-05-06-redwright-agent-user-notification-comments-draft.md`

## Problem
Ticket mention notifications are less useful if the user must switch contexts to answer a question or resolve a simple request.

## Expected
- Telegram notifications for ticket mentions should include a link to the ticket.
- Users should be able to reply from Telegram when the notification expects an answer.
- Replies should be attached back to the ticket as comments or equivalent ticket-scoped communication.
- Users should be able to resolve simple mention-driven requests from Telegram when appropriate.
- Messenger-side actions should not bypass ticket auditability.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Define how a Telegram notification maps back to a ticket and comment.
- Define the minimal reply routing behavior.
- Define what "resolve from messenger" means for ticket comments or mention requests.
- Preserve all messenger replies/actions in the ticket audit trail.

## Validation
- Send a ticket mention notification to Telegram.
- Reply from Telegram and verify the reply appears on the ticket.
- Trigger a supported resolve action from Telegram and verify the ticket/comment state updates.
- Verify all actions preserve ticket context and auditability.

## Outcome
Pending implementation.
