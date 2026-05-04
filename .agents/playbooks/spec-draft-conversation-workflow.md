# Spec Draft + Conversation Workflow

Use this playbook when a topic is in active design/brainstorming and not ready for stable specification.

## Intent

- Preserve design context across sessions.
- Keep brainstorming material in curated, editable form.
- Avoid losing decisions, tensions, and open questions.

## Artifact Pairing

For each draft in `ops/specs/drafts/`, maintain a paired conversation file in `ops/specs/conv/`.

- Draft: `ops/specs/drafts/...-draft.md`
- Conversation notes: `ops/specs/conv/...-conv.md`

Both files are living artifacts until promoted.

## Rules

1. Keep both files in English.
2. `...-draft.md` captures structured behavior/proposal.
3. `...-conv.md` captures curated discussion, not raw transcript.
4. Include `Open Questions` explicitly in both artifacts.
5. Mark provisional decisions clearly (for example: `keep`, `unsure`, `discard`).
6. Remove noise, typos, and irrelevant detours from conversation notes.
7. Keep the conversation file editable for future expansion.
8. Do not use title or heading suffixes in parentheses such as `(Draft)`.
9. Use semantic fields for state metadata (for example `Status`) only when they add operational value.
10. Add explicit cross-references: each draft must reference its conversation counterpart and vice versa.
11. Before commit, run a full consistency pass across playbook, templates, and concrete artifacts.
12. For each iteration, prefer one cohesive commit over corrective micro-commits.

## Template Locations

- `ops/templates/spec-draft-template.md`
- `ops/templates/spec-conversation-template.md`

## Promotion Path

- Iterate with drafts in `ops/specs/drafts/` and conversation notes in `ops/specs/conv/` until stable.
- Promote to `ops/specs/specs/*` once behavior and decisions are sufficiently converged.
