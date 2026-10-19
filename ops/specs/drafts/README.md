# Specification Drafts

This directory stores editable specification drafts.

Use `selection_status` metadata to decide whether a draft should be considered for future improvement work:

- `open`: selectable for future spec, plan, ticket, or implementation work.
- `closed`: already promoted, implemented, superseded, or otherwise not a current improvement candidate.

## Open Improvement Drafts

These recent drafts are intentionally visible as selectable follow-up work:

- `2026-05-09-redwright-agent-sandboxed-execution-backend-draft.md`
  - selection_status: `open`
  - follow_up_kind: `runtime_sandboxing`
- `2026-05-09-redwright-context-section-layer-normalization-draft.md`
  - selection_status: `open`
  - follow_up_kind: `hardening`
- `2026-05-09-redwright-semantic-code-context-enrichment-draft.md`
  - selection_status: `open`
  - follow_up_kind: `research_and_hardening`

## Closed Recent Drafts

- Pi Harness
  - selection_status: `closed`
  - promoted_to: [Pi Harness](../specs/2026-10-19-redwright-pi-harness-spec.md)
  - approved_plan: [seven-slice delivery](../../plans/2026-10-19-redwright-pi-harness-cycle-plan.md)

These recent drafts are not active selection candidates because they already moved through a spec and delivery cycle:

- `2026-05-09-redwright-agent-ticket-llm-context-shaping-draft.md`
  - selection_status: `closed`
  - promoted_to: `ops/specs/specs/2026-05-09-redwright-agent-ticket-llm-context-shaping-spec.md`
  - completed_tracker: `ops/trackers/2026-05-09-redwright-llm-context-shaping-cycle-tracker.md`

## Search Hints

Find open drafts:

```sh
rg -n '^- selection_status: `open`' ops/specs/drafts
```

Find closed drafts:

```sh
rg -n '^- selection_status: `closed`' ops/specs/drafts
```
