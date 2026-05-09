# RedWright Diagrams

This directory contains PlantUML source diagrams for durable reference documentation.

## Directories

- `components/` contains component relationship diagrams.
- `sequences/` contains scoped sequence diagrams.

## Render

Render a diagram with PlantUML:

```sh
plantuml docs/reference/diagrams/components/redwright-components.puml
plantuml docs/reference/diagrams/sequences/command-query-dispatch.puml
```

The committed source of truth is the `.puml` file. Generated images should only be committed when a documentation page needs a stable rendered asset.
