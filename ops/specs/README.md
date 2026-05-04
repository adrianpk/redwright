# Specifications Ledger

This directory stores specification artifacts produced from alignment cycles.

File types:

- `drafts/*-proto-spec-draft.md`: working specification drafts derived from discovery and Q&A.
- `conv/*-conv.md`: curated conversation notes paired with a draft (discussion counterpart).
- `specs/*-proto-spec.md`: refined proto-spec ready for formal execution planning.
- `specs/*-spec.md`: stabilized, review-ready specification for implementation.

Rules:

- use dated filenames: `YYYY-MM-DD-<topic>-proto-spec-draft.md`, `YYYY-MM-DD-<topic>-conv.md`, `YYYY-MM-DD-<topic>-proto-spec.md`, and `YYYY-MM-DD-<topic>-spec.md`
- keep language in English
- for active drafting topics, maintain both a draft under `drafts/` and its conversation counterpart under `conv/`
- update related `ops/plans/*` and `ops/trackers/*` when status changes

Templates:

- `ops/templates/spec-draft-template.md`
- `ops/templates/spec-conversation-template.md`
