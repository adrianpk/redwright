# Redwright Ingress Port and Simulated End-to-End Specification

## Status

- type: `spec`
- date: `2026-04-28`
- derived_from: `ops/specs/drafts/2026-04-28-redwright-ingress-port-and-simulated-e2e-proto-spec-draft.md`
- scope: `runtime ingress architecture and local e2e validation`

## 1. Goal

Introduce an ingress port abstraction so runtime orchestration consumes canonical transport-agnostic messages, while enabling simulated end-to-end tests that validate SQLite persistence and filesystem side effects without external network calls.

## 2. Ingress Port Contract

Runtime ingress dependency MUST expose a canonical event stream and send-response operation.

Canonical inbound event fields:

- `external_message_id`
- `external_chat_id`
- `sender_id`
- `text`
- `received_at`
- `transport`

Contract rules:

- runtime depends on ingress protocol, not Telegram concrete client classes
- Telegram ingress remains the production adapter
- simulated ingress is test-only and protocol-compatible

## 3. Adapter Set

Required adapters for this cycle:

- `TelegramIngressAdapter` (production)
- `SimulatedIngressAdapter` (tests)

Future adapters (out of scope now) must be addable via DI without runtime-flow rewrites.

## 4. Runtime Boundary

Ingress adapter responsibilities:

- fetch/push canonical inbound events
- deliver outbound response payloads through transport adapter

Runtime core responsibilities stay unchanged:

- context resolution
- plan/alignment and action runtime flow
- sqlite persistence
- execution and trace lifecycle

## 5. Simulated E2E Test Contract

A simulated e2e test MUST:

- run through daemon/runtime entrypoint using simulated ingress
- avoid Telegram API and external network calls
- run in isolated `/tmp` workspace root
- assert SQLite writes for project/workstream/task-related entities
- assert filesystem side effects from executed actions within isolated root

## 6. Persistence Assertions

Minimum scenario assertions:

- task row exists with expected content for processed turn
- workstream state persisted after turn processing
- trace-linked task/action evidence persists when actions execute

## 7. Filesystem Assertions

When action execution includes file write:

- expected file exists under the allocated temporary workspace
- expected content pattern exists
- write scope stays within temporary root

## 8. Acceptance Criteria

This spec is satisfied when all are true:

- runtime operates via ingress protocol abstraction
- Telegram adapter behavior remains intact
- simulated ingress enables deterministic local e2e execution
- e2e validates sqlite persistence and filesystem side effects
- e2e runs in isolated `/tmp` roots with deterministic cleanup

## 9. Non-Goals

- Slack adapter implementation
- HTTP-level Telegram mocking when protocol simulation is sufficient
- planner/executor contract redesign
