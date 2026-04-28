# Cycle Plan: RedWright Minimal Runtime and Skills

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `deliver a minimal, deterministic, primitive-first runtime with bounded turn loops, skill sub-loops, and low-friction operator controls across ingress channels`
- tracker: `ops/trackers/2026-04-29-redwright-minimal-runtime-and-skills-cycle-tracker.md`
- spec: `ops/specs/specs/2026-04-29-redwright-minimal-runtime-and-skills-spec.md`

## Principles

- Keep runtime deterministic at orchestration boundaries.
- Keep primitives small and stable.
- Keep model payloads selective and bounded.
- Keep skill execution as bounded sub-loops, not side channels.
- Keep channel adapters thin over one runtime core.

## Slice List

### Slice 1: Turn Loop V1 Contract Hardening

- status: `pending`
- branch: `feat/slice-1-turn-loop-v1-contract`
- [ ] `T1.1 define explicit runtime turn phases and transition table`
- [ ] `T1.2 add strict turn-state enum and guard clauses`
- [ ] `T1.3 wire deterministic transition tracing with stable ids`
- [ ] `T1.4 add tests for legal/illegal transition paths`

### Slice 2: Context Packet Builder V1

- status: `pending`
- branch: `feat/slice-2-context-packet-builder-v1`
- [ ] `T2.1 implement bounded packet builder with top-K files`
- [ ] `T2.2 include top-level tree summary and active objective`
- [ ] `T2.3 include last execution failures and patch summary`
- [ ] `T2.4 enforce deterministic truncation policy`
- [ ] `T2.5 add packet size/bound tests`

### Slice 3: Planner Output Schema V4

- status: `pending`
- branch: `feat/slice-3-planner-output-schema-v4`
- [ ] `T3.1 extend planner schema with control and skill fields`
- [ ] `T3.2 add strict validator and reject unknown keys`
- [ ] `T3.3 add backward compatibility behavior for missing fields`
- [ ] `T3.4 add parser/validator tests for schema failures`

### Slice 4: Control Plane Slash Router

- status: `pending`
- branch: `feat/slice-4-control-plane-slash-router`
- [ ] `T4.1 add slash parser for project/status/pause/resume/cancel/skill/continue`
- [ ] `T4.2 enforce precedence: slash > hints > NL`
- [ ] `T4.3 map slash outputs to runtime control intents`
- [ ] `T4.4 add tests for deterministic slash routing`

### Slice 5: Hint Normalizer and Merge Policy

- status: `pending`
- branch: `feat/slice-5-hint-normalizer-merge-policy`
- [ ] `T5.1 parse @hints into normalized fields`
- [ ] `T5.2 merge hints with session state and task objective`
- [ ] `T5.3 define conflict policy between hints and NL`
- [ ] `T5.4 add tests for mixed slash/hints/NL turns`

### Slice 6: Skill Router V1 (Explicit + Inferred)

- status: `pending`
- branch: `feat/slice-6-skill-router-v1`
- [ ] `T6.1 add SkillRouter contract: name/mode/confidence/reason`
- [ ] `T6.2 wire explicit activation from /skill`
- [ ] `T6.3 wire inferred activation from planner output`
- [ ] `T6.4 add activation telemetry and tests`

### Slice 7: Skill Sub-loop Runtime

- status: `pending`
- branch: `feat/slice-7-skill-subloop-runtime`
- [ ] `T7.1 add bounded skill sub-loop executor`
- [ ] `T7.2 add sub-loop terminal reasons and return artifact`
- [ ] `T7.3 enforce handoff back to main loop`
- [ ] `T7.4 add tests for normal/timeout/cancel exits`

### Slice 8: Clarification Session V2

- status: `pending`
- branch: `feat/slice-8-clarification-session-v2`
- [ ] `T8.1 persist active clarification question and resolved fields`
- [ ] `T8.2 enforce answer-first routing when clarification is open`
- [ ] `T8.3 add continue-with-current-context semantic handling`
- [ ] `T8.4 add tests for no-drift clarification progression`

### Slice 9: Feedback Loop Integrator (Compile/Test/Lint)

- status: `pending`
- branch: `feat/slice-9-feedback-loop-integrator`
- [ ] `T9.1 normalize run-command results into failure classes`
- [ ] `T9.2 persist execution artifacts and failure fingerprints`
- [ ] `T9.3 inject artifacts into next-turn context packet`
- [ ] `T9.4 add fail->repair->pass loop tests`

### Slice 10: Bounded Convergence Policy V1

- status: `pending`
- branch: `feat/slice-10-bounded-convergence-policy-v1`
- [ ] `T10.1 enforce max attempts / max wall time`
- [ ] `T10.2 enforce max no-progress / repeated-fingerprint limits`
- [ ] `T10.3 add deterministic terminal reason assignment`
- [ ] `T10.4 add tests for all terminal outcomes`

### Slice 11: Bootstrap Skills (Repo + Docs)

- status: `pending`
- branch: `feat/slice-11-bootstrap-skills-repo-docs`
- [ ] `T11.1 add repo-bootstrap skill contract (init/remote/branches)`
- [ ] `T11.2 add scaffold-agent-docs skill contract`
- [ ] `T11.3 add scaffold-readme skill contract`
- [ ] `T11.4 add template source resolution order`
- [ ] `T11.5 add dry-run/preview contract and safety tests`

### Slice 12: Channel Parity and Simulated E2E Matrix

- status: `pending`
- branch: `feat/slice-12-channel-parity-e2e-matrix`
- [ ] `T12.1 add parity tests for control plane on telegram + console`
- [ ] `T12.2 add parity tests for skill activation explicit vs inferred`
- [ ] `T12.3 add same-session multi-turn scenario tests`
- [ ] `T12.4 add project switch + continue scenario tests`
- [ ] `T12.5 validate persistence and filesystem side effects in isolated workspace`

### Slice 13: Session-Project Continuity Policy

- status: `pending`
- branch: `feat/slice-13-session-project-continuity-policy`
- [ ] `T13.1 enforce one explicit active project binding per session`
- [ ] `T13.2 require explicit project switch control path before mutating actions`
- [ ] `T13.3 add NL-to-explicit project resolution guard for cross-project requests`
- [ ] `T13.4 add tests for same-session continuity across telegram and console turns`
- [ ] `T13.5 add tests for explicit switch then continue behavior`

## Global Exit Criteria

- Turn loop is explicit, deterministic, and test-covered.
- Context payloads are bounded, stable, and execution-useful.
- Slash controls and inferred controls coexist with strict precedence.
- Skills can be activated explicitly and inferred, through one runtime path.
- Feedback loop repairs converge within bounded policy limits.
- Bootstrap skill contracts are defined and testable.
- Telegram and console flows satisfy parity matrix.
- Session-project continuity remains stable unless explicitly switched.
