# RedWright

<!-- REDWRIGHT_LOCAL_BADGES:START -->
[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](https://codeberg.org/adrianpk/redwright)
[![coverage](https://img.shields.io/badge/coverage-31.12%-brightgreen)](badges/coverage.svg)
<!-- REDWRIGHT_LOCAL_BADGES:END -->

RedWright is an **agent harness** for software development, built around messaging-first workflows.

It treats Telegram and Slack as primary interfaces, alongside a local TUI for project work. You describe engineering tasks in natural language, and RedWright executes them inside real workspaces with controlled access to files, commands, and tools.

## Product Focus

RedWright is designed for software-development execution, not generic chat. Current baseline interfaces are Telegram and local TUI. Slack and richer cross-channel multi-project continuity are part of the planned scope.

## What It Delivers

RedWright provides natural-language task intake, structured execution, guarded filesystem and command boundaries, and persisted execution evidence. The execution path is deterministic and server-owned (single writer).

## Start Here

- Concept: [What Is RedWright?](docs/explanation/what-is-redwright.md)
- Run guide: [Run RedWright](docs/how-to/run-redwright.md)
- Technical reference: [Runtime Capabilities](docs/reference/runtime-capabilities.md)
