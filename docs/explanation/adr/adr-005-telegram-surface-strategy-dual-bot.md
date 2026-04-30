# ADR-005: Telegram Surface Strategy (Dual Bot)

## Status
Superseded by ADR-008

## Date
2026-04-29

## Context
This ADR defined a dual-bot strategy (interactive bot + factory bot) to isolate noisy traffic and policy boundaries.

## Supersession Note
As of 2026-04-30, RedWright standardizes on one Telegram bot operating over a unified ticket-centric runtime surface. Bot-level split is deferred and considered optional for future scale.

See:
- `docs/explanation/adr/adr-008-kanban-centric-unified-runtime-and-ticket-execution.md`
