# Project New Operational Loop Behavior Conversation Notes

## Status
Living discussion

## Related Draft
`2026-05-01-project-new-operational-loop-behavior-draft.md`

## Promoted Specification
`ops/specs/specs/2026-05-01-project-new-operational-loop-behavior-spec.md`

## Purpose
Curated discussion log supporting `2026-05-01-project-new-operational-loop-behavior-draft.md`.

## Sessions

### Session 2026-05-01
#### Context
- Discussion focused on informal conversational operation from messenger surfaces (Telegram-like), not kanban auto mode.
- Runtime currently creates project directories/manifests correctly in some scenarios, but conversational behavior is not yet aligned with desired interaction quality.

#### Questions Raised
- Should `/project new` prioritize direct execution or clarification-first behavior?
- How should runtime telemetry be exposed in user responses?
- How can the system avoid re-asking details already provided by the user?
- Can a looped questioning model remain flexible while still predictable?
- Where should brainstorming context be persisted to avoid accidental context loss?

#### Candidate Answers
- Hide IDs/traces by default; expose telemetry only behind explicit debug/trace configuration.
- Use markdown code formatting when telemetry is shown in messenger outputs.
- Keep a stable questioning pattern, but avoid fixed hardcoded questions.
- Use semantic slots/priorities instead of static text prompts.
- Reuse existing persistence entities for clarification state and context carry-forward.

#### Current Convergences
- Slash commands should remain wrappers over domain operations (command-query / verb-noun style).
- A strong conversational loop is needed, but not one that asks for the sake of asking.
- Prompt-provided context must be consumed first; only blocking gaps should trigger questions.
- Internal LLM refinement loops are acceptable if user-visible questioning is reserved for real blockers.
- Messenger workflows need small increments and explicit checkpoints to reduce late-stage misalignment.

#### Open Tensions
- Default output expectation for `/project new`: scaffold-only vs functional baseline vs adaptive behavior.
- How conservative default behavior should be when confidence is moderate.
- Exact threshold for "enough context to act".

#### Provisional Decisions
- Keep exploration active; do not freeze implementation decisions yet.
- Maintain a running draft plus a curated conversation counterpart.
- Treat this pair as living artifacts; refine and edit continuously.

#### Deferred / Out of Scope
- Immediate implementation changes.
- Final protocol wording for loop control contract.
- Final migration policy for all historical drafts.

## Open Questions
- What minimum deliverable should `/project new` guarantee before asking any follow-up?
- Which fields are always blocking (if missing) versus defaultable?
- Should loop completion require explicit user confirmation before scaffold generation?
- How should "cancel" and "proceed with current context" be standardized in a cross-surface way?

## Edit Notes
- This file is intentionally curated and non-final.
- Content is condensed from brainstorming and may be revised, reordered, or removed.
