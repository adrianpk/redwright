# RedWright Project Setup Discussion

## Metadata

- status: `curated discussion; open`
- created: `2026-10-19`
- updated: `2026-10-19`

## Related Draft

[Project Setup](../../specs/drafts/2026-10-19-redwright-project-setup-draft.md)
and [data model](../../specs/drafts/2026-10-19-redwright-project-setup-draft-model.md).

This is a curation of the actual setup discussion, maintained as the paired
discussion artifact required by the repository's specification workflow.
No separate questionnaire was conducted.

## Session 2026-10-19

### Context

The user reviewed Settings after simplifying the project Protocol interface.
Templates are shared defaults; project Protocol directly edits each project's
AGENTS.md and Markdown under .agents/.

The user asked for portable, idiomatic stack baselines, including Odin and
Racket, then asked how those sets become active in an incorporated project.
The discussion exposed missing web setup controls and disconnected continuations.

### Questions Raised

- Can project incorporation ask for the intended stack and install a complete set?
- Where is project incorporation available in the interface?
- Why does a New modal request a use case, and why does a different URL fail?
- Why is the actual New Project form visually inconsistent and missing Stack?
- What does Guided Alignment add, and where can its answers be entered?
- Can the entire setup, including its visual and functional gaps, be specified?
- Can directory selection use a picker, with manual path entry as an alternative?
- Will selected templates and supplied context actually be used downstream?

### Verified Findings

- The screenshots first showed a Dumps New modal and an unsupported singular
  project URL. The actual project creation route exists separately.
- Project management is not exposed by the current selector.
- The New Project form uses an inconsistent full-width layout and exposes an
  unexplained Guided Alignment select.
- Classic setup fixes Ruby and does not create or verify its workspace.
- Protocol initialization may run before a workspace is available.
- Guided Alignment asks about outcome, users/operators, and constraints. Its
  backend can persist answers, but the web does not expose continuation.
- Conversational setup has a separate, larger materialization path. Ordinary
  project incorporation needs a complete shared domain outcome.
- A browser-local folder selection does not by itself attach a workspace on
  the remote RW server.

### Confirmed Convergences

- The setup specification must cover visual consistency, ergonomics, accessible
  navigation, folder selection, guided startup, templates, and real artifact use.
- A selected stack should yield a complete project-owned protocol when defaults
  are needed. Odin and Racket belong in the selection.
- Protocol remains file-only. Existing project files remain authoritative.
- Prefer convenient directory selection; keep manual path paste available.
- New creates a folder under the server account's ~/Projects on Linux and macOS.
  A configurable default base is deferred.
- New initializes Git and optionally configures origin from repository input.
  It does not clone. This replaces the earlier remote-cloning proposal.
- Retain Guided Alignment and complete the originally intended project questions
  and actual use of their answers.
- Include Add existing in Projects for legacy folders. Preserve their Git,
  remote, content, and protocol, and share stack selection and optional guided
  context with New. Initialize protocol defaults only when no protocol exists.
- Original migrations are rewritten rather than followed by corrective ones.
- Factory remains an operational test bed with its existing artifacts.
- The present request authorizes specification work, not setup implementation.

### Provisional Decisions

- keep: New creates a directory and initializes Git under the agreed fixed base;
- discard: remote cloning as a setup mode;
- keep: separate Add existing action for legacy projects, confirmed;
- keep: exact single-stack selection plus General/common-only;
- keep: self-contained framework sets instead of language/framework layering controls;
- keep: centered, responsive setup using existing RW controls and shared feedback;
- keep: server-side folder browsing with a validated manual-path alternative;
- keep: retain the three-question stage as optional Add project context;
- keep: disabled-by-default context choice, proposed as the initial UI default;
- keep: one shared technical setup outcome for web and API;
- keep: operational success requires a real workspace, intended protocol outcome,
  and a usable Board;
- keep: verify quiz/spec/harness payloads, not merely saved rows;
- keep: do not start implementation, provision runtime services, or fabricate
  feature artifacts as part of registration.

## Open Questions

The source, Guided Alignment, and legacy incorporation choices are resolved.
The user explicitly requested extending this same specification with the
Add existing workflow. There are no remaining blocking setup-scope questions.
Detailed UX defaults remain reviewable with the complete draft.

## Edit Notes

Keep this file aligned with the draft and model. Provisional choices remain
reviewable; do not convert them into approved implementation scope implicitly.
