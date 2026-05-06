---
id: TKT-20260506074055
title: Add notification manager for ticket mentions
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: notifications, mentions, telegram
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
Ticket comments with `@user` mentions should eventually notify users through multiple surfaces.

A future notification manager should own representation and delivery, including a web inbox and Telegram messages.

Related design placeholder:
`ops/specs/drafts/2026-05-06-redwright-agent-user-notification-comments-draft.md`

## Problem
Mention intent needs a delivery path. Without a notification manager, ticket comments can persist but users may not be alerted when an agent needs attention.

## Expected
- A notification manager should process mention-bearing ticket comments.
- The manager should create a future web inbox representation for the user.
- The manager should be able to send a Telegram message with enough description for the user.
- The notification should reference the source ticket.
- Delivery should preserve enough context for the user to understand why they were mentioned.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Define the notification event generated from a ticket mention.
- Define the minimal notification manager boundary.
- Preserve a web inbox representation even if the UI is not fully built yet.
- Add or integrate Telegram delivery only when the required user identity mapping is available.

## Validation
- Given a ticket comment with an `@user` mention, verify a notification event is produced.
- Verify the notification references the ticket and comment.
- Verify the notification can be represented for a future inbox.
- Verify Telegram delivery behavior when the user has a known Telegram identity.

## Outcome
Pending implementation.
