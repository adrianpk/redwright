---
id: TKT-20260506080309
title: Scope quiz index to current project
status: solved
kind: task
severity: medium
priority: normal
scope: web
tags: quiz, project-scope, web
source: chat
reported_at: 2026-05-06T08:03:09Z
ready_at: 2026-05-06T08:46:02Z
started_at: 2026-05-06T13:10:44Z
reviewed_at: 2026-05-06T13:12:20Z
closed_at: 2026-05-06T14:04:35Z
resolution: fixed
owner:
branch: fix/ticket-20260506080309-scope-quiz-index
pr: https://codeberg.org/adrianpk/redwright/pulls/325
commits:
  - d731c1c
  - 94b24d3
  - 60f7086
  - d1f7763
  - 8f6152f
---

## Context
The Quizzes view currently shows cards for each project.

RedWright already has a project selector in the navigation bar, so showing project cards inside the Quizzes view duplicates project selection.

## Problem
The Quizzes view starts at a cross-project card selection layer even though the current project is already established by the navigation selector.

This makes the view feel less direct and creates an unnecessary extra choice.

## Expected
- Entering the Quizzes view should use the currently selected project.
- The view should go directly to quiz/question cards for that project.
- General project questions should appear as cards without a use-case row.
- Each use case should have its own card or card group for associated questions.
- Project selection should remain handled by the global project selector.

## Actual
- The Quizzes view presents project cards even though a project selector already exists in the navigation.

## Fix Strategy
- Inspect the current Quizzes index route/view.
- Remove or bypass the project-card landing layer when a current project is selected.
- Render project-level question cards and use-case cards for the selected project.
- Preserve behavior for missing/no current project if needed.

## Validation
- Select a project from the navigation.
- Open Quizzes and verify it shows that project's quiz cards directly.
- Verify project-level questions render without a use-case row.
- Verify use-case question groups render as use-case cards.

## Outcome
Implemented and merged in PR #325.
