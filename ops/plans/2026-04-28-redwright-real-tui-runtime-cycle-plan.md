# Cycle Plan: Redwright Real TUI Runtime

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `tui + server-client runtime + project context`
- objective: `deliver a real persistent TUI experience with natural turns, visible runtime feedback, and stable project context resolution`
- tracker: `ops/trackers/2026-04-28-redwright-real-tui-runtime-cycle-tracker.md`

## Principles

- TUI is a persistent interactive session, not a one-shot wrapper.
- Human-visible output must show actionable runtime responses and errors.
- Project context resolution must not depend on first-token hacks.
- Server remains single execution owner.
- UX behavior is explicit, test-covered, and deterministic.

## Slice List

### Slice 1: Persistent TUI Session Loop

- status: `pending`
- branch: `feat/slice-1-persistent-tui-session-loop`
- [ ] `T1.1 run TUI in continuous read/render loop until explicit quit command`
- [ ] `T1.2 keep session id stable across turns in one TUI process`
- [ ] `T1.3 preserve and redraw history pane without shell restart flicker`
- [ ] `T1.4 add explicit in-app commands (`:quit`, `:status`) without breaking natural prompts`
- [ ] `T1.5 add loop lifecycle tests for multiple turns and clean exit`

### Slice 2: Runtime Feedback and Error Surface

- status: `pending`
- branch: `feat/slice-2-tui-runtime-feedback-surface`
- [ ] `T2.1 map server ack payload into user-facing summaries in TUI`
- [ ] `T2.2 render error envelopes with actionable reason text`
- [ ] `T2.3 remove ambiguous ` + "`status=`" + ` blank lines from TUI output`
- [ ] `T2.4 display task/workstream/terminal reason compactly per turn`
- [ ] `T2.5 add tests for success/failure rendering contracts`

### Slice 3: Project Context Resolution Without Prefix Hacks

- status: `pending`
- branch: `feat/slice-3-project-context-resolution-for-tui`
- [ ] `T3.1 add server-side project context resolver for socket clients using chat/session context`
- [ ] `T3.2 support explicit ` + "`@project <alias>`" + ` switch command in TUI`
- [ ] `T3.3 when ambiguous, return clarification question instead of silent failure`
- [ ] `T3.4 remove first-token project_ref inference from TUI and Telegram socket clients`
- [ ] `T3.5 add tests for inferred, explicit-switch, and ambiguous project cases`

### Slice 4: Multi-Client Coherence and Control Commands

- status: `pending`
- branch: `feat/slice-4-multiclient-coherence-controls`
- [ ] `T4.1 ensure parallel TUI and Telegram clients keep independent session contexts`
- [ ] `T4.2 wire ` + "`server ctl stop|resume|trace`" + ` to actual runtime behavior (not placeholder accepted)`
- [ ] `T4.3 expose control effects back into client views`
- [ ] `T4.4 add reconnection behavior tests preserving session continuity`
- [ ] `T4.5 add deterministic ordering tests for sequential same-project writes`

### Slice 5: Operator UX and Tasks

- status: `pending`
- branch: `feat/slice-5-tui-operator-ux-and-tasks`
- [ ] `T5.1 add dedicated rake tasks: ` + "`server`" + `, ` + "`server:trace`" + `, ` + "`tui`" + `, ` + "`telegram`" + `, ` + "`server:ctl:*`" + `
- [ ] `T5.2 update README runtime section with exact server+client run flow`
- [ ] `T5.3 add smoke test script covering server start + multi-turn TUI + shutdown`
- [ ] `T5.4 validate no Telegram token requirement for TUI path`
- [ ] `T5.5 close cycle tracker with final parity/UX checklist`

## Global Exit Criteria

- TUI runs as persistent interactive session and supports multiple consecutive turns.
- TUI shows meaningful server outcomes and errors per turn.
- Project context resolution is robust and no longer token-prefix fragile.
- Multi-client operation remains coherent under single server ownership.
- Operator commands and run tasks are short, explicit, and reproducible.
