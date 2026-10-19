# RedWright Project Setup Data Model

## Metadata

- status: `draft`
- selection_status: `open`
- created: `2026-10-19`
- updated: `2026-10-19`
- readiness: `paired with consolidated New and Add existing behavior`

## Related Specification

[Project Setup](2026-10-19-redwright-project-setup-draft.md)

This companion defines the proposed durable contracts. It does not introduce
a second project, protocol, questionnaire, or document hierarchy.

## Authority Map

| Concept | Authority | Other representation |
| --- | --- | --- |
| Project identity and selected stack | Project row | Setup input/history snapshot |
| Usable workspace | Actual server directory at the canonical Project.root_path | Session checkpoint and source metadata |
| Shared template definitions | Existing template catalog | Per-attempt input snapshot for reliable materialization |
| Initialized protocol | AGENTS.md and .agents/**/*.md in that workspace | Session records applied/preserved outcome only |
| Current structured project context | Existing ProjectAttribute rows | Setup turns retain the answers that produced each update |
| Internal setup report | Markdown file for the report body | Document row indexes its path and metadata |
| Current context supplied to agents | Current structured context and applicable current project files | Bounded request payload |
| Setup operation and recovery ownership | ProjectSetupSession and its recorded steps | Web/API progress representation |
| Board and columns | Existing Board and Column records | Navigation and setup readiness checkpoint |
| Folder listing | Current authorized filesystem view | Bounded response only; no persistent directory index |

Project context remains structured application data, as in the current
[file authority contract](../../../docs/reference/specification-files.md).
The derived internal summary is an immutable snapshot for its recorded revision.
It is not a context editor or another authority for those structured values.
Protocol bodies, file titles, descriptions, and references remain file-owned.

## Project

| Business field | Stored representation | Validation and lifecycle |
| --- | --- | --- |
| Display name | projects.name | Required, trimmed; independent of folder name |
| Brief description | projects.description | User text when supplied; no invented product requirements |
| Workspace | projects.root_path | Canonical accessible server path; unique registration |
| Repository linkage | projects.repo_url | Origin configured for New or retained from an existing folder; nullable without a remote |
| Selected stack | projects.stack_slug | Exact active stack key or the explicit General sentinel |
| Timestamps | Existing timestamps | Registration/update dates, not file authorship dates |

- Keep root_path unique after canonical path resolution. Compare an attached
  directory's real identity, not only alternative spellings of its input path.
- Keep the current uniqueness rule for a nonblank repository linkage. A duplicate
  returns the existing project before creating another workspace.
- Normalize an absent repository to NULL. Multiple local folders without a
  remote must not collide on an empty-string unique value.
- All affected URL consumers must handle an absent remote explicitly. Do not
  create a synthetic remote merely to satisfy a string method or old validation.
- Store General with one explicit internal value, proposed as general.
  It selects only the common set; it must not invoke unmatched-stack fallback.
- Do not add a foreign key from project protocol files to template documents.
  A project remains usable if a template is renamed or archived later.
- Do not duplicate the selected stack as a separately editable setup_context.stack
  value. Any compatibility attribute is derived from the Project field.
- Retain the runtime/framework details needed by existing consumers. A selected
  Rails stack must not be downgraded by an older Ruby runtime attribute.

## Setup Session and Materialization Attempt

Reuse ProjectSetupSession with explicit normalized input and recovery metadata.
Add dedicated columns only when queries or database constraints need them.

| Business field | Existing or proposed representation | Contract |
| --- | --- | --- |
| Initiating actor | actor_identifier, source_channel | Authorization and request ownership |
| Submit identity | request_id | Stable across retries of the same attempt |
| Associated project | project_id | Nullable until registration; reused after readiness |
| Source mode | metadata.source_mode | New or existing-folder registration; no clone mode |
| Input identity | metadata normalized name/description | Preserve valid input after errors |
| Destination | metadata.workspace input/resolved path | New resolves one child of the server account's ~/Projects; attachment uses the authorized selected folder |
| Repository input | repository_input, resolved_repository_json | Sanitized URL/origin; no credentials |
| Stack selection | metadata.selected_stack_key | Validated once, then persisted as Project.stack_slug |
| Context choice | metadata.guided_alignment_requested | Explicit user choice; proposed default false |
| Template input | metadata template IDs, revision/digest, resolved paths and bounded snapshot | One consistent composition per attempt |
| Current phase | current_state and status | Coarse progress; reuse existing state vocabulary |
| Readiness checkpoint | metadata.technical_ready_at and completed-step results | Written only after workspace, protocol outcome, and Board are verified |
| Context continuation | pending_question and context metadata | Backward-compatible API continuation; web can render all three fields |
| Failure | terminal_reason and sanitized step error | Enough detail for Retry without leaking credentials |
| Owned side effects | metadata materialization manifest | Paths created, before/after hashes, directory ownership, associated row IDs |
| Source report | metadata report path/revision | Internal snapshot provenance, not a document body |
| Concurrency | Existing lock plus a revision token or lock_version if needed | Reject stale mutation and serialize completion |

- The server account's ~/Projects is the fixed New base for Linux and macOS.
  Record its effective canonical destination for retry; do not introduce a
  project-root setting in this delivery.
- New records completion of owned directory creation, git init, and optional
  origin configuration. Repository input is not an instruction to clone or
  create a hosted repository.
- A remote URL is configuration, not evidence of network access or remote
  existence. No network authentication is needed merely to set origin.
- An existing destination, including an empty directory or symlink, is a
  collision. Never adopt it as an owned side effect of New.
- Existing-folder registration records the chosen folder as attached and never
  owned by the attempt. Store the real canonical location even when it is outside
  the fixed New base.
- Preserve the discovered Git state and origin during attachment. The saved
  repository linkage describes that origin; it is not a command to modify it.
- A previously registered canonical folder resolves to its existing project and
  existing associations before another project or Board can be created.
- Enforce uniqueness for initiating actor, source channel, and request_id.
  Reusing that identity with a different normalized payload reports a conflict.
- Serialize writes for the same canonical workspace. A row-level uniqueness
  failure after a concurrent request resolves to the existing registration.
- Template snapshots are operation inputs, not a project protocol source.
  Protocol reads and later agent requests must never read this snapshot.
  Preserve identifiers, revisions, and result hashes for traceability; discard
  an unneeded body snapshot after the attempt reaches a final outcome.
- Retrying an interrupted attempt reuses its recorded inputs and ownership.
  Refreshing templates is an explicit new attempt, not a silent mid-retry change.
- A readiness timestamp is a completed checkpoint, not a claim that a directory
  will remain available forever. Later workspace loss reports unavailable
  through the normal project/file access behavior.

### Lifecycle

| Operational phase | Reused state | Required outcome |
| --- | --- | --- |
| Form/context collection | collecting_context | No required workspace writes |
| Validated submission | ready_to_create | Stable normalized input and chosen template set |
| Owned materialization | creating_project | Actual workspace, protocol outcome, and Board steps |
| Optional project questions | collecting_alignment | Technical readiness already recorded |
| Finished or context skipped | completed | Project usable; accepted supplied answers retained |
| Cancelled before readiness | cancelled | No published project; safe compensation recorded |
| Fully compensated failure | failed | Useful error and controlled retry from recorded input |
| Partial/conflicting outcome | needs_reconciliation | Owned leftovers shown through recovery UI |

The implementation must add explicit retry/reconciliation transitions where
the existing state machine currently makes failed states terminal. It must not
edit state fields directly to bypass transition rules.

Leaving optional context after readiness completes or skips that optional stage.
It does not cancel or destroy the registered project. Preserve legacy pending
sessions and expose them through the same continuation page.

## Structured Project Context and Turns

The existing keys remain:

- guided_alignment.primary_outcome
- guided_alignment.operators
- guided_alignment.constraints

| Field | Stored representation | Contract |
| --- | --- | --- |
| Semantic key | project_attributes.key | Unique within the owning project |
| Current answer | project_attributes.value | Supplied nonblank value; no generated placeholder |
| Relevance | project_attributes.weight | Existing supported range; not a second workflow state |
| Provenance | project_attributes.source | Guided setup distinguished from other project context |
| Answer history | project_setup_turns | Records accepted changes and their origin |
| Request identity | project_setup_turns.request_id | Deduplicate a retried accepted update |
| Submitted normalized fields | normalized_fields_json | Semantic key, value, action, and source revision |

- Enforce uniqueness of project_id plus key for current context and session_id
  plus turn_index for ordered history.
- For a web form submitting several answers, deduplicate each accepted semantic
  update within its submit identity. Repeated Save must not append unchanged
  answers as new turns.
- Allow partial answers. Explicitly clearing a previously supplied answer
  removes that current value and records the change; an omitted field in an API
  payload leaves its value unchanged.
- All consumers read current attributes. Session history and report snapshots
  do not override a more recent accepted correction.
- Keep one meaningful source of each semantic value in the generation payload.
  If the later project quiz adds or conflicts with setup context, preserve source
  identity and use the existing context policy instead of pretending both are
  current identical facts.
- Use the existing bounded context builders for quiz generation, specification
  generation, and ticket execution. Verify actual request payloads.

## Template and File Materialization

Reuse ProjectProtocolTemplate and ProjectProtocolTemplateDocument. Their
database-backed catalog remains distinct from each project's file-only Protocol.

1. Resolve common plus exactly the selected active stack.
2. Normalize output paths. Selected-stack definitions take precedence at the
   same path; conflicting duplicate definitions within a set fail validation.
3. Validate output size and reference consistency before writing.
4. If an existing or intentionally empty initialized project set is detected,
   record preserved and do not write default protocol files.
5. Otherwise write with the existing safe workspace/file boundaries and track
   ownership for rollback.
6. Verify the written set and its references before recording technical readiness.

For attachment, record the protocol outcome as initialized or preserved.
A partial existing set remains preserved, including a set missing AGENTS.md or
the playbook index. Verification of generated references applies to newly
generated files; it does not authorize rewriting a preserved legacy set.

An initialized-empty marker records that deliberate absence. It is not a second
document catalog and must not restore deleted files.

Atomic writes and a workspace lock protect filesystem changes. Database rollback
alone cannot undo them. Compensation checks current hashes before removing any
file and never recursively removes an attached directory.

## Internal Reports and Board

- Keep report bodies in the existing internal report layout under
  ops/default/report, using the established file-backed Document contract.
  Store one report reference per setup session and update that session's same
  report on a retry instead of allocating another.
- The documents table stores the existing path, kind, status, timestamps, and
  source fingerprint. It must not regain a body column.
- Report generation is optional for technical readiness. Its retry cannot repeat
  successful registration, template writes, or Board creation.
- Preserve report provenance and revision. Current project context is never
  rebuilt from an old report body.
- Reuse an existing project Board. Otherwise create one default Board with
  Backlog, In Progress, Review, Approved, and Merged columns.
- Reconcile recognized existing file-backed RW artifacts through their current
  contracts before creating competing delivery state. Keep valid ticket keys,
  feature associations, source paths, and execution history intact.
- Protect default Board creation from duplicate submissions through a session
  checkpoint and appropriate uniqueness/locking at its owning boundary.
- Do not create starter delivery tickets, cases, dumps, quizzes, specifications,
  or runtime provisioning jobs as a side effect of ordinary registration.

## Folder Browser, Permissions, and Limits

Directory browsing is read-only and ephemeral. Its response contains the current
authorized directory, parent/breadcrumb entries, selectable child directories,
and a pagination cursor or explicit truncation indicator. It has no SQL table.

- Enforce the same access boundary for Browse and manually submitted paths.
- Resolve symlinks and canonical paths before permission and uniqueness checks.
  Return directory names only within the configured authorized roots.
- Restrict session mutation to its actor or an existing authorized project role.
  Template editing remains subject to the existing Settings permissions.
- Apply the application's CSRF protection to web mutations.
- Proposed bounded defaults: 100 directory entries per page, 4 KiB for a path
  or repository input, 8 KiB per context answer, and 10 seconds per local Git command.
  Reuse stricter existing application limits and make deployment-specific
  overrides explicit. No browsing recursion, unbounded output, or automatic
  retry loop is required.
- Do not persist directory contents, Git credential material, or raw Git
  stderr that may contain credentials.

## Queries and Recovery

Required queries support:

- existing projects ordered by display name;
- a project by canonical workspace or nonblank repository linkage;
- a resumable session owned by the current actor;
- that session's current phase, accepted context, pending step, and safe retry;
- active stack choices and their exact selected definition;
- authorized immediate child directories without a project-side effect;
- current structured project context and actual project protocol files.

Long-running work has one owned execution at a time per session. A background job,
when needed, uses the recorded session identity rather than creating another setup.
Progress reflects completed checkpoints, with sanitized failure details.

## Original Migration Targets and Existing Data

During implementation, rewrite the relevant original definitions:

- CreateProjects: nullable repository linkage when needed, canonical workspace
  uniqueness, and selected-stack invariants.
- CreateProjectSetupSessions and its turns: scoped submit identity, replay
  invariants, and concurrency fields only where required.
- CreateProjectAttributes: one current value per project and semantic key.
- Existing Board/Column definitions only if their creation invariants require it.

Update schema, fixtures, seeds, and tests to describe the intended clean schema.
Do not append corrective migrations or introduce project protocol tables.

For an already initialized development database, use a separate explicit,
repeatable conversion/export-import procedure where schema changes require it.
Back up before conversion; preserve IDs and associations needed by tickets and
other feature artifacts. Handle pre-existing duplicate attributes deliberately
before applying uniqueness. Do not silently discard conflicting values.

Backfill setup state only from verified available project data. An absent
workspace is not fixed by inventing a directory or marking the session complete.
Factory must remain operational with its existing data and file ownership.

## Open Questions

New directory creation, git init with optional origin configuration, Add existing
for legacy folders, and retention of Guided Alignment are confirmed. There are
no remaining blocking setup-scope questions in the
[parent draft](2026-10-19-redwright-project-setup-draft.md#open-questions).
No clone mode or default-root setting is part of this design.
