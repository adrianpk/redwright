module ProjectProtocols
  class StackProtocolSource
    STACKS = {
      "go" => {
        name: "Go Protocol Template",
        matchers: ["go", "golang"],
        root: "go",
        documents: [
          ["architecture", ".agents/ARCHITECTURE.md", "Architecture", 0],
          ["conventions", ".agents/CONVENTIONS.md", "Conventions", 1],
          ["documenting", ".agents/DOCUMENTING.md", "Documenting", 2],
          ["linting", ".agents/LINTING.md", "Linting", 3]
        ]
      },
      "elixir" => {
        name: "Elixir Protocol Template",
        matchers: ["elixir"],
        root: "elixir",
        documents: [
          ["architecture", ".agents/ARCHITECTURE.md", "Architecture", 0],
          ["conventions", ".agents/CONVENTIONS.md", "Conventions", 1],
          ["documenting", ".agents/DOCUMENTING.md", "Documenting", 2],
          ["linting", ".agents/LINTING.md", "Linting", 3]
        ]
      },
      "ruby" => {
        name: "Ruby Protocol Template",
        matchers: ["ruby"],
        root: "ruby",
        documents: [
          ["architecture", ".agents/ARCHITECTURE.md", "Architecture", 0],
          ["conventions", ".agents/CONVENTIONS.md", "Conventions", 1],
          ["documenting", ".agents/DOCUMENTING.md", "Documenting", 2],
          ["linting", ".agents/LINTING.md", "Linting", 3]
        ]
      },
      "rails" => {
        name: "Rails Protocol Template",
        matchers: ["rails"],
        root: "rails",
        documents: [
          ["architecture", ".agents/ARCHITECTURE.md", "Architecture", 0],
          ["conventions", ".agents/CONVENTIONS.md", "Conventions", 1],
          ["documenting", ".agents/DOCUMENTING.md", "Documenting", 2],
          ["linting", ".agents/LINTING.md", "Linting", 3]
        ]
      },
      "rust" => {
        name: "Rust Protocol Template",
        matchers: ["rust"],
        root: "rust",
        documents: [
          ["architecture", ".agents/ARCHITECTURE.md", "Architecture", 0],
          ["conventions", ".agents/CONVENTIONS.md", "Conventions", 1],
          ["documenting", ".agents/DOCUMENTING.md", "Documenting", 2],
          ["linting", ".agents/LINTING.md", "Linting", 3]
        ]
      },
      "zig" => {
        name: "Zig Protocol Template",
        matchers: ["zig"],
        root: "zig",
        documents: [
          ["architecture", ".agents/ARCHITECTURE.md", "Architecture", 0],
          ["conventions", ".agents/CONVENTIONS.md", "Conventions", 1],
          ["documenting", ".agents/DOCUMENTING.md", "Documenting", 2],
          ["linting", ".agents/LINTING.md", "Linting", 3]
        ]
      }
    }.freeze

    def initialize(root: Rails.root.join("app", "protocol_templates", "stacks"))
      @root = root.expand_path
    end

    def templates
      STACKS.transform_values { |definition| template_definition_for(definition) }
    end

    private

    attr_reader :root

    def template_definition_for(definition)
      {
        "stack_key" => definition.fetch(:root),
        "name" => definition.fetch(:name),
        "matchers" => definition.fetch(:matchers),
        "documents" => definition.fetch(:documents).map do |document|
          key, path, title, position = document
          stack_doc(
            key: key,
            path: path,
            title: title,
            body: body_for(definition.fetch(:root), path),
            position: position
          )
        end
      }
    end

    def body_for(stack_root, path)
      File.read(root.join(stack_root, path)).strip
    end

    def stack_doc(key:, path:, title:, body:, position:)
      {
        "key" => key,
        "path" => path,
        "title" => title,
        "layer" => "stack",
        "position" => position,
        "body" => body
      }
    end
  end
end
