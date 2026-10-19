# RedWright Project Setup

## Metadata

- status: `draft`
- selection_status: `open`
- created: `2026-10-19`
- updated: `2026-10-19`
- readiness: `New and Add existing scope consolidated; maintainer review before planning`
- scope: `web/project-setup`

## Related Artifacts

- [Data model](2026-10-19-redwright-project-setup-draft-model.md)
- [Curated discussion](../../conv/quiz/2026-10-19-redwright-project-setup-quiz.md)
- [Earlier web initialization contract](../specs/2026-05-02-redwright-web-project-initialization-and-agent-workflow-spec.md)
- [Conversational setup contract](../specs/2026-05-03-redwright-rails-project-setup-conversational-saga-spec.md)
- [Self-contained stack template proposal](2026-05-04-redwright-stack-protocol-template-composition-draft.md)
- [Current file authority](../../../docs/reference/specification-files.md)

## Purpose

Make incorporating a project into RW a discoverable, understandable, and
complete web workflow. The result must be an accessible workspace, the intended
project protocol, a usable Board, and project context that reaches the agents
when the user supplies it.

This specification covers navigation, visual consistency, directory selection,
source validation, stack and template selection, materialization, optional guided
context, artifact consumption, completion, cancellation, and recovery.

## Evidence and Current Gaps

The source inspection and user screenshots establish the following baseline:

- The project selector switches projects but does not expose project management.
  Projects and New Project exist as separate routes.
- The New Project form uses a full-width layout without the spacing and
  containment of the current artifact interfaces.
- The form exposes Name, Directory Name, Repository, and an unexplained
  Guided Alignment selector. It has no stack selector or directory browser.
- The classic creation lifecycle fixes the stack to Ruby. Its workspace step
  returns a descriptor without creating or verifying a directory.
- That lifecycle invokes protocol initialization before its workspace step.
  An unavailable workspace can produce a skipped initialization.
- The conversational materializer follows another path, with additional default
  board, summary, ticket, runtime, and local-workspace operations. It does not
  provide a complete web continuation for the classic form.
- Guided Alignment has three implemented questions. The web form can leave a
  session waiting for answers but supplies no interface to answer them.
- Protocol is file based. Template administration is a separate shared catalog.
  Existing project protocol files take precedence over initialization defaults.
- Stack selection currently uses free-text matching. Matching stack documents
  replace common documents with the same key.

Implementation entrypoints:
[ProjectsController](../../../apps/web/app/controllers/projects_controller.rb),
[classic lifecycle](../../../apps/web/app/services/project_initialization/active_record_lifecycle.rb),
[setup runner](../../../apps/web/app/services/project_initialization/setup_session_runner.rb),
[conversational materializer](../../../apps/web/app/services/project_setup/local_workspace_materializer.rb),
[guided alignment](../../../apps/web/app/services/project_setup/guided_alignment_service.rb),
and [protocol initialization](../../../apps/web/app/services/project_protocols/initialization_service.rb).

## Decisions and Review Boundary

### Confirmed Requirements

1. Setup must cover the whole user journey, including visual quality,
   consistency, ergonomics, and the actual use of generated artifacts.
2. A user must select the intended stack when incorporating a project. An empty
   protocol set receives common templates plus that selected stack's defaults.
3. Choosing a directory should be easier than manually typing a path when a
   practical picker is available. Pasting a path remains supported.
4. Protocol operates directly on AGENTS.md and Markdown under .agents/.
   Project protocol bodies or indexes must not be reintroduced into SQL.
5. Existing files are authoritative. Templates initialize project-owned copies.
6. Required schema changes rewrite the original migrations. Do not append
   corrective migrations. Keep Factory and its existing artifacts operational.
7. New Project creates a new directory under ~/Projects on the RW server on
   Linux and macOS. Configuring a different default root is deferred.
8. A new project initializes Git locally. Repository input configures a remote;
   it does not clone a repository.
9. Retain Guided Alignment and complete its intended optional project-context
   workflow, including actual downstream use of the answers.
10. Projects has separate New and Add existing actions. Add existing registers
    a legacy folder in place and shares stack selection, optional guided context,
    and completion with New.
11. Legacy incorporation retains existing files, Git configuration, and project
    protocol. A legacy project without a protocol receives the selected defaults.

### Proposed Defaults

The complete behavior below is proposed for review, rather than a claim that
every detail has already been approved.

| Decision | Proposal |
| --- | --- |
| Stack | One selected catalog stack, or an explicit General option using common templates only |
| Frameworks | Rails and Angular select complete stack sets; no additional language-stack inheritance control |
| Context default | Optional Add project context is disabled by default |
| Context entry | One compact page with the three existing questions, including partial save and resume |
| Landing | Open the new project's Board after technical setup or optional context completion |
| Agent execution | Setup prepares context and files; execution requires its own existing user action |

## User Journey

~~~text
Project selector -> Projects
                       |
          +------------+-----------------+
          |                              |
         New                        Add existing
   name + directory                folder + name
 stack + optional remote          stack + keep Git
          |                              |
          +------------+-----------------+
                       |
             validate and register
                       |
           workspace + protocol + Board
                       |
          +------------+-----------------+
          |                              |
    context omitted                context selected
          |                              |
          |                    three project questions
          |                     Save / Finish / Skip
          +------------+-----------------+
                       |
          registered project selected + Board

Any failed step -> useful error + preserved input + safe retry
~~~

Technical readiness and optional context completion are separate outcomes.
A project that is technically ready remains usable while optional context is
pending or skipped.

## Navigation and Visual Contract

- Keep project management outside the feature-specific navigation sequence.
  Add a Projects entry to the project selector. On Projects, group New and
  Add existing at the upper right, following the existing index convention.
  Use distinct action labels rather than an unexplained source-mode selector.
- The selector and creation entrypoint remain available with no registered
  projects. The empty state offers both creation and existing-folder attachment.
- Use the existing navigation highlight and aria-current convention. Global
  project management must not appear to edit the previously selected project.
- Use the existing page width, surfaces, typography, borders, action styles,
  input styles, modal behavior, and shared notification component. Do not add a
  separate design system for setup.
- Keep the form in a centered container with a readable width and responsive
  gutters. At 390, 768, and 1440 CSS pixels, headings, labels, fields, and actions
  remain inside the viewport without horizontal scrolling or clipped content.
- Organize fields into short source, identity, and protocol groups. Display only
  source-specific fields that apply. Optional content does not expand the basic
  form into a long questionnaire.
- Use English copy. Explain an unfamiliar choice once, next to that choice.
  Do not expose service class names, raw saga states, trace identifiers, or
  conversation explanations as product copy.
- Page-level actions belong at the upper right. Save, Create, Finish, and Cancel
  controls that affect a form belong below its fields. Use the same hierarchy
  and placement as the existing artifact editors.
- Show current status as a concise label or chip. Chips report state; explicit
  buttons, checkboxes, or themed controls perform actions.
- Reuse Rails flash for redirects and the existing shared notification bridge
  for asynchronous saves. Pending, saved, and failed states must be observable.
  Avoid a separate Saved message below each field.
- Provide visible keyboard focus, associated labels, accessible errors, and
  predictable tab order. A modal traps focus, closes without changing the form
  on Cancel or Escape, and returns focus to its trigger.
- Return validation errors beside fields and focus the first invalid field.
  Preserve entered values and the selected stack after every recoverable error.

## Source, Folder, and Identity

### New Project

New creates a directory; it does not import or clone a repository.

- Use ~/Projects as the base on Linux and macOS, resolved for the account running
  RW on the server. It is not the browser machine's home directory.
- Collect Name and suggest Directory name from it. Keep the directory component
  editable and show the resulting destination before creation.
- Accept only one directory component, excluding absolute paths, separators,
  parent traversal, and names that resolve outside the base. Changing the
  display name after creation must not move or rename its directory.
- Create the base when absent and permitted. An unavailable or unwritable base
  produces an actionable error, not another silently selected destination.
- Refuse every occupied destination, including an empty directory, file, or
  symlink. Do not delete, merge into, or overwrite it. Preserve form input so
  the user can choose another directory name.
- Protect reservation against concurrent creation. Ownership checks during
  rollback must never classify a pre-existing directory as created by RW.
- Run git init in the newly created folder. If a Remote URL is supplied,
  configure origin to that URL in this new repository.
- Label remote input clearly and validate its supported URL syntax. Do not infer
  a hosting provider. Configuring the remote requires no clone, fetch, push,
  initial commit, or creation of a repository on a hosting service.
- Git initialization and remote configuration must succeed before technical
  readiness. Retain a safe retry when a local Git operation fails.
- A configurable default project root in Settings is deferred. This delivery
  does not add that setting or a different destination-root selector to New.

### Add Existing Project

Use this separate action in Projects to incorporate a legacy project in place.

- Select an existing directory on the RW server. Do not move, copy, clone,
  reset, or initialize its repository.
- Validate that RW can read it and perform the writes required by the selected
  setup behavior. Report a missing directory, permission failure, or conflicting
  registration before publishing a project.
- Suggest Name from the selected folder, while keeping the display name editable.
  Renaming the display name must not rename its directory.
- Detect an existing Git origin when available. Repository linkage is optional
  for an existing folder without a remote; do not invent a hosted repository URL.
- A repeated canonical workspace path resolves to its existing RW project
  instead of creating a second registration.
- The folder can be outside ~/Projects when the existing access policy permits
  it. New's fixed creation base does not force an existing project to move.
- Show the detected origin as existing repository information, not an editable
  instruction to reset the remote. Keep the Name and Stack fields explicit.
- Explain the protocol outcome before submission: initialize common plus the
  chosen stack only when no protocol exists; otherwise keep the existing set.
  Use Add project as the form's submit action.
- Preserve README files, source code, uncommitted changes, branches, nested
  Markdown, and operational artifacts. Registration does not scaffold or
  normalize the legacy repository.
- If recognized RW artifacts already exist in the folder, use the established
  file reconciliation contracts and reuse valid identities and associations.
  Do not generate a competing specification, tracker, ticket set, or Board.
- An unrecognized external artifact layout remains untouched. A problem in a
  recognized artifact produces its normal actionable error; do not discard or
  overwrite it to complete registration.
- Cancellation or failure during attachment leaves the existing folder and Git
  unchanged. Compensate only unchanged files and database rows owned by this
  setup attempt.

### Folder Selection for Existing Projects

- Place Browse next to an editable Workspace field. The picker lists directories
  on the RW server, with breadcrumbs, parent navigation, folder icons, and a
  Select folder action. Selecting a folder only populates the field.
- Start from configured workspace roots or the last valid location permitted
  to the current user. List one directory level at a time with bounded results.
  Do not recursively scan the machine when opening the picker.
- Support folder names containing spaces and non-ASCII characters. Preserve
  the selected path when a user opens and cancels the picker.
- If browsing is unavailable or fails, keep the editable field usable and show
  a concise fallback message. Manual paste is a supported path with the same
  server-side validation, not a less capable setup mode.
- Explain the distinction with brief copy such as Folder on the RW server.
  An absolute path is useful here because the user is choosing the workspace;
  it must not become repeated metadata across normal project cards and pages.
- Apply the deployment's directory-access policy to both browsing and pasted
  paths. Do not expose unauthorized directory names or follow a symlink outside
  permitted roots.
- A browser-local directory picker or directory upload is not a substitute for
  selecting a server workspace. Such APIs grant access on the browser's
  device; they do not establish a filesystem path readable by remote Rails.
  See [Chrome File System Access documentation](https://developer.chrome.com/docs/capabilities/web-apis/file-system-access)
  and [showDirectoryPicker](https://developer.mozilla.org/en-US/docs/Web/API/Window/showDirectoryPicker).

### Repository Meaning

The inspected Repository field currently accepts a remote reference. It does
not execute git init. The updated New workflow must implement local Git
initialization and optional origin configuration as described above.

For Add existing, inspect and retain the repository and its origin when present.
Do not run git init or replace an existing remote during attachment. A folder
without Git can still be registered; adding Git to a legacy folder is a separate
explicit operation, not a hidden interpretation of the Repository field.

## Stack and Template Contract

- Populate Stack from active stack sets in Settings. Use a human name for each
  choice and a stable catalog key internally. Odin and Racket must be selectable.
- Require an explicit selection. Offer General for common templates only;
  do not silently use Ruby when a stack is missing, unknown, or unavailable.
- Use the selected key directly for web setup. Free-text runtime/framework
  matching must not override an explicit selection. All entry channels must
  resolve to the same final selected key before materialization.
- Show one short explanation: common rules plus the selected stack's rules
  become the project's protocol. Do not expose template layering machinery.
- Framework sets are self-contained: selecting Rails does not require selecting
  Ruby as well. Selecting Angular does not require a second TypeScript choice.
- For an empty protocol set, materialize common documents plus selected stack
  documents. A stack document replaces the common document at the same normalized
  project-relative path; unrelated common documents remain.
- Reject duplicate destinations, conflicting definitions, unavailable selections,
  and an incomplete required output set before publishing success.
- Resolve and snapshot the selected template inputs once per materialization
  attempt. If definitions changed since a displayed preview, refresh that preview
  before confirmation. A retry must not produce a mixture of template revisions.
- Produce AGENTS.md, the applicable concern files, .agents/PLAYBOOKS.md, and its
  playbook files. Every generated reference must resolve inside the workspace.
  AGENTS references the playbook index; that index references its procedures.
- If any existing project protocol set is present, preserve it as a set,
  including intentional omissions and nested Markdown. State that the existing
  protocol was kept. Stack selection records project context but does not
  authorize filling, rewriting, or restoring existing protocol files.
- Apply that preservation rule even if a legacy set contains only AGENTS.md or
  only files under .agents/. A missing index can be explained and addressed
  explicitly from Protocol; attachment must not silently reconstruct it.
- A workspace previously initialized to an intentionally empty protocol set
  also retains that decision. Distinguish it from a workspace never initialized.
- After setup, project Protocol reads its own AGENTS.md and .agents/**/*.md.
  Template edits affect subsequent initializations only. Later project edits
  do not mutate shared template definitions.

## Guided Project Context

### Purpose and Entry

- Replace the unexplained Opt in/Skip select with Add project context, marked
  optional and accompanied by a concise explanation of its use by agents.
- Selecting it opens a functional context page after technical setup. Leaving
  it unselected completes setup directly.
- Preserve the three existing semantic questions: primary outcome, users or
  operators, and constraints/risks/non-goals.
- Present the questions together in a compact form using the same textarea and
  action styling as the artifact editors. These describe the project as a whole.
  Do not manufacture a feature, dump, quiz, specification, or delivery ticket.
- Keep fixed semantic keys and clear English wording. These three inputs must
  not require an available LLM merely to render, save, skip, or finish.

### Saving, Skipping, and Resuming

- Save accepts the answers currently provided without requiring all three.
  Finish saves supplied answers and ends this optional stage. Skip finishes
  without inventing answers or discarding answers already saved.
- A blank value does not create a placeholder attribute. Revisiting a saved
  value allows correction; optimistic concurrency prevents overwriting a newer
  update from another browser or channel.
- A reload or sign-in restoration resumes the same project and saved context.
  Provide a visible Resume setup action in project management while this stage
  is pending. It must not leave an unreachable open session.
- The existing project context surface, including its project-level quiz where
  appropriate, must allow later refinement without recreating the project.
  Keep setup context and later quiz contributions distinguishable by provenance;
  do not run an additional automatic quiz at the end of setup.
- Optional context failure cannot undo technical setup or remove its project.
  Display what was saved, retain unsaved text, and allow retry or finishing later.

## Artifacts Must Affect Real Work

Setup is not complete merely because files or database rows were written.

| Input or artifact | Required consumer behavior |
| --- | --- |
| Selected stack | Project identity and runtime context use that same explicit key |
| Project protocol files | Protocol page and harness resolve the same workspace-owned files |
| AGENTS and playbook references | Referenced documents remain discoverable through the owning indexes |
| Supplied project context | Subsequent quiz and specification generation receive the accepted values |
| Supplied project context | Agent ticket execution receives those values in its project context |
| Optional setup summary | Internal report uses file-backed document storage and stays outside Specs |
| Default Board | The new project selector and Board entry resolve to that project's actual board |

- Reuse the existing context-building boundaries. Do not create a setup-only
  context injector that downstream work never reads.
- Verify protocol discovery and the existing applicability selection policy.
  Do not indiscriminately inject every playbook into every prompt.
- Structured project context retains its existing ProjectAttribute authority.
  Session turns are history. An optional internal summary is a derived snapshot,
  not another editable source that can contradict those current values.
- No document body is stored in the derived documents table. Protocol has no
  database content copy or metadata index. These rules also apply during setup.
- External protocol edits must affect the next applicable harness request.
  Never substitute global agent files or shared templates for a project's files.
- Completing setup does not approve a specification, generate feature tickets,
  run an agent, install language dependencies, or activate a runtime container.
  Existing runtime setup features remain separate explicit actions.

## Technical Setup, Completion, and Recovery

Use one shared application workflow from web controllers and command handlers.
They may present different interfaces but must not materialize different projects.

Required order:

1. Validate identity, source, actual destination, authorization, and stack choice.
2. Resolve duplicate registrations and create or resume the setup session.
3. For New, create its directory, initialize Git, and configure the supplied
   remote. For Add existing, attach the verified folder without changing its Git.
4. Prepare the common and selected stack inputs; inspect the existing protocol.
5. Register the project with its real accessible workspace and selected stack.
6. Materialize the protocol when appropriate and verify generated references.
7. Ensure one default Board and the established default columns. An imported
   project with an existing Board keeps its Board and tickets.
8. Persist the technical readiness checkpoint and any internal file-backed report.
9. Select the new project. Open optional context if selected; otherwise open Board.

- Project name, database identity, and workspace path are distinct. Do not
  persist a container placeholder as the usable server directory.
- Show pending feedback during slow operations and prevent duplicate submission.
  Long operations must expose actual server state, not simulated progress.
- Use one idempotency key for a submitted attempt and reuse its results on
  refresh, browser retry, or double click. Enforce unique workspace registration
  and avoid duplicate boards, answers, summaries, and protocol writes.
- Treat filesystem writes and database commits as separate failure boundaries.
  Record which files and directories the attempt owns before compensating.
- Before readiness, a failed attempt either safely removes only its unchanged,
  newly created artifacts or remains visibly recoverable with Retry.
  Never delete or reset an attached project directory.
- If another process edits a newly written file, recovery preserves that edit
  and reports a conflict. Do not restore a stale setup snapshot over it.
- Cancellation before materialization leaves no project or Board; a cancelled
  session may remain as operation history. Cancellation during a slow step must
  reach that owned operation and have an observable outcome.
- Closing optional context or cancelling after technical readiness keeps the
  usable project. It must not invoke the pre-creation rollback path.
- Optional reports must not turn a usable project into a falsely failed setup.
  Report a failed report/index refresh separately and retry it without repeating
  the completed technical work.
- A completed registration leaves no required action available only through API
  calls, Rails console commands, knowledge of a route, or a manually edited path.

## Interface and Ownership

- Preserve the existing /projects and /projects/new entrypoints.
  Add web continuation, progress, retry, and folder-listing routes only where
  the user journey needs them. Link every public step from the interface.
- Keep browser GET requests read-only apart from ordinary session navigation.
  Folder browsing does not initialize files or seed a project.
- Extend the existing StartProjectSetup, AdvanceProjectSetup, CancelProjectSetup,
  and GetProjectSetupSession semantics through shared Rails services.
- Validate request fields on the server. Only the session owner or an actor
  allowed by existing project permissions may continue or cancel that session.
- Use Rails request forms, flash, and existing JS conventions. Do not introduce
  a second frontend framework or a separate setup persistence framework.

## Data Transition and Existing Projects

The [model companion](2026-10-19-redwright-project-setup-draft-model.md) defines
authorities, fields, indexes, lifecycle, and migration targets.

- Rewrite applicable original migrations and update the schema, fixtures, and
  tests together. Do not append corrective migrations.
- Provide a bounded, explicit data-preserving conversion for an existing
  development database when needed. Editing an already-recorded migration alone
  does not update that database.
- Keep Factory selectable and preserve its workspace, Board, tickets, cases,
  dumps, quizzes, specifications, and existing protocol. Do not reset it to make
  the new setup appear to work.
- Handle pre-existing pending alignment sessions through the visible resume or
  skip path. Do not create another project to recover their context.
- The local, uncommitted Settings/baseline changes are an input to this design,
  not evidence that this setup specification has been implemented.

## Acceptance and Verification

| ID | Scenario and observable result |
| --- | --- |
| SET-01 | With zero or several projects, project management, New, and Add existing are reachable without typing a URL |
| SET-02 | At 390/768/1440 widths, setup and its picker fit the viewport and match existing RW controls |
| SET-03 | Keyboard users can select a folder, cancel the picker, resolve errors, submit, and resume with predictable focus |
| SET-04 | Browse and manual paste select the same server directory, including names with spaces; unavailable browsing leaves paste usable |
| SET-05 | A browser on a different machine never reports its own local folder as an attached RW workspace |
| SET-06 | Missing/inaccessible/disallowed/duplicate paths produce useful results without destructive side effects |
| SET-07 | Every active stack, including Odin and Racket, resolves its exact selected key; General does not become Ruby |
| SET-08 | An empty protocol set receives the complete common-plus-stack output with valid AGENTS and playbook references |
| SET-09 | Existing partial, nested, customized, and intentionally empty protocol sets remain unchanged |
| SET-10 | Shared template edits affect a new initialization, while initialized project files remain independent |
| SET-11 | A real existing folder becomes a selectable project with a usable Board; technical success never points to an absent directory |
| SET-12 | New creates a real Git repository under the server's ~/Projects, sets the supplied origin, and performs no clone, fetch, push, or initial commit |
| SET-13 | Default context choice completes directly; opting in opens the three questions with useful English copy |
| SET-14 | Partial save, Finish, Skip, reload, correction, and Resume persist the intended context without duplicate turns or artifacts |
| SET-15 | A controlled quiz/spec/harness request receives the selected stack, supplied context, and applicable current project protocol |
| SET-16 | Editing a project protocol outside RW affects the next applicable request without template or SQL fallback |
| SET-17 | Double submission and parallel retries create one project, Board, and intended protocol set |
| SET-18 | Failure between file writes and database commit is recoverable and preserves existing or concurrently edited files |
| SET-19 | Cancelling before creation leaves no project; leaving optional context after readiness keeps the usable project |
| SET-20 | Internal reports stay outside Specs and no new protocol body/index storage appears in SQL |
| SET-21 | Web and API use the same resolved inputs and materialization rules; existing API continuation remains functional |
| SET-22 | Factory and its existing feature/delivery artifacts remain usable after the database transition |
| SET-23 | New rejects an existing destination, including an empty directory or symlink, and parallel submissions cannot overwrite it |
| SET-24 | Adding a legacy folder preserves its Git, origin, and files; a folder without Git is not initialized implicitly |
| SET-25 | Add existing works in an authorized folder outside ~/Projects and initializes common-plus-stack defaults only when no protocol exists |
| SET-26 | Attachment preserves a partial protocol and recognized existing RW artifacts; retries reuse their valid identities and relationships |

Use focused Rails integration tests for state and storage contracts, a real
owned temporary filesystem for attachment and failure recovery, and browser
checks for layout, focus, selection, and feedback. Exercise the actual context
payload boundary; a test that only checks saved rows is insufficient for SET-15.
Verify git init and origin through a disposable local workspace. Remote setup
must succeed without network access or an existing remote hosting service.
Capture the completed flow for maintainer review before committing implementation.

## Open Questions

There are no remaining blocking questions about the agreed setup scope.
New creates a folder under ~/Projects, initializes Git, and optionally sets
origin; it never clones. Add existing attaches a legacy folder in place and
preserves its files and Git. Both use explicit stack selection and offer the
functional optional Guided Alignment stage.

The UX defaults and complete acceptance criteria remain reviewable in this
draft. No implementation plan or execution authorization is implied.
