module ProjectProtocols
  class TemplateRegistry
    STACK_KEYS = %w[go ruby rails typescript elixir gleam zig rust angular odin racket].freeze

    def initialize(source: DefaultBehavioralProtocolSource.new, stack_source: StackProtocolSource.new, fallback_stack_source: LocalProtocolSource.new)
      @source = source
      @stack_source = stack_source
      @fallback_stack_source = fallback_stack_source
    end

    def common_documents
      source.documents
    end

    def stack_templates
      STACK_KEYS.index_with { |stack_key| generic_template(stack_key) }.merge(stack_source.templates)
    end

    def stack_template_definition(stack_key)
      stack_templates.fetch(stack_key.to_s) do
        generic_template(stack_key.to_s)
      end
    end

    private

    attr_reader :source, :stack_source, :fallback_stack_source

    def stack_template(stack_key:, matchers:, architecture:, conventions:)
      {
        "stack_key" => stack_key,
        "matchers" => matchers,
        "documents" => [
          stack_doc("architecture", ".agents/ARCHITECTURE.md", "Architecture", architecture, 0),
          stack_doc("conventions", ".agents/CONVENTIONS.md", "Conventions", conventions, 1)
        ]
      }
    end

    def generic_template(stack_key)
      stack_template(
        stack_key: stack_key,
        matchers: [stack_key],
        architecture: fallback_stack_source.body_for(".agents/ARCHITECTURE.md"),
        conventions: fallback_stack_source.body_for(".agents/CONVENTIONS.md")
      )
    end

    def stack_doc(key, path, title, body, position)
      {
        "key" => key,
        "path" => path,
        "title" => title,
        "layer" => "stack",
        "position" => position,
        "body" => body.strip
      }
    end
  end
end
