# Specification Files

Specs uses project files as its source of truth. The Rails `documents` table is
a derived index of project-relative paths, titles, kinds, statuses, use-case
associations, source fingerprints, and file modification times. It contains no
document bodies. Document relations are reconstructed from file metadata.

## Layout and Metadata

New specifications use `ops/default/spec/<five-digit-id>-<slug>/artifact.md`.
Internal trackers use the corresponding `tracker` directory, and setup summaries
use `report`. Discovery also recognizes other namespaces and the existing
`ops/specs/specs/`, `ops/specs/drafts/`, `ops/plans/`, and `ops/trackers/` layouts.
Only specifications are exposed through `/specs` and its forms.

A use case represents one feature and has at most one dump, quiz, specification,
and tracker. Discovery is optional. New specifications select an existing feature
without a specification; further generation updates that same file and record.
Corrective features have a same-project `corrects_use_case_id` relationship.

Markdown has YAML frontmatter with `title`, `project_id`, `case_slug`, `status`,
and `created_at`, followed by the authored body. Generated specifications also
record the actual request identifier and response fingerprint, plus a Provenance
section identifying project and discovery sources. Manual authoring does not
require generation identifiers. Feature specifications require a valid `case_slug`.
Supporting reports can remain project-wide. Case names can change while
their slugs remain stable, so renaming a case does not break specification links.

The selected workspace establishes project ownership. A frontmatter
`project_id` is portable metadata, not a foreign key into the local Rails
database; existing values are preserved when editing or approving a file.

The adjacent `metadata.json` provides an `ops-layout/v1` artifact envelope.
Its creation status describes that envelope. The specification's lifecycle
status is read from Markdown, never from the envelope or a database override.

Normal harness generation writes `status: draft`. `Approve` changes it to
`status: approved` in place. Existing `accepted` and `final` specifications can
also be read. Web revisions become drafts unless saved with `Save and approve`.

The optional `relations` field contains mappings with `path` and `type`; types
are `derives_from`, `references`, and `tracks`. Paths refer to project-local
document files. These references rebuild the derived relation index.

## Refresh and Conflicts

Specs pages and specification command queries reconcile the selected project's files before
querying its index. Document bodies are read from files when needed. Agent
context reads the target workspace directly; it does not substitute documents
from the RW checkout. Implementation context excludes draft specifications.

Writes use a workspace lock, atomic file replacement, and a SHA-256 source
revision. A stale edit or approval returns a conflict. Missing files disappear
from the index. Unavailable workspaces and malformed files produce explicit
errors instead of silently serving cached content. Index failure cannot make
a database body authoritative; rebuilding the index recovers from files.

Files are limited to 2 MiB each, 500 discovered files, and 32 MiB in aggregate.
Discovery context is limited to 100 entries per collection and 128 KB. A feature
description is limited to 4,000 bytes. Harness generation has a 180-second
execution deadline and a 2 MiB output limit.

## Generation and Internal Trackers

The default wrapper invokes the installed `codex exec` in the project workspace,
in read-only, ephemeral mode with a structured title/body output contract.
`REDWRIGHT_SPEC_HARNESS` can select the compatible executable. Authentication
uses the local harness session. No provider credential or model configuration
is stored in specification files.

`Specifications::Tracker#generate!` accepts an approved specification and the
ordered, actual implementation tickets. The generated tracker's `ticket_keys`
field is the execution sequence. Completion comes from ticket workflow states:
`solved` and `closed` are terminal; archived tickets are not pending. Reopening
a ticket makes it pending again. A missing referenced ticket is an error.
Pickup follows the next pending ticket in each tracker, falling back to normal
priority ordering for untracked work. Trackers have no web read or edit surface.

`Build tickets` runs wrapped-harness slicing of an approved specification.
Existing ticket keys identify retained work. New slices receive new tickets;
omitted tickets close as `obsolete` and retain their original relationships.
The tracker's specification revision must match the approved source before
pickup or execution. Regenerating or editing a specification invalidates prior
slicing. Rebuilding publishes a current tracker after updating ticket files.

Once a ticket starts, its specification and tracker are protected. Returning it
to ready, solving it, or archiving it does not remove that recorded start. The
web offers a linked corrective case for later contract changes. External changes
to an executing specification produce an explicit reconciliation error.

## Ticket Files

Tickets use `ops/default/ticket/<five-digit-id>-<slug>/artifact.md` with the same
Markdown envelope. Their bodies contain descriptions. Metadata owns the stable
`ticket_key`, title, board and column keys, status, priority, feature slug,
execution timestamps, runtime and delivery references, specification path and
revision, and tracker path. SQL stores an index without a description body.
External edits refresh before board reads and pickup. Forms reject stale source
revisions. Missing files require restoration and never authorize deleting
history. Delivery tickets cannot be hard deleted.

Comments, project context, use cases, and quizzes retain their existing
database storage. Dump bodies live in project Markdown files; their database
rows are rebuildable metadata indexes. They do not duplicate the authoritative ticket body. Slicing
is limited to 20 tickets and 128 KB of input context; the harness execution and
output bounds also apply.

## Existing Databases

The applicable original migrations describe the intended index schema. No
corrective migration is appended. Existing installations need a data-preserving
transition because their original migrations have already been recorded.

Prepare a separate database before replacing an existing one:

```sh
cd apps/web
bundle exec rake 'specifications:prepare_database[/path/to/rebuilt.sqlite3]'
```

The task takes a consistent SQLite snapshot, builds the separate database from
the original migrations, copies unchanged domain tables, exports legacy
Markdown bodies into the owning project workspaces, and rebuilds document and
relation indexes. It exports legacy dump notes and useful synthesis into one
editable file per dump, retaining IDs, scope, tags, and a single document status.
It exports ticket files, preserving ticket IDs, prior metadata,
comments, and relationships, and validates foreign keys. Legacy standalone drafts
that fed approved specifications become internal historical reports with exact
bodies and relation edges intact. Unscoped specifications receive a feature case.
Existing project-wide discovery remains available as project context.
Existing exported files are never overwritten with different legacy bodies.
The source database remains unchanged. Keep its snapshot and project-file
backups until the transition is accepted.

Use a frozen source or repeat preparation from the latest data before the final
switch; writes made after the snapshot are not part of the prepared database.
Review and stop the application before switching its database. Do not run
`db:reset` against the existing database. Fresh seeds preserve existing demo
tickets and documents instead of resetting their work.

For an already converted database, refresh derived indexes with:

```sh
bundle exec rake specifications:reindex
```
