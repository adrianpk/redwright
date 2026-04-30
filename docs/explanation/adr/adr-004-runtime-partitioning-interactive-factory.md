# ADR-004: Runtime Partitioning (Interactive and Factory)

## Status
Superseded by ADR-008

## Date
2026-04-29

## Context
This ADR defined two logical runtimes (`interactive` and `factory`) to preserve low-latency direct workflows while adding reproducible ticket automation.

## Supersession Note
As of 2026-04-30, RedWright moves to a Kanban-centric execution model where all work is ticket-oriented and executed by one unified runtime surface. The previous runtime partitioning is kept only as historical context.

See:
- `docs/explanation/adr/adr-008-kanban-centric-unified-runtime-and-ticket-execution.md`
