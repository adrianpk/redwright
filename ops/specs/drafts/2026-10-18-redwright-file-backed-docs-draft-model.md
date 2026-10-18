# RedWright File-Backed Specifications Data Model

## Metadata

- status: `draft`
- selection_status: `open`
- created: `2026-10-18`
- updated: `2026-10-18`
- readiness: `implemented and validated; maintainer trial pending`

## Related Draft

[File-Backed Specifications](2026-10-18-redwright-file-backed-docs-draft.md)

## Authority and Derived Storage

The project workspace establishes document ownership. File `project_id` values
are portable metadata, distinct from local Rails record IDs, and survive
editing and approval. The project document owns its body and lifecycle metadata. The database stores
a rebuildable representation for queries. Any additional file metadata must
have an explicit responsibility; it must not introduce a competing lifecycle
status or content authority.

| Concept | Authoritative representation | Possible database representation |
| --- | --- | --- |
| Document identity | Project and relative file path | Derived local record key and indexed relative path |
| Project | Owning workspace and agreed file metadata | Project association |
| Path | Current project-relative file location | Indexed relative path |
| Title | Document metadata under the agreed format | Indexed title |
| Artifact kind | Agreed layout or metadata contract | Indexed kind |
| Lifecycle status | Document metadata | Indexed status |
| Use case | Agreed portable file reference | Resolved use-case association |
| Body | Markdown document | Not stored |
| Provenance and relations | Agreed file references | Derived relationships |
| Document timestamps | Agreed document metadata | Indexed timestamps |
| Source revision | Current source contents | Fingerprint and freshness information |
| Preview | Current source contents | Optional derived excerpt |

The concrete index and serialization contract is documented in
[Specification Files](../../../docs/reference/specification-files.md).
Database refresh time must not silently become the document's authored or
modified time.

## Product Visibility

- The user-facing entity is a specification. A generic document record or
  artifact kind must not become an additional product concept in the interface.
- Draft and approved are states of the same specification in the user
  interface. Approval preserves specification identity.
- Trackers and other supporting documents are internal execution artifacts.
  Exclude them from public specification lists, authoring forms, and related
  artifact panels without discarding their data or operational relationships.
- Whether the existing generic Document persistence remains useful internally
  is an implementation decision. The visible contract does not require a new
  database hierarchy or a destructive removal of internal documents.

## Scope, Cardinality, and Authoring Sources

- Current baseline: `Project` has many use cases and documents. `UseCase` has
  many documents; `Document` has an optional use-case association.
- Agreed cardinality: one use case represents one feature and owns at most
  one dump, quiz, specification, and tracker. A tracker orders one or more
  implementation tickets. Database uniqueness and file reconciliation enforce
  singular artifact relationships.
- `corrects_use_case_id` links a corrective feature to another use case in the
  same project. Linked features and delivery history prevent destructive removal.
- Remove the previous `source_draft` requirement. Direct authoring and harness
  generation create a specification without a prerequisite draft record.
- Case slugs remain stable when display names change, preserving file-owned
  references without requiring a rewrite of every specification.
- Dumps, quizzes, and generation request/response identifiers are provenance
  where those sources actually exist. Directly authored specifications must
  not require synthetic discovery or generation references.
- RW normally creates specifications through its wrapped harness and retains
  the actual generation provenance. Manual creation is an alternative path
  using the same specification model.
- Document kind, lifecycle status, and any approval state need separate,
  explicit semantics. A manually created specification does not imply that
  implementation has been authorized.

## Generation and Approval Lifecycle

| Action | Authoring path | Resulting specification state |
| --- | --- | --- |
| Generate through wrapped harness | Normal RW generation | draft |
| Approve | Existing generated or manually authored draft | approved on the same specification |
| Save draft | Direct manual authoring | draft |
| Save and approve | Direct manual authoring | approved |

- The lifecycle status lives in the specification file and is reflected in
  the derived index. Approval does not create a separate source draft,
  duplicate specification, or approval artifact.
- Generated provenance stays attached when status changes. The approval
  action does not replace the source request or response identity.
- Generation success does not by itself set approved status, resolve tickets,
  or start execution. Any automatic approval mode remains an open policy
  decision in the parent draft.
- The serialization contract below defines this implementation. Additional
  lifecycle transitions remain open for maintainer feedback.

## Implementation Tickets and Generated Tracker

| Concept | Responsibility | Authority |
| --- | --- | --- |
| Specification | Feature or corrective-work contract within project/use-case context | Specification file |
| Implementation ticket | Actionable work and its current workflow state | The actual ticket |
| Internal tracker | Generated execution order and stable references to implementation tickets | Tracker for ordering; referenced tickets for completion |
| Tracker progress summary | Optional presentation of resolved and pending work | Derived from current referenced ticket states |

- Tracker references use stable ticket keys and must resolve to the actual
  implementation tickets. Missing references produce an explicit error.
- Do not introduce a second authoritative resolved flag or completion
  checklist in the tracker. A reopened ticket remains unresolved regardless
  of an older tracker summary.
- Keep specification lifecycle status distinct from ticket implementation
  status. A specification's approval does not mark its tickets resolved.
- Tracker generation and maintenance are internal operations. There is no
  direct web tracker editor, ordering control, deletion action, or completion
  control; implementation remains manageable through tickets in Board.
- Trackers serialize ordered ticket keys and the specification source revision.
  Current ticket states determine progress. Stale slicing cannot authorize execution.
- Ticket Markdown files own descriptions and ticket metadata. SQL indexes paths,
  source revisions, board/column and feature associations, statuses, and other
  query metadata, without a description body. Separate comments retain ticket IDs.
- Re-slicing before execution retains useful ticket IDs and keys and closes
  omitted tickets as obsolete, preserving their feature and source references.
- Starting a ticket records execution history in its file and the tracker.
  Returning it to ready does not reset that history. Regeneration and contract
  edits stay blocked; corrective work uses a linked feature.

## Serialization Contract

The document shape is YAML frontmatter followed by a Markdown body
and a `Provenance` section where sources exist.

- Specification frontmatter fields: `title`, `project_id`,
  `case_slug`, `status`, `source_request_id`, `source_response_id`, `created_at`.
- Normal harness generation produces `status: draft`; the Approve action
  changes it to `status: approved` on the same specification. Automatic
  approval is not exposed in this change.
- Internal plan/tracker serialization is not part of the public specification
  authoring format. Existing internal documents are preserved during conversion.
- Source request/response and discovery references are not universal required
  fields: manual authoring may have none. Preserve only actual provenance.

Use project-relative paths, source fingerprints, file modification times, and
file-owned relations to rebuild the derived index. Missing, malformed, or
unavailable sources produce explicit errors. Imported accepted/final statuses
remain readable alongside draft and approved.

## Queries and Indexes

- Query specifications by project, status, and use case; order by agreed
  document dates. Internal artifact kinds are not a user-facing type filter.
- Resolve an indexed project-relative path to the current file.
- Enforce uniqueness on project and relative path. Discover renames as removed
  and added paths; approval keeps the same file identity.
- Compare source fingerprints and file attributes during synchronous project
  reconciliation before Specs pages and specification queries.
- No content-search index is currently justified by the existing Docs query
  surface. Full-text search requirements remain a separate decision.

## Lifecycle and Recovery Constraints

- Reconciliation derives database state from files.
- RedWright writes update files before derived rows.
- An index failure after a successful file write must not make the database
  copy authoritative.
- Missing files, invalid metadata, and stale edits need explicit handling;
  neither cached content nor defaults may silently repair the source file.
- Typed relationships are serialized as project-relative file paths and
  relation types. The old `source_draft` foreign key is removed; legacy
  relations are exported into file metadata before the index is rebuilt.

## Open Questions

The parent draft records remaining policy and interaction questions for the
maintainer trial. The file, index, and conversion contracts above define this
implementation. Automated validation passed; the maintainer trial remains open.

## Schema and Example Continuity

- Edit the applicable existing migrations and schema to represent the intended
  model from the start; do not append corrective migrations for this change.
- Update fixtures and example artifact setup to the agreed representation.
- Preserve Factory's existing tickets, artifacts, lifecycle state, and
  relationships when moving database-only documents to files and rebuilding
  derived indexes.
- Fresh database creation and preservation of the existing example are
  separate acceptance cases. A successful fresh seed does not establish that
  existing work survived the transition.
