# Lore Knowledge Protocol

This document defines global retrieval and capture of durable operational
knowledge. Invoke the installed `lore` CLI directly. Lore is a knowledge store,
not an activity journal, transcript archive, progress log, or replacement for
repository documentation.

## Authority and Boundaries

- Query Lore when applicable stored knowledge could avoid a costly repeated
  inference about a project, repository, system, host, technology, or client.
- Treat retrieved entries as reusable guidance, not proof of current mutable
  state. Verify drift-prone facts against live state or authoritative
  documentation when practical.
- Use `protocol/ACTIVITY.md` and Acta for completed activity, milestones,
  summaries, and timesheets. Do not record activity events in Lore.
- Do not use Lore instead of specifications, plans, trackers, reports, source
  documentation, or live system inspection when those artifacts own the
  current contract or state.
- Autonomous capture at agent discretion is the default. The authority to
  perform a task includes recording reusable knowledge discovered during that
  task unless the user opts out.
- The agent decides what is worth preserving from likely reuse value,
  reconstruction cost, applicability, and expected durability. Do not ask for
  confirmation before an autonomous non-destructive capture.
- Explicit capture remains available when the user asks to preserve an item
  that the agent did not select autonomously. The request authorizes capture
  subject to privacy and safety boundaries; do not ask for redundant
  confirmation.
- Autonomous capture may create an entry or revise an overlapping entry through
  Lore's append-only revision model. Archive, invalidate, restore, and purge
  require explicit user authorization.

## Retrieve

- Use `lore search --text <text> --context <context> --limit <count> --json`
  for bounded discovery. Omit filters that do not improve relevance.
- Prefer `project:<name>` with the canonical lowercase project directory name.
  Add `repository`, `system`, `host`, `technology`, or `client` contexts only
  when that dimension changes applicability.
- When an entry intentionally has no project context, invoke Lore outside a Git
  worktree. Lore can infer project and repository context from the current
  worktree even when another context type is supplied. Inspect mutation output
  for unintended inferred context.
- Check `truncated` in search output. Narrow the text, contexts, labels, kinds,
  statuses, or recorded-time range until the result is complete.
- Use `lore show --id <entry-id> --json` for the complete effective entry. Add
  `--history` only when revision history matters.
- Use `lore verify --json` when store integrity is relevant or expected
  knowledge is unexpectedly absent.
- Provide only the bounded entries needed for the active reasoning task. Keep
  retrieved content distinct from current verification and inference.

## Record

- Evaluate reusable knowledge while working and again before completing the
  task. Capture selected knowledge while its context is current.
- Search for overlapping effective knowledge before creating another entry.
- Revise an overlapping entry when newly verified knowledge updates the same
  reusable item. Create a new entry when the knowledge has a distinct owner or
  applicability boundary.
- Choose the narrowest kind: `procedure`, `fact`, `warning`, or `reference`.
- Curate one reusable item with a concise title and self-contained body. Store
  the knowledge, not the conversation that produced it.
- Use the narrowest applicable contexts. Keep labels sparse and add references
  only when they materially support retrieval or verification.
- Set `--verified-at` only when the recorded content was actually verified at
  that time.
- For agent-authored capture, use `--source agent --harness codex`. Add model
  provenance only when it is reliably available and useful.
- Strong capture signals include a non-obvious recovery procedure, hard
  constraint, recurring failure mode, expensive discovery, durable reference,
  or another insight likely to prevent meaningful repeated work. These signals
  guide agent judgment; they are not an exhaustive eligibility list.
- Do not capture merely because a result is correct, recent, or available.
- Exclude routine commands, transient status, obvious documentation, progress
  narration, prompts, transcripts, hidden reasoning, diffs, patches, terminal
  history, and unnecessary source content.
- Never store credentials, tokens, secrets, personal data, or incidental local
  identifiers. Use a host or client context only when it is necessary for
  applicability.

Example:

```text
lore record procedure \
  --title "<concise title>" \
  --body "<curated technical knowledge>" \
  --context "project:<name>" \
  --source agent \
  --harness codex \
  --json
```

## Revision and Lifecycle

- Use `lore revise` for an authorized or autonomously qualifying update to an
  existing entry. Preserve the established kind and supply a concise reason.
- With explicit authorization, use `archive` for valid knowledge that should
  leave normal search, `invalidate` for knowledge known to be incorrect, and
  `restore` when an entry should become active again.
- Treat `lore review` as read-only candidate discovery. A review result does not
  authorize a mutation.
- Treat `lore purge` as destructive. Require explicit purge authorization, run
  the dry run first, report the selected revision chains, and confirm only the
  reviewed selection.

## Failure Handling

- Never edit Lore storage files directly.
- If retrieval is unavailable or incomplete, report the limitation when it
  affects confidence and continue from authoritative live evidence where
  possible. Do not construct a parallel knowledge store.
- If an authorized record or revision fails, preserve the underlying work,
  report the failure, and inspect service health with supported Lore commands
  before retrying.
