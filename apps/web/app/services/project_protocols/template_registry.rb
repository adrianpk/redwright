module ProjectProtocols
  class TemplateRegistry
    def common_documents
      [
        {
          "key" => "agents_root",
          "path" => "AGENTS.md",
          "title" => "AGENTS",
          "layer" => "behavioral",
          "position" => 0,
          "body" => <<~MARKDOWN.strip,
            # Agent Operating Contract

            Read this document before starting any work in this repository.

            ## Core Rules

            - Read referenced protocol files before changing behavior that they govern.
            - Keep changes scoped to the active task or slice.
            - Report validation outcomes explicitly.
            - Treat this file as the root entrypoint for the protocol tree.
          MARKDOWN
          "provenance" => {"source" => "common_template"}
        },
        {
          "key" => "conventions",
          "path" => ".agents/CONVENTIONS.md",
          "title" => "Conventions",
          "layer" => "behavioral",
          "position" => 1,
          "body" => <<~MARKDOWN.strip,
            # Conventions

            - Prefer repository-local patterns over new abstractions.
            - Keep naming, comments, and repository documentation in English.
            - Favor cohesive, reviewable commits aligned with one concern.
          MARKDOWN
          "provenance" => {"source" => "common_template"}
        },
        {
          "key" => "architecture",
          "path" => ".agents/ARCHITECTURE.md",
          "title" => "Architecture",
          "layer" => "stack",
          "position" => 2,
          "body" => <<~MARKDOWN.strip,
            # Architecture

            Project-specific architecture guidance lives here.
          MARKDOWN
          "provenance" => {"source" => "common_template"}
        },
        {
          "key" => "playbooks_index",
          "path" => ".agents/PLAYBOOKS.md",
          "title" => "Playbooks",
          "layer" => "behavioral",
          "position" => 3,
          "body" => <<~MARKDOWN.strip,
            # Playbooks Index

            This file indexes focused playbooks under `.agents/playbooks/`.
          MARKDOWN
          "provenance" => {"source" => "common_template"}
        },
        {
          "key" => "playbook_slice_delivery",
          "path" => ".agents/playbooks/slice-delivery.md",
          "title" => "Slice Delivery",
          "layer" => "behavioral",
          "position" => 4,
          "body" => <<~MARKDOWN.strip,
            # Slice Delivery

            - Execute one slice at a time.
            - Keep one branch and one PR per slice.
            - Keep commits aligned with tracker tasks.
          MARKDOWN
          "provenance" => {"source" => "common_template"}
        }
      ]
    end

    def stack_templates
      {
        "go" => stack_template(
          stack_key: "go",
          matchers: ["go"],
          architecture: <<~MARKDOWN,
            # Go Architecture

            - Keep packages small and explicit.
            - Prefer straightforward package boundaries over deep nesting.
            - Keep command entrypoints and internal implementation clearly separated.
          MARKDOWN
          conventions: <<~MARKDOWN
            # Go Conventions

            - Run `go test ./...` as the default test expectation.
            - Prefer standard library solutions before extra dependencies.
            - Keep exported APIs minimal.
          MARKDOWN
        ),
        "ruby" => stack_template(
          stack_key: "ruby",
          matchers: ["ruby"],
          architecture: <<~MARKDOWN,
            # Ruby Architecture

            - Keep domain logic out of entrypoint scripts where possible.
            - Prefer plain Ruby objects for reusable behavior.
            - Keep side effects explicit.
          MARKDOWN
          conventions: <<~MARKDOWN
            # Ruby Conventions

            - Prefer small objects with explicit responsibilities.
            - Keep tests readable and focused on behavior.
            - Avoid framework-shaped patterns unless the project actually uses a framework.
          MARKDOWN
        ),
        "rails" => stack_template(
          stack_key: "rails",
          matchers: ["rails"],
          architecture: <<~MARKDOWN,
            # Rails Architecture

            - Respect Rails app boundaries and existing app/service/model structure.
            - Keep domain logic out of controllers.
            - Treat migrations, jobs, and background work as first-class architectural concerns.
          MARKDOWN
          conventions: <<~MARKDOWN
            # Rails Conventions

            - Prefer Rails-native patterns before custom frameworks.
            - Use targeted Rails tests for changed behavior.
            - Keep persistence and request lifecycle changes explicit.
          MARKDOWN
        ),
        "typescript" => generic_template("typescript", "TypeScript"),
        "elixir" => generic_template("elixir", "Elixir"),
        "gleam" => generic_template("gleam", "Gleam"),
        "zig" => generic_template("zig", "Zig"),
        "rust" => generic_template("rust", "Rust"),
        "angular" => generic_template("angular", "Angular")
      }
    end

    def stack_template_definition(stack_key)
      stack_templates.fetch(stack_key.to_s) do
        generic_template(stack_key.to_s, stack_key.to_s.tr("_-", " ").split.map(&:capitalize).join(" "))
      end
    end

    private

    def stack_template(stack_key:, matchers:, architecture:, conventions:)
      {
        "stack_key" => stack_key,
        "matchers" => matchers,
        "documents" => [
          stack_doc("architecture", ".agents/ARCHITECTURE.md", "Architecture", architecture),
          stack_doc("conventions", ".agents/CONVENTIONS.md", "Conventions", conventions)
        ]
      }
    end

    def generic_template(stack_key, label)
      stack_template(
        stack_key: stack_key,
        matchers: [stack_key],
        architecture: <<~MARKDOWN,
          # #{label} Architecture

          - Keep #{label}-specific structure explicit.
          - Prefer the project's established boundaries over generic rewrites.
          - Make operational assumptions visible in the protocol.
        MARKDOWN
        conventions: <<~MARKDOWN
          # #{label} Conventions

          - Follow the common behavior protocol first.
          - Apply #{label}-specific conventions consistently.
          - Document notable framework or tooling expectations in this file.
        MARKDOWN
      )
    end

    def stack_doc(key, path, title, body)
      {
        "key" => key,
        "path" => path,
        "title" => title,
        "layer" => "stack",
        "body" => body.strip
      }
    end
  end
end
