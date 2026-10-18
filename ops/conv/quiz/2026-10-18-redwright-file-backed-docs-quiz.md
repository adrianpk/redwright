# RedWright File-Backed Specifications Discussion Notes

## Status

Living discussion; open. Curated from the current conversation, without a
separate questionnaire session.

## Related Draft

[File-Backed Specifications](../../specs/drafts/2026-10-18-redwright-file-backed-docs-draft.md)

## Session 2026-10-18

### Questions Raised

- Why store formal documents in the database if they also exist in the project?
- Can document status live in the document itself?
- Does Docs need full document bodies in the database for search or rendering?
- What happens when someone edits a file outside RedWright?
- Which discovery steps should be optional when creating a specification?
- Does a use case contain one specification or several?
- Should the user manage a generic catalogue of documents or an explicit
  specification section?
- Should implementation completion belong to tickets or to a tracker checklist?
- How can generated specifications be approved without treating manual
  document creation as the normal workflow?

### Current Convergences

- The real project file must be the source of truth.
- Document lifecycle status can live in document metadata.
- Persistence can remain useful as a fast, rebuildable Rails query index.
- Before this change, Docs used database content for listing, previews, reading, editing,
  and promotion; its queries do not implement content search.
- Rails can render file content while using Active Record for indexed lists.
- Saving both representations without detecting external file changes leaves
  a stale-copy problem. Rails convenience alone does not resolve it.
- Normalize the document format and describe the resulting contract on its
  own terms.
- Keep artifact creation simple and reuse existing behavior when sufficient.
- Project context supplies the main direction. An optional dump captures
  working ideas and can focus a quiz. A quiz must also start without a dump
  and actively elicit missing feature decisions.
- Assisted generation uses project context, available dump material, and quiz
  decisions to produce a specification of the understood feature.
- Most specifications should be created by RW through its wrapped harness.
  The user should not need to create an empty document or paste harness output.
- Direct manual specification authoring must work without a dump, quiz, or
  separate draft artifact; it is an alternative to the normal generated path.
- Rewrite applicable existing migrations instead of adding corrective ones.
- Factory must remain usable with its existing tickets and other artifacts;
  rewriting the schema does not authorize resetting that data.
- Replace the visible Docs concept with Specs. This section manages
  specifications only; trackers and other supporting documents are internal
  and invisible to users.
- With the existing entries, navigation should read Cases, Dumps, Quizzes,
  Specs, Board, Protocol, Settings.
- Draft and approved are states of the same specification. A generated draft
  can be approved with one action that updates its file metadata and index
  without copying it into a separate document.
- Manual authoring can offer Save draft and Save and approve. Approval does
  not by itself start ticket execution.
- A use case can group multiple features. Features and corrective work can
  have distinct specifications; the one-to-many relationship is now agreed.
- Implementation belongs in tickets. The generated tracker organizes execution
  order and references those tickets, whose states determine what is resolved.
- Tracker summaries must derive from tickets rather than maintain a separate
  source of implementation completion.
- The tracker is an internal generated artifact without direct web viewing
  or management. The user manages implementation through tickets in Board.

### Verified Baseline Before This Change

- A use case can contain multiple specifications through its document
  association; the schema has no one-to-one uniqueness rule for them.
- The previous document workflow required a source draft for a specification,
  which conflicts with direct specification authoring.
- The quiz could start without a dump. Its previous question-provider input
  did not include dump content; this implementation adds optional dump context.
- Navigation previously said Docs, and the document interface exposed Drafts,
  Specs, and Plan Trackers as separate categories.

### Provisional Decisions

- `keep`: file authority and support for external file edits.
- `keep`: lifecycle metadata in the document.
- `keep`: a derived database index remains an available design choice.
- `keep`: metadata/path indexes without database bodies or cached previews.
- `keep`: synchronous project reconciliation for Specs reads and revision
  checks for file writes; agent context reads target-workspace files.
- `keep`: namespaced Markdown envelopes, file-owned lifecycle metadata, and
  draft-to-approved changes on the same specification.
- `keep`: optional dumps, quizzes without dumps, and direct specification
  authoring as distinct supported entry paths.
- `keep`: existing migration edits and continuity of the Factory example.
- `keep`: Specs as the explicit user-facing section, with trackers and other
  supporting documents kept internal.
- `keep`: RW generation through the wrapped harness as the primary authoring
  path, with direct manual authoring also supported.
- `keep`: normal generation produces a draft; one Approve action updates that
  same specification to approved while retaining identity and provenance.
- `unsure`: whether an explicitly selected automatic approval mode is useful,
  and what authorization and revision rules should govern it.
- `keep`: multiple specifications per use case for features and corrective work.
- `keep`: tickets own implementation status; the generated internal tracker
  orders execution and references those same tickets.
- `keep`: no direct web tracker management.
- `keep`: internal tracker generation from ordered ticket keys; current ticket
  state drives pending work, and missing references are explicit errors.

## Open Questions

The [draft's open questions](../../specs/drafts/2026-10-18-redwright-file-backed-docs-draft.md#open-questions)
remain active. The maintainer requested an evolving specification and has
additional functionality to review. No stabilization or implementation
planning has been requested.
