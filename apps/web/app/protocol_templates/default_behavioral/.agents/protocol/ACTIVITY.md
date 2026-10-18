# Acta Activity Protocol

This document defines the global activity journal, retrieval, and reporting
contract. Invoke the installed `acta` CLI directly. A skill can orchestrate
Acta, but it must not maintain a separate activity ledger.

## Authority

- Use Acta as the required interface for recorded activity history, milestone
  lookup, cross-project summaries, and timesheet preparation.
- Query Acta before using an LLM to summarize or interpret completed work. Do
  not reconstruct an activity ledger from Git logs, pull requests, trackers,
  reports, chat history, or filesystem inspection when Acta can answer the
  question.
- Use Git, the canonical forge, trackers, and external systems only to verify
  their current mutable state or to perform the requested operation. They do
  not replace Acta as the activity journal.
- Treat Acta output as recorded evidence, not proof that unrecorded work did
  not occur. Do not infer missing activity or duration.
- If Acta is unavailable or cannot return a complete bounded result, report
  that condition. Do not silently substitute a manually reconstructed
  activity history.

## Retrieve and Report

- Use `acta report --from <YYYY-MM-DD> --to <YYYY-MM-DD> --timezone
  Europe/Warsaw --limit 1000 --json` for a bounded calendar summary or
  timesheet input.
- Use `acta search --scope <scope> --query <text> --limit <count> --json` for
  discovery. Add type, occurrence-time, duration, source, harness, model,
  commit, or pull-request filters when they narrow the question.
- Use `acta show --id <event-id> --json` for the complete effective record.
  Add `--raw` only when the exact stored chain member is required.
- Check `truncated` in structured search and report output. Narrow the scope,
  time range, type, or query until the result is complete.
- Use `acta verify` or `acta verify --full` when journal integrity is relevant
  or a result is unexpectedly absent.
- Give the LLM only the bounded Acta results needed for interpretation. Keep
  recorded facts distinct from conclusions or recommendations.

## Record Completed Activity

- The authority to perform a task includes recording its significant completed
  outcome in Acta unless the user explicitly opts out. Record outcomes, not
  transcripts or work in progress.
- Use the most specific peer event type. A commit has no special status and is
  not a prerequisite for another event.
- After each completed non-trivial commit, immediately run `acta record commit
  [flags] [summary]` while that commit is still `HEAD`.
- After creating, materially reviewing, merging, or closing a pull request,
  immediately run `acta record pull-request --forge <url> --repository
  <owner/name> --number <number> --action <opened|reviewed|merged|closed>
  [flags] <summary>`. Record the transition only after it succeeds or is
  verified on the canonical forge.
- Use `acta record worklog --duration <minutes> [flags] <summary>` only when
  the duration was supplied or approved by the user. Never derive duration
  from timestamps, commits, event counts, or elapsed agent execution time.
- Use `acta record note [flags] <summary>` for a significant completed non-Git
  outcome when no more specific event type applies. This includes operational,
  infrastructure, investigation, coordination, and decision outcomes.
- Add a concise summary when the underlying artifact does not contain useful
  retrieval terms. Supply scope, references, occurrence time, and provenance
  only when their values are known reliably.
- Omit abandoned or work-in-progress activity, generated-only changes,
  punctuation-only changes, isolated formatting, and other trivial events.
- Never record credentials, tokens, personal data, prompts, conversation
  content, hidden reasoning, diffs, patches, file contents, environment
  variables, or terminal history.

## Failure Handling

- Never edit the Acta journal files directly.
- If a required record fails, preserve the completed underlying work, report
  the Acta failure, and retry only after checking the service and journal with
  the supported Acta commands.
- Do not replace a failed Acta record with a note in a tracker, report, chat,
  or another parallel activity log.
