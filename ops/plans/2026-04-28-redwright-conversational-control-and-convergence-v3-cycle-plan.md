# Cycle Plan: Redwright Conversational Control and Convergence V3

## Metadata

- owner: `adrianpk`
- status: `draft`
- scope: `runtime`
- objective: `make clarification/control flow deterministic while preserving multilingual natural language and bounded autonomous convergence`
- tracker: `ops/trackers/2026-04-28-redwright-conversational-control-and-convergence-v3-cycle-tracker.md`

## Principles

- Use explicit runtime state, not implicit text heuristics.
- Keep LLM reasoning flexible, keep runtime transitions deterministic.
- Bound convergence loops by attempts, time, and context budget.
- Prefer minimal stable context packets over full-repo dumps.
- Preserve auditability: each transition and decision must be traceable.

## Slice List

### Slice 1: Control Intent Contract

- status: `pending`
- branch: `feat/slice-1-control-intent-contract`
- [ ] `T1.1 define control_intent enum: proceed_with_current_context, cancel_clarification_only, cancel_task, cancel_all, none`
- [ ] `T1.2 define control_scope enum: gap, task, workstream, chat, runtime`
- [ ] `T1.3 define planner response contract v3 with intent + control_intent + actions + gaps`
- [ ] `T1.4 define backward compatibility behavior when control_intent is missing`
- [ ] `T1.5 add parser unit tests for strict contract acceptance/rejection`
- [ ] `T1.6 add migration notes in runtime docs/spec`

### Slice 2: Clarification Session State Machine

- status: `pending`
- branch: `feat/slice-2-clarification-session-state-machine`
- [ ] `T2.1 add clarification_sessions persistence model with status=open/closed/cancelled/timed_out`
- [ ] `T2.2 persist pending_gaps, resolved_fields, last_question_id, turn_counter, created_at, updated_at`
- [ ] `T2.3 enforce single active clarification session per chat+workstream`
- [ ] `T2.4 implement deterministic transition table and guard clauses`
- [ ] `T2.5 add repository tests for create/open/resolve/cancel/timeout transitions`
- [ ] `T2.6 add trace events for each state transition`

### Slice 3: Turn Router Precedence for Pending Clarification

- status: `pending`
- branch: `feat/slice-3-pending-clarification-turn-router`
- [ ] `T3.1 add pre-router stage before planner call`
- [ ] `T3.2 when session=open, classify message as: gap_answer, control_command, or new_task`
- [ ] `T3.3 consume gap answers into resolved_fields before considering any new plan`
- [ ] `T3.4 prevent accidental meta drift (e.g., 'RSpec' becoming a new topic)`
- [ ] `T3.5 add deterministic tie-break rules for ambiguous short replies`
- [ ] `T3.6 add simulated ingress tests for multi-turn gap consumption`

### Slice 4: Multilingual Control Interpretation Layer

- status: `pending`
- branch: `feat/slice-4-multilingual-control-interpretation`
- [ ] `T4.1 define control interpretation prompt contract (language-agnostic)`
- [ ] `T4.2 map freeform text to control intents without hardcoded slash commands`
- [ ] `T4.3 include examples in ES/EN/IT/DE for proceed/cancel semantics`
- [ ] `T4.4 add confidence score and fallback strategy for low-confidence classification`
- [ ] `T4.5 require explicit confirmation only for destructive cancel scopes`
- [ ] `T4.6 add tests for metaphorical stop phrases and mixed-language messages`

### Slice 5: Context Packet V3 Budgeting

- status: `pending`
- branch: `feat/slice-5-context-packet-v3-budgeting`
- [ ] `T5.1 enforce top-K file selection policy (default K=5, configurable)`
- [ ] `T5.2 include repo tree summary (top-level only by default)`
- [ ] `T5.3 include snippets only (bounded lines/bytes per file)`
- [ ] `T5.4 include latest executable errors and previous patch summary`
- [ ] `T5.5 include project conventions and stack hints in compact form`
- [ ] `T5.6 add packet-size guards with deterministic truncation order`
- [ ] `T5.7 add tests for packet bounds and truncation determinism`

### Slice 6: Bounded Micro-Loop Execution V3

- status: `pending`
- branch: `feat/slice-6-bounded-micro-loop-v3`
- [ ] `T6.1 enforce per-task max attempts (default 6-8 configurable)`
- [ ] `T6.2 enforce task timeout budget (default 60-180s configurable)`
- [ ] `T6.3 enforce one action batch per iteration with stable ordering`
- [ ] `T6.4 run validation gates when available (build/test/lint)`
- [ ] `T6.5 on failure, re-prompt with exact errors + last patch + used files`
- [ ] `T6.6 terminal reasons: success, max_attempts, timeout, blocked, cancelled`
- [ ] `T6.7 add convergence tests: fail->repair->pass and non-convergent fallback`

### Slice 7: Cancellation and Resume Semantics

- status: `pending`
- branch: `feat/slice-7-cancel-and-resume-semantics`
- [ ] `T7.1 implement cancel_clarification_only without dropping task context`
- [ ] `T7.2 implement cancel_task with safe abort of active execution`
- [ ] `T7.3 implement cancel_all scoped to chat/runtime boundaries`
- [ ] `T7.4 implement resumable continuation from last stable checkpoint`
- [ ] `T7.5 guarantee no orphaned partial records after cancellation`
- [ ] `T7.6 add tests for cancel mid-clarification and cancel mid-convergence`

### Slice 8: Human Output Contract + Optional Debug Envelope

- status: `pending`
- branch: `feat/slice-8-human-output-and-debug-envelope`
- [ ] `T8.1 set human-readable response as default telegram output`
- [ ] `T8.2 keep JSON envelope optional via config flag`
- [ ] `T8.3 when debug enabled, render JSON in fenced block for Telegram`
- [ ] `T8.4 include concise execution summary (actions, attempts, terminal reason)`
- [ ] `T8.5 ensure clarify responses reference active question context explicitly`
- [ ] `T8.6 add tests for output mode toggling and message formatting`

### Slice 9: Persistence Hygiene and Dev Reset Safety

- status: `pending`
- branch: `feat/slice-9-persistence-hygiene-dev-reset`
- [ ] `T9.1 ensure dev reset can rebuild state from clean DB without manual edits`
- [ ] `T9.2 prevent stale clarification sessions from poisoning new runs`
- [ ] `T9.3 add TTL cleanup for abandoned sessions`
- [ ] `T9.4 add integrity checks for task/workstream/session linkage`
- [ ] `T9.5 add recovery tests for restart-after-crash during open clarification`

### Slice 10: Simulated E2E Matrix for Realistic Conversations

- status: `pending`
- branch: `feat/slice-10-simulated-e2e-conversation-matrix`
- [ ] `T10.1 same-project multi-turn build request with partial answers`
- [ ] `T10.2 new-project creation where name is inferred then confirmed`
- [ ] `T10.3 multilingual stop-asking command followed by execution`
- [ ] `T10.4 cancel current task vs cancel all runtime scope`
- [ ] `T10.5 interruption by new high-priority request mid-loop`
- [ ] `T10.6 non-convergent scenario falling back to blocked/clarify`
- [ ] `T10.7 assert filesystem and sqlite side effects in isolated test workspace`

## Global Exit Criteria

- Control commands in natural language are reliably interpreted into deterministic control intents.
- Open clarification sessions consume follow-up answers without meta drift.
- Micro-loop converges or exits with explicit bounded terminal reasons.
- Context packet stays bounded and stable while still enabling actionable edits.
- Cancellation/resume leaves no inconsistent persistence artifacts.
- Simulated e2e matrix demonstrates reproducible behavior across key conversation patterns.
