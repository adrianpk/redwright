# Spec Draft + Conversation Workflow

Use this playbook when a topic is in active design/brainstorming and not ready for stable specification.

## Intent

- Preserve design context across sessions.
- Keep brainstorming material in curated, editable form.
- Avoid losing decisions, tensions, and open questions.

## Artifact Pairing

For each draft in `ops/specs/drafts/`, maintain a paired conversation file.

- Draft: `...-draft.md`
- Conversation notes: `...-conv.md`

Both files are living artifacts until promoted.

## Rules

1. Keep both files in English.
2. `...-draft.md` captures structured behavior/proposal.
3. `...-conv.md` captures curated discussion, not raw transcript.
4. Include `Open Questions` explicitly in both artifacts.
5. Mark provisional decisions clearly (for example: `keep`, `unsure`, `discard`).
6. Remove noise, typos, and irrelevant detours from conversation notes.
7. Keep the conversation file editable for future expansion.

## Template Locations

- `ops/templates/spec-draft-template.md`
- `ops/templates/spec-conversation-template.md`

## Promotion Path

- Iterate in `ops/specs/drafts/` until stable.
- Promote to `ops/specs/specs/*` once behavior and decisions are sufficiently converged.
