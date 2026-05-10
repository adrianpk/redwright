---
name: repo-changelog
description: Generate and update curated RedWright repository changelogs from Git history, pull requests, ops specs, plans, trackers, and release-alignment context. Use when the user asks to create, backfill, refresh, review, or prepare CHANGELOG.md, release notes, notable changes, or dev-to-main release summaries for this repository.
---

# Repository Changelog

Use this skill inside RedWright repositories when creating or updating
`CHANGELOG.md` or release notes.

## Output Rules

1. Put the canonical changelog at repository root: `CHANGELOG.md`.
2. Keep changelog content in English.
3. Use the spirit of Keep a Changelog: `Added`, `Changed`, `Fixed`, `Removed`,
   `Documentation`, and `Tests`.
4. Do not treat the changelog as Diataxis documentation. It is release/history
   metadata, not a tutorial, how-to, explanation, or reference document.
5. Prefer user/feature-oriented entries over commit-level entries.
6. Preserve relevant architecture, workflow, and operations changes when they
   affect future maintenance or repository process.
7. Do not include conversational noise, PR body edits, typo-only changes, or
   mechanical tracker churn unless they belong to a broader notable change.
8. Default to concise release notes. For a normal feature cycle, capture the
   user-visible feature in one or two bullets and add only directly relevant
   fixes. Do not expand every slice, tracker, validation run, doc update, or
   implementation mechanism into changelog entries.
9. Treat docs, tests, and ops artifacts as supporting evidence by default, not
   changelog entries. Mention them only when they are themselves the user-facing
   deliverable or materially change how users operate RedWright.

## Startup

1. Inspect whether `CHANGELOG.md` already exists.
2. Read recent or requested range history with `git log --reverse --date=short`.
3. Inspect PR titles when available, especially release-alignment PRs and slice
   PRs.
4. Inspect ops artifacts only as needed:
   - `ops/specs/specs/`
   - `ops/specs/drafts/`
   - `ops/plans/`
   - `ops/trackers/`
   - `ops/conv/quiz/`
5. If the user requests a release PR summary, compare the relevant branches with
   `git log base..head` and `git diff --stat base..head`.

## Backfill Workflow

Use this workflow when the changelog is missing or the user asks for history
from the beginning.

1. Build a chronological map from the first commit to current `HEAD`.
2. Group commits into product/workflow cycles by date, branch naming, PR titles,
   slice markers, ops trackers, and feature area.
3. Write entries by date or release section, not by commit.
4. Keep each date section focused on notable capabilities and behavior changes.
5. Add `[Unreleased]` at the top for work not yet released to `main`.
6. Keep the first draft reviewable; do not commit unless the user explicitly
   asks.

## Update Workflow

Use this workflow when `CHANGELOG.md` already exists.

1. Identify the last covered commit/date/range.
2. Compare the uncovered range.
3. Add entries under `[Unreleased]` unless the user gives a version or date.
4. Preserve the file's existing style unless it conflicts with this skill.
5. Prefer appending concise bullets to existing categories over creating a new
   section for every commit.

## Entry Granularity

Include:

- New user-visible capabilities.
- Behavior changes that affect how RedWright is used.
- Architecture boundaries that change future implementation paths.
- Removed or deprecated models, workflows, UI surfaces, commands, or APIs.
- New repository workflows, skills, tickets, ops processes, or release gates
  only when users or maintainers must act differently.

Avoid:

- One bullet per commit.
- One bullet per slice.
- Internal variable renames.
- PR title/body cleanup.
- Tracker checkbox updates unless they close a notable cycle.
- Repeated "record PR", "mark merged", or "refresh badge" entries unless they
  are part of a release/documentation change.
- Listing validation commands, test files, internal docs, specs, plans, or
  trackers unless the user specifically asks for a process audit or release
  evidence pack.

## Category Guidance

- `Added`: new capabilities, screens, flows, models, commands, skills, and
  workflows.
- `Changed`: behavior/model shifts, architecture realignment, UX hierarchy
  changes, and policy changes.
- `Fixed`: bugs, regressions, incorrect semantics, broken flows, and guardrails.
- `Removed`: deleted behavior, models, commands, UI, or compatibility paths.
- `Documentation`: specs, drafts, plans, trackers, guides, README/gallery, ADRs,
  playbooks, and release notes.
- `Tests`: coverage that validates a new or corrected contract.

Use `Documentation` and `Tests` sparingly. A feature implementation usually
does not need either section in the changelog just because docs and tests were
changed.

## Release PR Summaries

For `dev -> main` release PRs:

1. Use the PR title style already established in the repository.
2. Prefer `chore(release): align dev with main` unless the repository has moved
   to a newer convention.
3. Use PR sections:
   - `Summary`
   - `Changes`
   - `Validation`
4. Summarize branch-level changes by cycle/capability, not by commit.
5. Mention changelog updates explicitly when `CHANGELOG.md` changes.

## Validation

For changelog-only changes:

- Run `git diff --check`.
- Inspect Markdown headings with `rg -n "^## |^### " CHANGELOG.md`.
- No application test suite is required unless code changed.

Report clearly when validation is documentation-only.
