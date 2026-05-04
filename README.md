# RedWright

<!-- REDWRIGHT_LOCAL_BADGES:START -->
[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](https://codeberg.org/adrianpk/redwright)
[![coverage](https://img.shields.io/badge/coverage-91.6%-brightgreen)](badges/coverage.svg)
<!-- REDWRIGHT_LOCAL_BADGES:END -->

<div align="center" style="background:#FDF3E4; padding:2px 12px; border-radius:14px; margin:16px 0 24px 0;">
  <img src="docs/reference/assets/img/gallery/boards.png" alt="RedWright board screenshot" width="860" />
</div>

[See more](docs/reference/ui/gallery.md)

RedWright is a **black-box software factory platform** where one runtime agent operates directly from the Kanban board.
Telegram and local TUI are the current interactive surfaces. The agent reads board state, decides the next ticket to execute, and can create new tickets when incoming work is not yet represented on the board.

## Name Origin

Personal metaphors and naming associations are not usually explained. It is not our favorite thing to do, but we are not dogmatic about it. RedWright is a playful mix: `Red` is the color of Ruby, and Ruby is the language used for this implementation; `Wright` evokes the idea of a craftsperson building with care; and the initials `R` + `W` point to the harness approach: the agent operates through simple primitives, starting from read and write.

## Software Factory

RedWright addresses a specific operational problem: coordinating multiple AI coding agents without losing control over delivery. Execution happens inside isolated sandboxes, while a Kanban board defines what runs, in which order, and under what priority. Work is expressed as tickets moving through a familiar lifecycle, which keeps the system predictable and observable. In its current form, execution is deliberately constrained to a single agent, allowing the execution model to be defined with precision before introducing concurrency.

The system is designed to evolve into configurable multi-agent execution, where specialized roles such as programmer, reviewer, merger, and QA collaborate, potentially using different models per role. Execution can be triggered per ticket or run continuously, completing the full lifecycle before selecting the next task based on priority. The system remains strictly ticket-centric: if work appears without a ticket, one is created to track its progression and preserve consistency.

The Kanban board serves as the primary interface for local operation, while Telegram acts as the main control channel in practice. Expanding to additional channels is intentionally deferred to avoid multiplying the cost of iteration across parallel entry points. The TUI is minimal. It is still a prototype and rough at the edges. It will be refined. Much of the system already works, but it is still being shaped. This is a statement of intent built on work in progress.

## Start Here

- Concept: [What Is RedWright?](docs/explanation/what-is-redwright.md)
- User guide: [RedWright User Guide](docs/how-to/user-guide/index.md)
- Run guide: [Run RedWright](docs/how-to/run-redwright.md)
- Technical reference: [Runtime Capabilities](docs/reference/runtime-capabilities.md)
- Semantic contract: [Application Semantics v1](docs/reference/application-semantics-v1.md)
