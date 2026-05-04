module ProjectProtocols
  class TemplateRegistry
    STACK_KEYS = %w[go ruby rails typescript elixir gleam zig rust angular].freeze

    def initialize(source: LocalProtocolSource.new)
      @source = source
    end

    def common_documents
      source.documents
    end

    def stack_templates
      STACK_KEYS.index_with { |stack_key| generic_template(stack_key) }
    end

    def stack_template_definition(stack_key)
      stack_templates.fetch(stack_key.to_s) do
        generic_template(stack_key.to_s)
      end
    end

    private

    attr_reader :source

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

    def generic_template(stack_key)
      stack_template(
        stack_key: stack_key,
        matchers: [stack_key],
        architecture: source.body_for(".agents/ARCHITECTURE.md"),
        conventions: source.body_for(".agents/CONVENTIONS.md")
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
