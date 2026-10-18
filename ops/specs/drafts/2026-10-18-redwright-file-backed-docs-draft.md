# RedWright File-Backed Specifications

## Metadata

- id: `draft-2026-10-18-redwright-file-backed-docs`
- status: `draft`
- selection_status: `open`
- created: `2026-10-18`
- updated: `2026-10-18`
- scope: `specifications/authoring-storage-and-ticket-execution`
- promoted_to: `none`
- readiness: `implemented and validated; maintainer trial and PR review pending`

## Related Artifacts

- [Discussion notes](../../conv/quiz/2026-10-18-redwright-file-backed-docs-quiz.md)
- [Provisional data model](2026-10-18-redwright-file-backed-docs-draft-model.md)
- [Existing document contract](../specs/2026-05-01-redwright-document-canvas-and-ticket-reference-model-spec.md)
- [Existing use-case context contract](../specs/2026-05-07-redwright-ticket-use-case-formal-context-refactor-spec.md)

## Purpose and Status

Provide a simple, understandable way to create artifacts that guide development.
Expose specifications through an explicit Specs interface, replacing the generic
Docs surface. Keep project specification files as the source of truth and the
database available for efficient Rails queries without creating an independent
document store that can contradict those files. Trackers and supporting
documents remain internal artifacts, invisible to the user.

This is a living draft. It records the current agreements and leaves remaining
behavior open for maintainer review. Implementation was authorized after the
design round. Automated validation passed; the manual trial and PR review
remain pending.

## Baseline Before This Change

- Docs stores document titles and complete bodies in the database.
- The web interface lists drafts, specifications, and combined plan trackers.
  Drafts are editable; specifications and plan trackers are read-only there.
- The navigation entry is currently Docs. The existing document surface mixes
  user specifications and execution-support documents.
- Promotion creates a separate specification record copied from a draft and
  preserves their relationship.
- Creating a specification currently requires a source draft. Direct manual
  specification creation is not supported by the current document workflow.
- A use case has many documents, including specifications. A document belongs
  to one project and optionally one use case. There is no one-spec-per-use-case
  uniqueness constraint.
- A quiz can start from project or use-case context without a dump. Its current
  question-provider input does not include dump content, so optional dump
  support in the desired workflow still needs to be checked and connected.
- Docs lists by project and artifact type, orders by record timestamps, and
  renders titles, previews, and document bodies from database records.
- The document query handler filters by project and type. It does not provide
  document-content search.
- Agent context selects documents by metadata and policy. Its additional
  repository-file reader is separate from the Docs web interface.

Implementation references:
[Document](../../../apps/web/app/models/document.rb),
[DocumentsController](../../../apps/web/app/controllers/documents_controller.rb),
[document commands and queries](../../../apps/web/app/services/document_management/command_query_handlers.rb),
and [agent document context](../../../apps/web/app/services/agent_ticket_execution/context_section_providers.rb).
Additional references:
[UseCase](../../../apps/web/app/models/use_case.rb),
[quiz controller](../../../apps/web/app/controllers/project_quizzes_controller.rb),
[quiz runtime](../../../apps/web/app/services/quiz_loops/runtime.rb), and
[quiz question provider](../../../apps/web/app/services/quiz_loops/question_provider.rb).

## Agreed Direction

### Specification-Only Interface

- Name the navigation entry and the corresponding user-facing section Specs.
- Replace the generic document canvas with a specification-focused list,
  detail view, and authoring workflow. Do not present artifact-type choices
  such as Drafts or Plan Trackers as separate user-managed categories.
- Trackers and other supporting documents remain internal. They must not
  appear as user-managed content in navigation, listings, forms, or related
  artifact panels. Their existing data and operational use must be preserved.
- Present draft and approved as states of the same specification within Specs.
  Approval does not create a second artifact or a separate document category.
- Preserve the relative navigation order for shared entries. With the current
  set of entries, the target order is:

```text
Cases -> Dumps -> Quizzes -> Specs -> Board -> Protocol -> Settings
```

### Simple Artifact Authoring

- Reuse existing behavior where it already meets this contract. Simplification
  is the goal; existing capabilities do not need replacement merely to adopt
  a new storage representation.
- A use case represents one feature. It owns at most one dump, one quiz, one
  specification, and one tracker. Its tracker references one or more tickets.
  Corrective work gets a separate use case linked to the original feature.
- Dump and quiz are optional recommendations, without a mandatory discovery
  gate. A directly authored specification is a supported starting point.
- A specification captures a sufficiently understood feature: its purpose,
  relevant decisions, scope, expected behavior, and acceptance criteria.
- Project context supplies the main product and engineering direction. The
  selected use case supplies the feature context where applicable.
- A dump is optional. It captures the user's working ideas and, when available,
  helps focus subsequent quiz questions.
- A quiz must work without a preceding dump. Starting from project and
  use-case context, it must actively elicit missing decisions and clarify
  ambiguity through focused questions and follow-ups.
- RW is expected to create most specifications through its wrapped harness.
  This is the primary authoring path: RW supplies project context, relevant
  dump material when present, and the quiz's captured decisions to the harness
  and persists the resulting specification file.
- A user who already understands the feature must be able to create and edit
  a detailed specification directly, without first creating a dump, quiz, or
  separate draft artifact. Manual writing is an alternative to normal harness
  generation, not a prerequisite for it.

The intended entry paths are:

```text
Project context + optional dump + optional quiz
    -> RW through wrapped harness -> spec(status=draft)
    -> user approves -> same spec(status=approved)

Project context + user-authored content -> directly authored specification
```

### Simple Generation and Approval

- In the normal generated path, RW produces the specification as a draft and
  makes it available in Specs. The user does not need to create an empty
  document, copy harness output, or fill in a manual creation form first.
- Provide one Approve action on that generated specification. It changes
  `status: draft` to `status: approved` in the same authoritative file and
  refreshes the derived index while preserving document identity and provenance.
- Review and revision operate on that specification. Do not require a second
  draft artifact, a separate approval document, or repeated discovery steps
  merely to approve a specification that is already clear.
- For direct manual authoring, provide Save draft and Save and approve as
  alternatives. Both authoring paths use the same specification lifecycle.
- Successful harness generation is distinct from approval. Any mode that
  bypasses the normal user approval action still requires an explicit policy
  decision; it is not implied by using the harness.
- Approval makes the specification ready to organize implementation. Starting
  ticket execution remains a separate action.

### Feature Regeneration and Execution Boundary

- Regenerate the same specification, preserving its identity and path. Include
  its authored content, current project context, latest dump, and quiz answers.
  The result becomes draft and invalidates prior slicing.
- Once the revised specification is approved, Build tickets explicitly runs
  slicing through the wrapped harness and rebuilds the internal tracker.
- Before execution starts, retained work keeps its ticket key and record ID.
  New work gets new tickets. Omitted work closes with resolution obsolete,
  retaining its feature, specification, tracker, and history.
- The first execution start permanently protects the specification and tracker.
  Returning a ticket to ready, closing it, or archiving it does not enable
  regeneration. This boundary also applies to manual edits and APIs.
- Further contract changes use a linked corrective use case. Discovery may
  continue on the existing dump and quiz after execution starts.
- Source revision checks and a feature lock fence regeneration, slicing, and
  execution starts. Outdated or incomplete slicing cannot authorize execution.

### Ticket-Owned Implementation and Internal Tracking

- Tickets carry the implementation work for a specification. Their actual
  workflow state determines which work is resolved and which remains pending.
- Generate an internal tracker that organizes execution order and references
  the actual implementation tickets through stable identifiers.
- Use the referenced tickets' current state when determining remaining work.
  A tracker must not maintain an independent, authoritative completion
  checklist that can contradict ticket state.
- If the tracker includes completion summaries, derive them from its tickets.
  A resolved or reopened ticket must not require an independent manual tracker
  update to establish its implementation state.
- The tracker remains a generated internal artifact. Provide no direct web
  surface to view, create, edit, reorder, delete, or mark completion in it.
- The user manages implementation through tickets in Board. Tracker ordering
  and ticket completion are separate responsibilities; editing a tracker is
  not a way to resolve implementation work.

### File Authority

- The actual project document is authoritative for its content and document
  lifecycle metadata, including its status.
- Editing a document outside RedWright is a valid operation. RedWright must
  recognize that change rather than restore an older database copy.
- Use the Markdown and metadata format defined in the model companion and
  [Specification Files](../../../docs/reference/specification-files.md).
- Ticket files own their Markdown bodies, workflow state, timestamps, and
  feature/specification/tracker references. SQL indexes metadata and paths
  without a description body. Comments remain separate records.

### Database Role

- Persistence may remain as a derived index for project, path, title, kind,
  status, use-case association, and other agreed query metadata.
- That index must be rebuildable from the project's document files and any
  explicitly agreed file metadata. It must not own otherwise unrecoverable
  document state.
- Store metadata and paths in the database, without document bodies or cached
  previews. Read full content from the corresponding file.
- Rails rendering does not require an authoritative database body: list pages
  can query the index and document pages can read the corresponding file.

### External Changes and Writes

- Reconcile the selected project synchronously before Specs pages and
  specification queries. Detect external additions, modifications, and
  deletions. Agent document context reads the active target workspace directly.
- An index refresh must not rewrite the source document merely to make it
  match cached state.
- RedWright edits must persist the authoritative file before updating its
  derived database state.
- If a file write succeeds but the index update fails, preserve the file and
  make the index recoverable from it. Do not treat the two writes as one atomic
  database transaction.

### Schema History and Existing Example Data

- Rewrite the applicable existing migrations to express the intended schema
  from the start. Do not append corrective migrations for this change.
- Keep the schema, fixtures, and example artifact setup consistent with that
  intended representation.
- Factory must remain operational with its existing tickets and other
  artifacts, including their content, state, and relationships.
- Rewriting migration history does not authorize erasing the running example
  database or replacing existing work with freshly seeded records. The data
  transition must preserve the existing example, not just recreate a similar
  empty project.

## Implementation Decisions

- New artifacts use the namespaced Markdown envelope and frontmatter described
  in [Specification Files](../../../docs/reference/specification-files.md).
  Existing operational paths remain discoverable.
- A project-relative path identifies a file. Web approval preserves its path
  and index record. External renames are discovered as removed and added paths;
  references must be updated when renaming files.
- Keep case slugs stable when case names change so file references remain
  valid. Discovery resolves the existing case by its current name.
- Generated specifications use the local wrapped harness and a title/body output
  contract. The user can focus a particular feature or corrective change. The
  wrapper records actual provenance and leaves approval to the user.
- Saving a revision as a draft returns it to review. Save and approve approves
  the revision explicitly. Automatic approval is not exposed in this change.
- Build tickets runs bounded wrapped-harness slicing and publishes the internal
  tracker after updating actual ticket files. Failed rebuilding leaves planning
  unavailable for execution until repaired. Approval alone does not generate
  tickets or start execution.
- Internal setup/alignment summaries are file-backed reports, separate from
  user specifications. Setup creates an owned workspace for generated
  placeholder project paths before writing those files.
- Prepare existing data in a separate database built from the original
  migrations. Preserve domain rows, document bodies, legacy IDs, and relations;
  do not reset the existing example database.

## Acceptance Criteria

These criteria define the implemented scope for maintainer review:

1. An external change to a document's content or lifecycle status is reflected
   under the agreed freshness rule without a database edit.
2. Rebuilding the document index from the agreed project files preserves the
   document information and relationships covered by this contract.
3. Opening a document and using it as agent context resolve the same project
   file revision, subject to changes made between the two operations.
4. A RedWright edit updates the file, and later indexing cannot restore an
   older database body over that edit.
5. An externally removed document is not silently recreated from a cached row.
6. A user can start a quiz without a dump and receive questions aimed at
   clarifying the feature and eliciting decisions from the available context.
7. When relevant dump material exists, the quiz and generated specification
   can use it alongside project context and captured quiz decisions.
8. A user can author a specification directly without prerequisite discovery
   artifacts or a separate draft document.
9. The applicable original migrations describe the resulting schema without
   new corrective migrations, and fixtures match that schema.
10. Factory's existing tickets and artifacts remain accessible and usable
    after the storage transition; their content, state, and relationships
    are preserved according to their user-facing or internal role.
11. Navigation exposes Specs in the specified order, and its section presents
    specifications rather than a generic document-type catalogue.
12. Trackers and supporting documents have no user-facing management surface
    or entries in specification lists and relation panels. Their internal
    execution role and existing data remain operational.
13. A use case represents one feature, with at most one dump, quiz, spec, and
    tracker. Corrective work has its own linked use case.
14. The generated tracker references the real implementation tickets and
    organizes their execution order. Resolved and pending work follow current
    ticket state rather than an independent tracker checklist.
15. The user manages implementation tickets through Board and cannot directly
    manage the internal tracker from the web interface.
16. RW can generate a specification through its wrapped harness from the
    available context without requiring the user to manually create the file
    or paste the generated content.
17. One Approve action changes the generated draft to approved in the same
    specification file. Its identity and provenance remain intact, the index
    reflects the new status, and ticket execution does not start implicitly.

## Open Questions

Feature cardinality, optional discovery, regeneration limits, obsolete-ticket
retention, and file-backed ticket authority are settled for this PR.

- Should a later explicit mode allow automatic approval of generated specs?
- Do additional lifecycle states or revision policies become necessary after
  the maintainer trial?
- What interaction details need adjustment after trying the complete Specs
  workflow on the branch?

Keep this draft open for maintainer feedback before stabilization.
