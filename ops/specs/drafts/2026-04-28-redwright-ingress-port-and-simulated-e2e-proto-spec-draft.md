# Redwright Ingress Port + Simulated End-to-End Proto-Spec Draft

## Status

- type: `proto-spec-draft`
- date: `2026-04-28`
- source: `Telegram-first runtime requirement + request for pluggable ingress architecture and simulated e2e tests`

## 1. Scope

This draft defines a Ruby interface/protocol pattern where:
- Telegram remains the only production ingress in the current phase
- runtime flow consumes a transport-agnostic input port
- additional ingress types (for example Slack) can be injected later without runtime rewrite
- end-to-end style tests can run with a simulated input adapter (no Telegram API calls)

This is a specification draft only. No Slack implementation is included.

## 2. Primary Goal

Decouple ingress transport from runtime orchestration while preserving existing behavior:
- same runtime persistence contract in SQLite
- same filesystem side-effects for execution actions
- same turn lifecycle semantics

Transport changes must not alter domain/runtime contracts.

## 3. Ingress Port Contract (Ruby)

Define a minimal ingress protocol, for example `IngressPort`, with responsibilities:
- poll or receive canonical inbound messages
- expose canonical fields required by runtime flow
- acknowledge outbound responses through adapter-specific transport

Canonical inbound message shape (logical fields):
- `external_message_id`
- `external_chat_id`
- `sender_id`
- `text`
- `received_at`
- `transport` (`telegram`, future `slack`, etc.)

Rules:
- runtime must depend on protocol, not Telegram client concrete class
- Telegram adapter is one implementation of the protocol
- adapters are replaceable via explicit dependency injection

## 4. Adapter Pattern

Required components:
- `TelegramIngressAdapter` (current production adapter)
- `SimulatedIngressAdapter` (test-only adapter)
- optional future adapters (Slack, others)

Required behavior parity:
- all adapters emit the same canonical message type
- runtime flow remains unchanged across adapters

## 5. Runtime Integration Boundary

Ingress responsibility ends at canonical message delivery.

Runtime responsibilities remain:
- context resolution
- planning/alignment flow
- action materialization/execution
- SQLite persistence
- response creation

This prevents transport-specific conditionals from leaking into core runtime flow.

## 6. Simulated End-to-End Test Strategy

Tests must verify full runtime behavior using a simulated input port, not Telegram API.

Required test properties:
- execute a real turn through runtime entrypoint
- assert SQLite writes for project/workstream/task/alignment entities as applicable
- assert filesystem outputs created by execution actions
- run with temporary filesystem paths under `/tmp`

Temporary resource policy:
- each test allocates isolated `/tmp` directory
- test DB path and workspace path point to that directory
- cleanup is automatic at test end

## 7. Persistence Assertions (SQLite)

Minimum assertions per e2e scenario:
- task row created with expected status transitions
- workstream state updates are persisted
- turn/message traceability fields are present
- failure modes persist diagnostics (when applicable)

## 8. Filesystem Assertions

When execution actions include file creation/modification, tests must verify:
- expected files exist in `/tmp` workspace
- expected content patterns are present
- writes do not escape allocated temporary root

## 9. Acceptance Gate (Slice-Level)

This slice is complete only when all are true:
- runtime can process turns through ingress protocol abstraction
- Telegram adapter still works with no regression in behavior
- simulated adapter enables e2e tests with no external network calls
- e2e tests validate both SQLite persistence and filesystem side effects
- tests run with isolated `/tmp` roots and deterministic cleanup

## 10. Non-Goals

- no Slack adapter implementation in this slice
- no Telegram API mocking at HTTP level when protocol simulation is sufficient
- no redesign of core planner/executor semantics

## 11. Open Items

- final Ruby module/class names for ingress protocol and adapters
- synchronous polling loop vs event-driven handoff contract
- canonical message schema versioning strategy
- exact fixture strategy for multi-turn simulated conversations
