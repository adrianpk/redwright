# RedWright

<!-- REDWRIGHT_LOCAL_BADGES:START -->
[![CI](https://img.shields.io/badge/CI-failing-red)](https://codeberg.org/adrianpk/redwright)
[![coverage](https://img.shields.io/badge/coverage-28.28%-brightgreen)](badges/coverage.svg)
<!-- REDWRIGHT_LOCAL_BADGES:END -->

RedWright is a **black-box software factory platform** where one runtime agent operates directly from the Kanban board.

Telegram and local TUI are the current interactive surfaces. The agent reads board state, decides the next ticket to execute, and can create new tickets when incoming work is not yet represented on the board.

(*) Slack is expected as a later extension after the Telegram path is stable.

## Name Origin

Personal metaphors and naming associations are not usually explained. It is not our favorite thing to do, but we are not dogmatic about it. RedWright is a playful mix: `Red` is the color of Ruby, and Ruby is the language used for this implementation; `Wright` evokes the idea of a craftsperson building with care; and the initials `R` + `W` point to the harness approach: the agent operates through simple primitives, starting from read and write.

## Product Focus

RedWright addresses a concrete operational problem: coordinating multiple AI coding agents without losing control over delivery.

Agents execute inside isolated sandboxes or containers, while the Kanban board acts as the control plane that determines what runs, in which order, and with what priority. Work is expressed through tickets following a familiar lifecycle, allowing tasks to be created, prioritized, and assigned in a way that remains predictable and observable.

At the moment, execution is intentionally constrained: a single agent operates at a time. This makes it easier to define the execution model precisely before expanding it into agent pools or teams.

The target model evolves this into configurable multi-agent execution, where specialized roles such as programmer, reviewer, merger, and QA collaborate, optionally using different models per role when that leads to better outcomes.

The Kanban board is the most natural interface for local, desktop-based operation, but the same workflow is fully accessible through Telegram, which currently serves as the primary control channel in daily, production-like usage.

Supporting multiple channels from the start is intentionally avoided. Spreading the same operational surface across several entry points (Slack, email, others) would multiply the cost of every correction and iteration. Telegram is the preferred operational path today, and the system is being shaped around real usage there before expanding outward.

The TUI is intentionally minimal and will remain so, but in its current state it is still a rough prototype and will receive further attention and refinement in the near term.

Execution can be triggered for a specific ticket, or run as a continuous loop where the full lifecycle is completed (program, review, merge) before automatically selecting the next assigned ticket based on priority. If work is introduced without an explicit ticket, the agent will create one to track its evolution, keeping the system strictly ticket-centric.

Much of this is already in progress, and several parts are already functional, but refinement is still ongoing. This README should be read as an advanced statement of intent grounded in active implementation.

## Start Here

- Concept: [What Is RedWright?](docs/explanation/what-is-redwright.md)
- Run guide: [Run RedWright](docs/how-to/run-redwright.md)
- Technical reference: [Runtime Capabilities](docs/reference/runtime-capabilities.md)
- Semantic contract: [Application Semantics v1](docs/reference/application-semantics-v1.md)
