# RedWright Context Section Layer Normalization Draft

## Metadata

- id: `draft-2026-05-09-redwright-context-section-layer-normalization`
- status: `draft`
- selection_status: `open`
- owner: `adrianpk`
- created: `2026-05-09`
- updated: `2026-05-09`
- scope: `llm-context-sections/context-policy/request-engine`
- follow_up_kind: `hardening`
- promoted_to: `none`

## Summary

RedWright context sections need two distinct identifiers:

- `name`: the concrete identity of the section.
- `metadata.context_layer`: the normalized policy layer used by context shaping.

The context policy engine should select context by `metadata.context_layer`, not by forcing every section to be renamed to a generic policy category.

## Rationale

Concrete section names are useful for debugging, trace inspection, provider payloads, and action-specific semantics. Normalized layers are useful for policy selection because many concrete sections belong to the same policy family.

Examples:

- `ticket` and `validation_feedback` are different concrete sections, but both can belong to the `prompt` layer.
- `relevant_files` and `tests` are different concrete sections, but both can belong to the `concrete_files` layer.
- `protocol_files` and `protocol_model` are different concrete sections, but both belong to the `protocols` layer.

Renaming concrete sections to the normalized layer would lose useful distinctions. Leaving sections without normalized layer metadata makes policy pruning brittle because `RequestEngine` falls back to the concrete section name.

## Contract

Every `Redwright::LLM::ContextSection` used with a context policy should provide a valid `metadata["context_layer"]`.

The intended shape is:

```ruby
Redwright::LLM::ContextSection.new(
  name: "relevant_files",
  content: files,
  authority: "workspace_filesystem",
  metadata: {
    "context_layer" => "concrete_files"
  }
)
```

Field meanings:

- `name` identifies the specific block.
- `authority` identifies provenance and trust.
- `metadata.context_layer` identifies the normalized policy layer.

## Current Follow-Up Need

The hotfix after the context-shaping cycle restored `agent_ticket_execution` by mapping legacy sections to normalized layers. A later hardening slice should make missing or invalid `context_layer` metadata visible through tests, warnings, or diagnostics before policy pruning can silently omit critical context.
