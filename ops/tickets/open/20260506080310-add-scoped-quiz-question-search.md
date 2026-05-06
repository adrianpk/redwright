---
id: TKT-20260506080310
title: Add scoped quiz question search
status: open
kind: unclassified
severity: unclassified
priority: unclassified
scope: unclassified
tags: quiz, search, turbo-streams
source: chat
reported_at: 2026-05-06T08:03:09Z
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
Quiz cards may include both general project questions and use-case-specific questions.

Users need a fast way to find a specific question and jump to it without manually scanning all cards.

## Problem
The Quizzes view does not provide a quick search/jump interaction for questions across project-level and use-case-level cards.

## Expected
- A search control should appear above quiz cards.
- The search should be suitable for Turbo Streams-style incremental results if that fits the existing Rails patterns.
- In the project quiz view, search should cover both project-level questions and use-case questions for the current project.
- In a use-case-specific quiz view, search should be scoped to that use case.
- Search results should allow direct jump/navigation to the matching question or card.
- Search should not require the user to know whether a question is general or use-case-specific.

## Actual
- To be verified during triage and implementation.

## Fix Strategy
- Identify current quiz routes and card markup.
- Add a question search endpoint or reuse an existing query path.
- Add an incremental search UI above quiz cards.
- Add stable anchors or navigation targets for direct jumps to questions/cards.
- Respect project scope and use-case scope depending on the current view.

## Validation
- Search for a project-level question from the project quiz view and jump to it.
- Search for a use-case question from the project quiz view and jump to it.
- Open a use-case quiz view and verify search results are scoped to that use case.
- Verify search updates without disrupting the current card layout.

## Outcome
Pending implementation.
