# ADR-005: Telegram Surface Strategy (Dual Bot)

## Status
Accepted

## Date
2026-04-29

## Context
One-bot strategy mixes informal project conversations with multi-project factory control traffic. This increases noise, policy complexity, and authorization risk.

## Decision
Adopt **dual Telegram bot surfaces**:

1. `interactive bot`
- Project-scoped operational conversations.
- Human-driven and low-latency interactions.

2. `factory bot`
- Kanban/factory control operations.
- Multi-project orchestration interactions.

Both bots route into the same Command/Query semantic core with different ingress policies.

## Consequences

### Positive
- Lower operator noise and channel overload.
- Simpler chat allow-list and control policy boundaries.
- Better audit separation by channel intent.

### Negative
- Additional token, webhook, and lifecycle management.
- Slightly higher setup complexity.
