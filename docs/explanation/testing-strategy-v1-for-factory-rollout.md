# Testing Strategy v1 for Factory Rollout

## Why
Current coverage is insufficient for high-confidence autonomous workflows. Factory mode requires stronger behavioral safety.

## Test Layers

1. Unit tests
- Command handlers
- Query handlers
- Transition and authorization policies

2. Contract tests
- Adapter to semantic envelope mapping
- Git provider and sandbox adapter contracts

3. Integration tests
- Persistence + state transitions + policy checks

4. End-to-end tests
- Ticket lifecycle: pick -> code -> PR -> review -> merge
- Failure paths: sandbox failure, unauthorized access, transition rejection

## Table-Driven Pattern in Ruby
Use case tables (`Array<Hash>`) in Minitest to cover policy matrices and transitions with compact deterministic assertions.

## Rollout Rule
Every new command/query or policy must ship with:
1. Unit tests
2. At least one integration test
3. E2E update when lifecycle behavior changes
